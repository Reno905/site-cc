import express from 'express'
import { createServer } from 'http'
import { Server } from 'socket.io'
import cors from 'cors'
import helmet from 'helmet'
import compression from 'compression'
import rateLimit from 'express-rate-limit'
import dotenv from 'dotenv'
import mysql from 'mysql2/promise'
import { createClient } from 'redis'
import jwt from 'jsonwebtoken'
import { logger } from './utils/logger.js'
import { authenticateSocket } from './middleware/auth.js'
import { setupCaseHandlers } from './handlers/caseHandlers.js'
import { setupUserHandlers } from './handlers/userHandlers.js'
import { setupAdminHandlers } from './handlers/adminHandlers.js'

// Load environment variables
dotenv.config()

const app = express()
const server = createServer(app)

// CORS configuration
const corsOptions = {
  origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'],
  credentials: process.env.CORS_CREDENTIALS === 'true',
  methods: ['GET', 'POST']
}

// Socket.io setup
const io = new Server(server, {
  cors: corsOptions,
  path: '/socket.io/',
  transports: ['websocket', 'polling'],
  allowEIO3: true
})

// Express middleware
app.use(helmet())
app.use(compression())
app.use(cors(corsOptions))
app.use(express.json({ limit: '10mb' }))
app.use(express.urlencoded({ extended: true, limit: '10mb' }))

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 60000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: 'Too many requests from this IP'
})
app.use('/api/', limiter)

// Database connection
let dbConnection
const connectToDatabase = async () => {
  try {
    dbConnection = await mysql.createConnection({
      host: process.env.DB_HOST || 'mysql',
      port: parseInt(process.env.DB_PORT) || 3306,
      user: process.env.DB_USERNAME || 'case_user',
      password: process.env.DB_PASSWORD || 'case_password',
      database: process.env.DB_DATABASE || 'case_platform',
      charset: 'utf8mb4'
    })
    logger.info('Connected to MySQL database')
  } catch (error) {
    logger.error('Database connection failed:', error)
    process.exit(1)
  }
}

// Redis connection
let redisClient
const connectToRedis = async () => {
  try {
    redisClient = createClient({
      socket: {
        host: process.env.REDIS_HOST || 'redis',
        port: parseInt(process.env.REDIS_PORT) || 6379
      },
      password: process.env.REDIS_PASSWORD || 'redis_password'
    })
    
    await redisClient.connect()
    logger.info('Connected to Redis')
  } catch (error) {
    logger.error('Redis connection failed:', error)
    process.exit(1)
  }
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    connections: io.engine.clientsCount
  })
})

// API endpoints
app.get('/api/stats', async (req, res) => {
  try {
    const stats = {
      activeUsers: io.engine.clientsCount,
      totalOpenings: await getTotalOpenings(),
      totalUsers: await getTotalUsers(),
      timestamp: new Date().toISOString()
    }
    res.json(stats)
  } catch (error) {
    logger.error('Error fetching stats:', error)
    res.status(500).json({ error: 'Internal server error' })
  }
})

// Socket.io connection handling
io.use(authenticateSocket)

io.on('connection', (socket) => {
  logger.info(`User connected: ${socket.user?.id || 'anonymous'} (${socket.id})`)
  
  // Join user to their personal room
  if (socket.user) {
    socket.join(`user:${socket.user.id}`)
    
    // Update user's online status
    updateUserOnlineStatus(socket.user.id, true)
  }
  
  // Setup event handlers
  setupCaseHandlers(io, socket, { db: dbConnection, redis: redisClient })
  setupUserHandlers(io, socket, { db: dbConnection, redis: redisClient })
  setupAdminHandlers(io, socket, { db: dbConnection, redis: redisClient })
  
  // Handle disconnection
  socket.on('disconnect', () => {
    logger.info(`User disconnected: ${socket.user?.id || 'anonymous'} (${socket.id})`)
    
    if (socket.user) {
      updateUserOnlineStatus(socket.user.id, false)
    }
  })
  
  // Handle errors
  socket.on('error', (error) => {
    logger.error(`Socket error for user ${socket.user?.id || 'anonymous'}:`, error)
  })
})

// Helper functions
async function getTotalOpenings() {
  try {
    const [rows] = await dbConnection.execute('SELECT COUNT(*) as count FROM openings')
    return rows[0].count
  } catch (error) {
    logger.error('Error getting total openings:', error)
    return 0
  }
}

async function getTotalUsers() {
  try {
    const [rows] = await dbConnection.execute('SELECT COUNT(*) as count FROM users')
    return rows[0].count
  } catch (error) {
    logger.error('Error getting total users:', error)
    return 0
  }
}

async function updateUserOnlineStatus(userId, isOnline) {
  try {
    await redisClient.setEx(`user:${userId}:online`, 300, isOnline ? '1' : '0')
    
    // Broadcast user status to admin
    io.to('admin').emit('userStatusUpdate', {
      userId,
      isOnline,
      timestamp: new Date().toISOString()
    })
  } catch (error) {
    logger.error('Error updating user online status:', error)
  }
}

// Graceful shutdown
process.on('SIGTERM', gracefulShutdown)
process.on('SIGINT', gracefulShutdown)

async function gracefulShutdown() {
  logger.info('Starting graceful shutdown...')
  
  server.close(() => {
    logger.info('HTTP server closed')
  })
  
  if (dbConnection) {
    await dbConnection.end()
    logger.info('Database connection closed')
  }
  
  if (redisClient) {
    await redisClient.quit()
    logger.info('Redis connection closed')
  }
  
  process.exit(0)
}

// Start server
const PORT = process.env.PORT || 3001
const HOST = process.env.HOST || '0.0.0.0'

async function startServer() {
  try {
    await connectToDatabase()
    await connectToRedis()
    
    server.listen(PORT, HOST, () => {
      logger.info(`WebSocket server running on ${HOST}:${PORT}`)
      logger.info(`Environment: ${process.env.NODE_ENV}`)
      logger.info(`CORS origins: ${corsOptions.origin.join(', ')}`)
    })
  } catch (error) {
    logger.error('Failed to start server:', error)
    process.exit(1)
  }
}

startServer()

export { io, dbConnection, redisClient }
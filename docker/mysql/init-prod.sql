-- Case Platform Production Database Initialization

-- Set timezone
SET time_zone = '+00:00';

-- Set charset and collation
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create production user with limited privileges
CREATE USER IF NOT EXISTS 'case_backup'@'%' IDENTIFIED BY 'backup_password_here';
GRANT SELECT, LOCK TABLES, RELOAD, REPLICATION CLIENT ON case_platform.* TO 'case_backup'@'%';

-- Create monitoring user
CREATE USER IF NOT EXISTS 'case_monitor'@'%' IDENTIFIED BY 'monitor_password_here';
GRANT PROCESS, REPLICATION CLIENT ON *.* TO 'case_monitor'@'%';
GRANT SELECT ON performance_schema.* TO 'case_monitor'@'%';
GRANT SELECT ON information_schema.* TO 'case_monitor'@'%';

-- Optimize MySQL settings for production
SET GLOBAL sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';

-- Set default charset and collation for database
ALTER DATABASE case_platform CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Performance optimizations
SET GLOBAL innodb_buffer_pool_size = 2147483648; -- 2GB
SET GLOBAL innodb_log_file_size = 536870912; -- 512MB
SET GLOBAL max_connections = 1000;
SET GLOBAL table_open_cache = 4000;

-- Create indexes that might be needed
-- These will be created during Laravel migrations, but listed here for reference
-- CREATE INDEX idx_users_steam_id ON users(steam_id);
-- CREATE INDEX idx_openings_user_id ON openings(user_id);
-- CREATE INDEX idx_openings_created_at ON openings(created_at);
-- CREATE INDEX idx_payments_user_id ON payments(user_id);
-- CREATE INDEX idx_payments_status ON payments(status);

-- Flush privileges
FLUSH PRIVILEGES;

-- Log the initialization
SELECT 'Case Platform Production Database Initialized' AS status;
-- Case Platform Database Initialization

-- Set timezone
SET time_zone = '+00:00';

-- Create additional user if needed
-- CREATE USER IF NOT EXISTS 'case_admin'@'%' IDENTIFIED BY 'admin_password';
-- GRANT ALL PRIVILEGES ON case_platform.* TO 'case_admin'@'%';

-- Optimize MySQL settings for Laravel
SET GLOBAL sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';

-- Set default charset
ALTER DATABASE case_platform CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Flush privileges
FLUSH PRIVILEGES;
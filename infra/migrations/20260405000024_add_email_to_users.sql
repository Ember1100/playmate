-- 为用户表添加邮箱字段（用于账号密码登录）
ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(100) UNIQUE;
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

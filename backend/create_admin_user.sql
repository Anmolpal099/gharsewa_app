-- Manual admin user (password: Password123)
-- Run: docker-compose exec -T db mysql -u gharsewa_user -pgharsewa_password gharsewa < create_admin_user.sql

DELETE FROM users WHERE email = 'admin@gharsewa.com';

INSERT INTO users (
  id, name, email, password, role, roles,
  is_active, email_verified_at, created_at, updated_at
) VALUES (
  UUID(),
  'Admin User',
  'admin@gharsewa.com',
  '$2y$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYfujPn7Twu',
  'admin',
  '["admin"]',
  1,
  NOW(),
  NOW(),
  NOW()
);

SELECT id, name, email, role, roles, is_active, email_verified_at FROM users WHERE email = 'admin@gharsewa.com';

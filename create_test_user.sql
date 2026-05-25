-- Create Test User for Login Testing
-- This user has a verified email and can log in immediately

USE gharsewa;

-- Delete existing test user if exists
DELETE FROM users WHERE email = 'test@example.com';

-- Create test user with verified email
INSERT INTO users (
    name, 
    email, 
    password, 
    role, 
    is_active, 
    email_verified_at, 
    created_at, 
    updated_at
)
VALUES (
    'Test User',
    'test@example.com',
    '$2y$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYfujPn7Twu', -- Password: Password123
    'customer',
    1,
    NOW(),
    NOW(),
    NOW()
);

-- Verify the user was created
SELECT 
    id,
    name,
    email,
    role,
    is_active,
    email_verified_at,
    created_at
FROM users 
WHERE email = 'test@example.com';

-- Test credentials:
-- Email: test@example.com
-- Password: Password123

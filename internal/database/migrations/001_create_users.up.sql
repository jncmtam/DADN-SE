-- Enable pgcrypto extension for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create table users with UNIQUE constraint on username
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(255) NOT NULL UNIQUE, -- UNIQUE constraint applied directly
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    otp_secret TEXT, -- Store secret for OTP generation
    is_email_verified BOOLEAN DEFAULT FALSE,
    role VARCHAR(10) CHECK (role IN ('admin', 'user')) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create table otp_request
CREATE TABLE otp_request (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    otp_code VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Fix typo: create_at -> created_at
);

-- Create index on users.email for better query performance
CREATE INDEX idx_users_email ON users(email);

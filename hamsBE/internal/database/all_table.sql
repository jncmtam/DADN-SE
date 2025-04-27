-- Enable pgcrypto extension for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create table users with UNIQUE constraint on username
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) UNIQUE NOT NULL,
    avatar_url TEXT DEFAULT '',
    password_hash TEXT NOT NULL,
    otp_secret TEXT, -- Store secret for OTP generation
    is_email_verified BOOLEAN DEFAULT FALSE,
    role VARCHAR(10) CHECK (role IN ('admin', 'user')) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Refresh token table
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create table otp_request
CREATE TABLE otp_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    otp_code VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
);

-- Create index on users.email for better query performance
CREATE INDEX idx_users_email ON users(email);
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'cage_status') THEN
        CREATE TYPE cage_status AS ENUM ('active', 'inactive');
    END IF;
END $$;

CREATE TABLE cages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    user_id UUID NOT NULL,
    status cage_status DEFAULT 'inactive' NOT NULL,
    num_device INT DEFAULT 0, -- Added to match user_route.go
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_cages_user_id ON cages(user_id);
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'sensor_type') THEN
        CREATE TYPE sensor_type AS ENUM ('temperature', 'humidity', 'light', 'distance');
    END IF;
END $$;

CREATE TABLE sensors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    type sensor_type NOT NULL,
    value FLOAT NOT NULL, -- Made NOT NULL to match usage
    unit VARCHAR(50),
    cage_id UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Added for tracking updates
    FOREIGN KEY (cage_id) REFERENCES cages(id) ON DELETE CASCADE
);

CREATE INDEX idx_sensors_cage_id ON sensors(cage_id);
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'device_type') THEN
        CREATE TYPE device_type AS ENUM ('display', 'light', 'pump', 'fan');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'device_status') THEN
        CREATE TYPE device_status AS ENUM ('on', 'off', 'auto');
    END IF;
END $$;


CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    type device_type NOT NULL,
    status device_status DEFAULT 'off' NOT NULL,
    last_status device_status,
    cage_id UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cage_id) REFERENCES cages(id) ON DELETE CASCADE
);

DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'condition_enum') THEN
        CREATE TYPE condition_enum AS ENUM ('>', '<', '=');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'action_enum') THEN
        CREATE TYPE action_enum AS ENUM ('turn_on', 'turn_off');
    END IF;
END $$;

CREATE TABLE automation_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sensor_id UUID NOT NULL,
    device_id UUID NOT NULL,
    cage_id UUID NOT NULL, -- Added directly in CREATE TABLE
    condition condition_enum NOT NULL,
    threshold FLOAT NOT NULL,
    action action_enum NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Added for consistency
    FOREIGN KEY (sensor_id) REFERENCES sensors(id) ON DELETE CASCADE,
    FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE,
    FOREIGN KEY (cage_id) REFERENCES cages(id) ON DELETE CASCADE
);

CREATE INDEX idx_automation_rules_sensor_id ON automation_rules(sensor_id);
CREATE INDEX idx_automation_rules_device_id ON automation_rules(device_id);
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    cage_id UUID NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('info', 'warning', 'error')),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (cage_id) REFERENCES cages(id) ON DELETE CASCADE
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE TABLE statistics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cage_id UUID NOT NULL,
    water_refill_sl INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Added for consistency
    FOREIGN KEY (cage_id) REFERENCES cages(id) ON DELETE CASCADE
);

CREATE INDEX idx_statistic_cage_id ON statistics(cage_id);
CREATE INDEX idx_statistic_created_at ON statistics(created_at);
CREATE TABLE settings (
       cage_id UUID PRIMARY KEY REFERENCES cages(id) ON DELETE CASCADE,
       high_water_usage_threshold INT NOT NULL,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
       updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );


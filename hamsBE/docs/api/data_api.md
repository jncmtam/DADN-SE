```sql
-- Drop existing tables if they exist (optional, for a clean setup)
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS statistic CASCADE;
DROP TABLE IF EXISTS settings CASCADE;
DROP TABLE IF EXISTS schedules CASCADE;
DROP TABLE IF EXISTS automation_rules CASCADE;
DROP TABLE IF EXISTS sensors CASCADE;
DROP TABLE IF EXISTS devices CASCADE;
DROP TABLE IF EXISTS cages CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Create users table
CREATE TABLE users (
    id VARCHAR(36) PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create cages table
CREATE TABLE cages (
    id VARCHAR(36) PRIMARY KEY,
    user_id VARCHAR(36) REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    num_device INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create devices table
CREATE TABLE devices (
    id VARCHAR(36) PRIMARY KEY,
    cage_id VARCHAR(36) REFERENCES cages(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    type VARCHAR(20) NOT NULL, -- e.g., 'fan', 'pump'
    status VARCHAR(10) DEFAULT 'off', -- e.g., 'on', 'off'
    last_status VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create sensors table
CREATE TABLE sensors (
    id VARCHAR(36) PRIMARY KEY,
    cage_id VARCHAR(36) REFERENCES cages(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL, -- e.g., 'temperature', 'humidity'
    value FLOAT NOT NULL,
    unit VARCHAR(10) NOT NULL, -- e.g., '°C', '%'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create automation_rules table
CREATE TABLE automation_rules (
    id VARCHAR(36) PRIMARY KEY,
    sensor_id VARCHAR(36) REFERENCES sensors(id) ON DELETE CASCADE,
    device_id VARCHAR(36) REFERENCES devices(id) ON DELETE CASCADE,
    condition VARCHAR(2) NOT NULL, -- e.g., '>', '<', '='
    threshold FLOAT NOT NULL,
    unit VARCHAR(10) NOT NULL,
    action VARCHAR(20) NOT NULL, -- e.g., 'turn_on', 'turn_off', 'refill'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create schedules table
CREATE TABLE schedules (
    id VARCHAR(36) PRIMARY KEY,
    device_id VARCHAR(36) REFERENCES devices(id) ON DELETE CASCADE,
    execution_time VARCHAR(5) NOT NULL, -- Format: HH:MM
    days VARCHAR(50) NOT NULL, -- JSON array: ["mon", "wed", "fri"]
    action VARCHAR(20) NOT NULL, -- e.g., 'turn_on', 'turn_off', 'refill'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create settings table
CREATE TABLE settings (
    cage_id VARCHAR(36) PRIMARY KEY REFERENCES cages(id) ON DELETE CASCADE,
    high_water_usage_threshold INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create statistic table
CREATE TABLE statistic (
    id VARCHAR(36) PRIMARY KEY,
    cage_id VARCHAR(36) REFERENCES cages(id) ON DELETE CASCADE,
    water_refill_sl INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create notifications table
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(36) REFERENCES users(id) ON DELETE CASCADE,
    cage_id VARCHAR(36) REFERENCES cages(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL, -- e.g., 'sensor_alert', 'device_action'
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert test data
-- Insert users
INSERT INTO users (id, username, password, email) VALUES
('user1', 'testuser1', '$2a$10$hashedpassword', 'user1@example.com'),
('user2', 'testuser2', '$2a$10$hashedpassword', 'user2@example.com');

-- Insert cages
INSERT INTO cages (id, user_id, name, status, num_device) VALUES
('cage1', 'user1', 'Cage 1', 'active', 2),
('cage2', 'user1', 'Cage 2', 'active', 1),
('cage3', 'user2', 'Cage 3', 'active', 1);

-- Insert devices
INSERT INTO devices (id, cage_id, name, type, status, last_status) VALUES
('device1', 'cage1', 'Fan', 'fan', 'off', NULL),
('device2', 'cage1', 'Pump', 'pump', 'off', NULL),
('device3', 'cage2', 'Heater', 'heater', 'off', NULL),
('device4', 'cage3', 'Light', 'light', 'off', NULL);

-- Insert sensors
INSERT INTO sensors (id, cage_id, type, value, unit, created_at) VALUES
('sensor1', 'cage1', 'temperature', 25.0, '°C', NOW()),
('sensor2', 'cage1', 'humidity', 50.0, '%', NOW()),
('sensor3', 'cage2', 'temperature', 22.0, '°C', NOW()),
('sensor4', 'cage3', 'light', 300.0, 'lux', NOW());

-- Insert automation rules
INSERT INTO automation_rules (id, sensor_id, device_id, condition, threshold, unit, action) VALUES
('rule1', 'sensor1', 'device1', '>', 30.0, '°C', 'turn_on'),
('rule2', 'sensor2', 'device2', '<', 40.0, '%', 'refill'),
('rule3', 'sensor3', 'device3', '<', 20.0, '°C', 'turn_on');

-- Insert schedules
INSERT INTO schedules (id, device_id, execution_time, days, action) VALUES
('schedule1', 'device1', '08:00', '["mon", "wed", "fri"]', 'turn_on'),
('schedule2', 'device2', '12:00', '["tue", "thu"]', 'refill');

-- Insert settings
INSERT INTO settings (cage_id, high_water_usage_threshold) VALUES
('cage1', 100),
('cage2', 150);

-- Insert statistics
INSERT INTO statistic (id, cage_id, water_refill_sl, created_at) VALUES
('stat1', 'cage1', 50, NOW() - INTERVAL '1 day'),
('stat2', 'cage1', 30, NOW()),
('stat3', 'cage2', 20, NOW());

-- Insert initial notifications (optional, for testing retrieval)
INSERT INTO notifications (user_id, cage_id, type, message, is_read, created_at) VALUES
('user1', 'cage1', 'device_action', 'Device Fan turned on', FALSE, NOW()),
('user1', 'cage2', 'sensor_alert', 'Temperature below threshold', FALSE, NOW());
```

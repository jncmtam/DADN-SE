-- Enable pgcrypto for UUID generation (already included in schema)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Insert sample users
INSERT INTO
    users (
        id,
        username,
        email,
        avatar_url,
        password_hash,
        otp_secret,
        is_email_verified,
        role,
        created_at,
        updated_at
    )
VALUES
    (
        '550e8400-e29b-41d4-a716-446655440000',
        'john_doe',
        'john.doe@example.com',
        'https://example.com/avatar1.jpg',
        '$2a$10$examplehash1',
        'secret1',
        TRUE,
        'user',
        '2025-04-01 10:00:00',
        '2025-04-01 10:00:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440001',
        'jane_smith',
        'jane.smith@example.com',
        'https://example.com/avatar2.jpg',
        '$2a$10$examplehash2',
        'secret2',
        TRUE,
        'admin',
        '2025-04-01 11:00:00',
        '2025-04-01 11:00:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440002',
        'bob_jones',
        'bob.jones@example.com',
        '',
        '$2a$10$examplehash3',
        'secret3',
        FALSE,
        'user',
        '2025-04-02 09:00:00',
        '2025-04-02 09:00:00'
    );

-- Insert sample refresh tokens
INSERT INTO
    refresh_tokens (id, user_id, token, expires_at, created_at)
VALUES
    (
        '550e8400-e29b-41d4-a716-446655440010',
        '550e8400-e29b-41d4-a716-446655440000',
        'refresh_token_1',
        '2025-05-01 10:00:00',
        '2025-04-01 10:00:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440011',
        '550e8400-e29b-41d4-a716-446655440001',
        'refresh_token_2',
        '2025-05-01 11:00:00',
        '2025-04-01 11:00:00'
    );

-- Insert sample OTP requests
INSERT INTO
    otp_requests (
        id,
        user_id,
        otp_code,
        expires_at,
        is_used,
        created_at
    )
VALUES
    (
        '550e8400-e29b-41d4-a716-446655440020',
        '550e8400-e29b-41d4-a716-446655440000',
        '123456',
        '2025-04-01 10:30:00',
        FALSE,
        '2025-04-01 10:00:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440021',
        '550e8400-e29b-41d4-a716-446655440002',
        '789012',
        '2025-04-02 09:30:00',
        TRUE,
        '2025-04-02 09:00:00'
    );

-- Insert sample cages
INSERT INTO
    cages (
        id,
        name,
        user_id,
        status,
        num_device,
        created_at,
        updated_at
    )
VALUES
    (
        '550e8400-e29b-41d4-a716-446655440100',
        'Hamster Cage 1',
        '550e8400-e29b-41d4-a716-446655440000',
        'active',
        2,
        '2025-04-01 12:00:00',
        '2025-04-01 12:00:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440101',
        'Hamster Cage 2',
        '550e8400-e29b-41d4-a716-446655440000',
        'inactive',
        1,
        '2025-04-02 08:00:00',
        '2025-04-02 08:00:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440102',
        'Admin Cage',
        '550e8400-e29b-41d4-a716-446655440001',
        'active',
        3,
        '2025-04-01 13:00:00',
        '2025-04-01 13:00:00'
    );

-- Insert sample sensors
INSERT INTO
    sensors (
        id,
        name,
        type,
        value,
        unit,
        cage_id,
        created_at,
        updated_at
    )
VALUES
    (
        '550e8400-e29b-41d4-a716-446655440200',
        'Temp Sensor 1',
        'temperature',
        32.5,
        '°C',
        '550e8400-e29b-41d4-a716-446655440100',
        '2025-04-25 12:00:00',
        '2025-04-25 12:00:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440201',
        'Humidity Sensor 1',
        'humidity',
        85.0,
        '%',
        '550e8400-e29b-41d4-a716-446655440100',
        '2025-04-25 12:01:00',
        '2025-04-25 12:01:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440202',
        'Water Level Sensor',
        'distance',
        18.0,
        'cm',
        '550e8400-e29b-41d4-a716-446655440101',
        '2025-04-25 12:02:00',
        '2025-04-25 12:02:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440203',
        'Light Sensor',
        'light',
        200.0,
        'lux',
        '550e8400-e29b-41d4-a716-446655440102',
        '2025-04-25 12:03:00',
        '2025-04-25 12:03:00'
    );

-- Insert sample devices
INSERT INTO
    devices (
        id,
        name,
        type,
        status,
        last_status,
        cage_id,
        created_at,
        updated_at
    )
VALUES
    (
        '550e8400-e29b-41d4-a716-446655440300',
        'Water Pump 1',
        'pump',
        'on',
        'off',
        '550e8400-e29b-41d4-a716-446655440100',
        '2025-04-01 12:00:00',
        '2025-04-25 12:00:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440301',
        'Fan 1',
        'fan',
        'off',
        'on',
        '550e8400-e29b-41d4-a716-446655440100',
        '2025-04-01 12:00:00',
        '2025-04-25 12:01:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440302',
        'Light 1',
        'light',
        'on',
        'off',
        '550e8400-e29b-41d4-a716-446655440101',
        '2025-04-02 08:00:00',
        '2025-04-25 12:02:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440303',
        'Display 1',
        'display',
        'auto',
        'auto',
        '550e8400-e29b-41d4-a716-446655440102',
        '2025-04-01 13:00:00',
        '2025-04-25 12:03:00'
    );

-- Insert sample automation rules
INSERT INTO
    automation_rules (
        id,
        sensor_id,
        device_id,
        cage_id,
        condition,
        threshold,
        action,
        created_at,
        updated_at
    )
VALUES
    (
        '550e8400-e29b-41d4-a716-446655440400',
        '550e8400-e29b-41d4-a716-446655440200',
        '550e8400-e29b-41d4-a716-446655440301',
        '550e8400-e29b-41d4-a716-446655440100',
        '>',
        30.0,
        'turn_on',
        '2025-04-01 12:00:00',
        '2025-04-01 12:00:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440401',
        '550e8400-e29b-41d4-a716-446655440201',
        '550e8400-e29b-41d4-a716-446655440301',
        '550e8400-e29b-41d4-a716-446655440100',
        '>',
        80.0,
        'turn_on',
        '2025-04-01 12:00:00',
        '2025-04-01 12:00:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440402',
        '550e8400-e29b-41d4-a716-446655440202',
        '550e8400-e29b-41d4-a716-446655440300',
        '550e8400-e29b-41d4-a716-446655440101',
        '<',
        16.0,
        'refill',
        '2025-04-02 08:00:00',
        '2025-04-02 08:00:00'
    );

-- Insert sample notifications
INSERT INTO
    notifications (
        id,
        user_id,
        cage_id,
        type,
        title,
        message,
        is_read,
        created_at
    )
VALUES
    (
        '550e8400-e29b-41d4-a716-446655440500',
        '550e8400-e29b-41d4-a716-446655440000',
        '550e8400-e29b-41d4-a716-446655440100',
        'warning',
        'Cage Hamster Cage 1: High temperature',
        'High temperature detected: 32.5°C',
        FALSE,
        '2025-04-25 12:00:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440501',
        '550e8400-e29b-41d4-a716-446655440000',
        '550e8400-e29b-41d4-a716-446655440100',
        'warning',
        'Cage Hamster Cage 1: High humidity',
        'High humidity detected: 85.0%',
        FALSE,
        '2025-04-25 12:01:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440502',
        '550e8400-e29b-41d4-a716-446655440000',
        '550e8400-e29b-41d4-a716-446655440101',
        'warning',
        'Cage Hamster Cage 2: Low water level',
        'Low water level detected: 10.0%',
        TRUE,
        '2025-04-25 12:02:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440503',
        '550e8400-e29b-41d4-a716-446655440000',
        '550e8400-e29b-41d4-a716-446655440100',
        'info',
        'Device Water Pump 1: Action refill executed',
        'Device Water Pump 1 refilled',
        FALSE,
        '2025-04-25 12:03:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440504',
        '550e8400-e29b-41d4-a716-446655440001',
        '550e8400-e29b-41d4-a716-446655440102',
        'error',
        'Device Display 1: Action failed',
        'Cannot execute action on Display 1: device error',
        FALSE,
        '2025-04-25 12:04:00'
    );

-- Insert sample statistics
INSERT INTO
    statistics (
        id,
        cage_id,
        water_refill_sl,
        created_at,
        updated_at
    )
VALUES
    (
        '550e8400-e29b-41d4-a716-446655440600',
        '550e8400-e29b-41d4-a716-446655440100',
        500,
        '2025-04-25 12:00:00',
        '2025-04-25 12:00:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440601',
        '550e8400-e29b-41d4-a716-446655440100',
        300,
        '2025-04-24 12:00:00',
        '2025-04-24 12:00:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440602',
        '550e8400-e29b-41d4-a716-446655440101',
        200,
        '2025-04-25 12:00:00',
        '2025-04-25 12:00:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440603',
        '550e8400-e29b-41d4-a716-446655440102',
        400,
        '2025-04-25 12:00:00',
        '2025-04-25 12:00:00'
    );

-- Insert sample settings
INSERT INTO
    settings (
        cage_id,
        high_water_usage_threshold,
        created_at,
        updated_at
    )
VALUES
    (
        '550e8400-e29b-41d4-a716-446655440100',
        1000,
        '2025-04-01 12:00:00',
        '2025-04-01 12:00:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440101',
        800,
        '2025-04-02 08:00:00',
        '2025-04-02 08:00:00'
    ),
    (
        '550e8400-e29b-41d4-a716-446655440102',
        1200,
        '2025-04-01 13:00:00',
        '2025-04-01 13:00:00'
    );
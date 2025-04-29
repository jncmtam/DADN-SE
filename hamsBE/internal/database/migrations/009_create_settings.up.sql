CREATE TABLE settings (
    cage_id UUID PRIMARY KEY,
    high_water_usage_threshold INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


INSERT INTO users (
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
) VALUES (
    gen_random_uuid(),
    'admin',
    'admin@example.com',
    '',
    '$2a$12$nvJkeBfLvsCYnEGK/fMYjey3mQ7JYYc9Ou4R4H2j.ir6onHEAdMfq',
    NULL,
    TRUE,
    'admin',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

INSERT INTO users (
    id,
    username,
    email,
    avatar_url,
    password_hash,
    is_email_verified,
    role,
    created_at,
    updated_at
) VALUES (
    '5a8f9d73-2bcb-4c65-917f-2ff409e9e1d9',
    'user1', 
    'user1@example.com',
    '',
    '$2y$10$psOkrYhg8y2M.DQPmEGIRuvDwhY0QgSTC5YYh7440cHYGKkNe8.ce',
    TRUE,
    'user',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

INSERT INTO cages (id, name, user_id, status)
VALUES ('7c2b9e6e-ff2d-4c92-8b8c-2d1f2e0d6c00', 'cage1', '5a8f9d73-2bcb-4c65-917f-2ff409e9e1d9', 'active');

INSERT INTO sensors (name, type, value, unit, cage_id)
VALUES 
('temperature', 'temperature', 28.5, '°C', NULL),
('humidity', 'humidity', 65.2, '%', NULL),
('light', 'light', 300.0, 'lux', '7c2b9e6e-ff2d-4c92-8b8c-2d1f2e0d6c00'),
('waterlevel', 'water', 50, 'mm', '7c2b9e6e-ff2d-4c92-8b8c-2d1f2e0d6c00');

INSERT INTO devices (name, type, status, cage_id)
VALUES 
('led', 'light', 'off', NULL),
('pump', 'pump', 'off', '7c2b9e6e-ff2d-4c92-8b8c-2d1f2e0d6c00'),
('fan', 'fan', 'off', '7c2b9e6e-ff2d-4c92-8b8c-2d1f2e0d6c00');

CREATE OR REPLACE FUNCTION notify_sensor_update() RETURNS trigger AS $$
DECLARE
BEGIN
  PERFORM pg_notify('sensor_updates', 
    json_build_object(
      'sensor_id', NEW.id,
      'value', NEW.value,
      'type', NEW.type
    )::text
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sensor_update_trigger
AFTER UPDATE ON sensors
FOR EACH ROW
WHEN (OLD.value IS DISTINCT FROM NEW.value)
EXECUTE FUNCTION notify_sensor_update();
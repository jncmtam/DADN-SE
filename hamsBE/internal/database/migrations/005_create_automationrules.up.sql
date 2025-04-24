DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'condition_enum') THEN
        CREATE TYPE condition_enum AS ENUM ('>', '<', '=');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'action_enum') THEN
        CREATE TYPE action_enum AS ENUM ('turn_on', 'turn_off', 'refill', 'lock');
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
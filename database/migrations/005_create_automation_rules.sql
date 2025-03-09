CREATE TABLE automation_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sensor_id UUID NOT NULL REFERENCES sensors(id) ON DELETE CASCADE,
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    condition VARCHAR(2) CHECK (condition IN ('>', '<', '=', '>=', '<=')) NOT NULL,
    threshold FLOAT NOT NULL,
    action VARCHAR(10) CHECK (action IN ('turn_on', 'turn_off')) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

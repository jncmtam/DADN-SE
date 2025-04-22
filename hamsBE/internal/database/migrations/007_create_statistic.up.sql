CREATE TABLE sensor_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sensor_id UUID NOT NULL REFERENCES sensors(id) ON DELETE CASCADE,
    value FLOAT NOT NULL,
    unit VARCHAR(50) NOT NULL,
    condition_met VARCHAR(255) NOT NULL, 
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sensor_data_sensor_id ON sensor_data(sensor_id);
CREATE INDEX idx_sensor_data_recorded_at ON sensor_data(recorded_at);
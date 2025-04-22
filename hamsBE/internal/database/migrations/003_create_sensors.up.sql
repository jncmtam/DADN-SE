DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'sensor_type') THEN
        CREATE TYPE sensor_type AS ENUM ('temperature', 'humidity', 'light', 'distance', 'weight');
    END IF;
END $$;


CREATE TABLE sensors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    type sensor_type NOT NULL,  
    value FLOAT, -- Set default for value = 0.0, prevent null value !
    unit VARCHAR(50),
    cage_id UUID NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cage_id) REFERENCES cages(id) ON DELETE CASCADE
);

CREATE INDEX idx_sensors_cage_id ON sensors(cage_id);
-- Sensor shouldn't be null, because sensor always report a value.
ALTER TABLE sensors ALTER COLUMN value SET DEFAULT 0.0;

CREATE TABLE sensor_data (
    id SERIAL PRIMARY KEY,
    sensor_id VARCHAR(255) NOT NULL,
    value DOUBLE PRECISION NOT NULL,
    unit VARCHAR(50) NOT NULL,
    condition_met TEXT,
    recorded_at TIMESTAMP NOT NULL
);
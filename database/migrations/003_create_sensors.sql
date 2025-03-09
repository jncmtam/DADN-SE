CREATE TABLE sensors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL,
    type VARCHAR(20) CHECK (type IN ('temperature', 'humidity', 'light', 'distance', 'weight')) NOT NULL,
    value FLOAT NOT NULL,
    unit VARCHAR(10) CHECK (unit IN ('°C', '%', 'lux', 'cm', 'kg')) NOT NULL,
    cage_id UUID NOT NULL REFERENCES cages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW()
);

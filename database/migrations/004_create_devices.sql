CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL,
    type VARCHAR(20) CHECK (type IN ('display', 'lock', 'light', 'pump', 'fan')) NOT NULL,
    status VARCHAR(10) CHECK (status IN ('on', 'off', 'auto')) NOT NULL,
    cage_id UUID NOT NULL REFERENCES cages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

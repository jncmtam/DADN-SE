CREATE TABLE schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    execution_time VARCHAR(5) NOT NULL, -- Changed to VARCHAR to match code
    days TEXT[] NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('turn_on', 'turn_off', 'refill', 'lock')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Added for consistency
    -- CHECK CONSTRAINT: Kiểm tra tất cả giá trị trong days có hợp lệ không
    CONSTRAINT valid_days CHECK (
        days <@ ARRAY['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
    )
);

CREATE INDEX idx_schedules_device_id ON schedules(device_id);
CREATE INDEX idx_schedules_device_days_time ON schedules(device_id, days, execution_time);
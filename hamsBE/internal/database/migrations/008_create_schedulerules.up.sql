CREATE TABLE schedule_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    execution_time TIME NOT NULL,
    days TEXT[] NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('turn_on', 'turn_off', 'refill')),
    created_at TIMESTAMP DEFAULT NOW(),
    
    -- CHECK CONSTRAINT: Kiểm tra tất cả giá trị trong days có hợp lệ không
    CONSTRAINT valid_days CHECK (
        days <@ ARRAY['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']
    )
);

CREATE INDEX idx_schedule_rules_device_id ON schedule_rules(device_id);
CREATE INDEX idx_schedule_rules_device_days_time ON schedule_rules(device_id, days, execution_time);

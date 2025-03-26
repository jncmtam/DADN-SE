CREATE TABLE schedule_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    execution_time TIME NOT NULL,
    days TEXT[] NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('turn_on', 'turn_off')),
    created_at TIMESTAMP DEFAULT NOW(),
    
    -- CHECK CONSTRAINT: Kiểm tra tất cả giá trị trong days có hợp lệ không
    CONSTRAINT valid_days CHECK (
        days <@ ARRAY['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
    )
);
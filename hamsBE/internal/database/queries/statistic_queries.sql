-- name: create_device_status_logs_table
CREATE TABLE device_status_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    status VARCHAR(3) NOT NULL CHECK (status IN ('on', 'off')),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- name: create_daily_energy_consumption_table
CREATE TABLE daily_energy_consumption (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    energy_consumed FLOAT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- name: create_monthly_energy_consumption_table
CREATE TABLE monthly_energy_consumption (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    month DATE NOT NULL,
    energy_consumed FLOAT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- name: create_log_device_status_change_function
CREATE OR REPLACE FUNCTION log_device_status_change()
RETURNS TRIGGER AS $$ 
BEGIN
    INSERT INTO device_status_logs (device_id, status, timestamp)
    VALUES (NEW.id, NEW.status, CURRENT_TIMESTAMP);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- name: create_device_status_change_trigger
CREATE TRIGGER device_status_change_trigger
AFTER UPDATE OF status ON devices
FOR EACH ROW
EXECUTE FUNCTION log_device_status_change();

-- name: create_calculate_energy_consumption_function
CREATE OR REPLACE FUNCTION calculate_energy_consumption(device_id UUID, start_time TIMESTAMP, end_time TIMESTAMP)
RETURNS FLOAT AS $$
DECLARE
    power FLOAT := 5.0;
    total_energy FLOAT := 0.0;
    prev_timestamp TIMESTAMP;
    current_status VARCHAR(3);
BEGIN
    FOR log IN
        SELECT status, timestamp
        FROM device_status_logs
        WHERE device_id = calculate_energy_consumption.device_id 
          AND timestamp >= start_time 
          AND timestamp <= end_time
        ORDER BY timestamp
    LOOP
        IF prev_timestamp IS NOT NULL AND current_status = 'on' THEN
            total_energy := total_energy + (EXTRACT(EPOCH FROM (log.timestamp - prev_timestamp)) / 3600.0) * power;
        END IF;
        prev_timestamp := log.timestamp;
        current_status := log.status;
    END LOOP;
    IF current_status = 'on' AND prev_timestamp IS NOT NULL THEN
        total_energy := total_energy + (EXTRACT(EPOCH FROM (end_time - prev_timestamp)) / 3600.0) * power;
    END IF;
    RETURN total_energy;
END;
$$ LANGUAGE plpgsql;

-- name: insert_daily_energy_consumption
INSERT INTO daily_energy_consumption (device_id, date, energy_consumed)
SELECT 
    d.id, 
    CURRENT_DATE - INTERVAL '1 day', 
    calculate_energy_consumption(d.id, 
        (CURRENT_DATE - INTERVAL '1 day')::TIMESTAMP, 
        (CURRENT_DATE - INTERVAL '1 day' + INTERVAL '23 hours 59 minutes 59 seconds')::TIMESTAMP)
FROM devices d
WHERE calculate_energy_consumption(d.id, 
    (CURRENT_DATE - INTERVAL '1 day')::TIMESTAMP, 
    (CURRENT_DATE - INTERVAL '1 day' + INTERVAL '23 hours 59 minutes 59 seconds')::TIMESTAMP) IS NOT NULL;

-- name: insert_monthly_energy_consumption
INSERT INTO monthly_energy_consumption (device_id, month, energy_consumed)
SELECT 
    dec.device_id, 
    DATE_TRUNC('month', dec.date)::DATE, 
    SUM(dec.energy_consumed)
FROM daily_energy_consumption dec
WHERE dec.date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
  AND dec.date < DATE_TRUNC('month', CURRENT_DATE)
GROUP BY dec.device_id, DATE_TRUNC('month', dec.date);

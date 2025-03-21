-- name: create_automation_rule
INSERT INTO automation_rules (sensor_id, device_id, condition, threshold, unit, action) 
VALUES ($1, $2, $3, $4, $5, $6) 
RETURNING id, created_at;

-- name: delete_automation_rule
DELETE FROM automation_rules WHERE id = $1;

-- name: get_automation_rules_by_deviceID
SELECT id, sensor_id, condition, threshold, unit, action
FROM automation_rules
WHERE device_id = $1;

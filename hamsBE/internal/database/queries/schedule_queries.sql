-- name: create_schedule_rule
INSERT INTO schedule_rules (device_id, execution_time, days, action) 
VALUES ($1, $2, $3, $4) 
RETURNING id, created_at;

-- name: check_schedule_rule_exists
SELECT EXISTS(SELECT 1 FROM schedule_rules WHERE id = $1);

-- name: delete_schedule_rule
DELETE FROM schedule_rules WHERE id = $1;

-- name: get_schedule_rules_by_deviceID
SELECT id, execution_time, days, action
FROM schedule_rules
WHERE device_id = $1;
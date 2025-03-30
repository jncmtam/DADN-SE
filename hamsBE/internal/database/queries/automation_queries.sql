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

-- name: IsOwnedByUser_Automation
SELECT COUNT(*) 
FROM automation_rules 
    JOIN devices ON automation_rules.device_id = devices.id 
    JOIN cages ON devices.cage_id = cages.id 
WHERE automation_rules.id = $1 AND cages.user_id = $2;

-- name: check_automation_rule_exists
SELECT EXISTS(SELECT 1 FROM automation_rules WHERE id = $1);
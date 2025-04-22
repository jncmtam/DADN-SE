-- name: create_automation_rule
INSERT INTO automation_rules (sensor_id, device_id, condition, threshold, unit, action)
VALUES ($1, $2, $3, $4, $5, $6)
RETURNING id, sensor_id, device_id, condition, threshold, unit, action, created_at;

-- name: delete_automation_rule
DELETE FROM automation_rules WHERE id = $1;

-- name: get_automation_rules_by_device_id
SELECT id, sensor_id, condition, threshold, unit, action, created_at
FROM automation_rules
WHERE device_id = $1;

-- name: is_owned_by_user_automation
SELECT EXISTS(
    SELECT 1
    FROM automation_rules ar
    JOIN devices d ON ar.device_id = d.id
    JOIN cages c ON d.cage_id = c.id
    WHERE ar.id = $1 AND c.user_id = $2
);

-- name: check_automation_rule_exists
SELECT EXISTS(SELECT 1 FROM automation_rules WHERE id = $1);
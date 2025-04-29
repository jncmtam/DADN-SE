-- name: create_automation_rule
INSERT INTO automation_rules (sensor_id, device_id, condition, threshold, unit, action) 
VALUES ($1, $2, $3, $4, $5, $6) 
RETURNING id, created_at;

-- name: delete_automation_rule
DELETE FROM automation_rules WHERE id = $1;

-- name: get_automation_rules_by_deviceID
SELECT 
    ar.id, 
    ar.sensor_id, 
    s.type AS sensor_type,
    ar.condition, 
    ar.threshold, 
    s.unit, 
    ar.action
FROM automation_rules ar
JOIN sensors s ON ar.sensor_id = s.id
WHERE ar.device_id = $1;

-- name: IsOwnedByUser_Automation
SELECT COUNT(*) 
FROM automation_rules 
    JOIN devices ON automation_rules.device_id = devices.id 
    JOIN cages ON devices.cage_id = cages.id 
WHERE automation_rules.id = $1 AND cages.user_id = $2;

-- name: check_automation_rule_exists
SELECT EXISTS(SELECT 1 FROM automation_rules WHERE id = $1);

-- name: get_automation_rules_by_sensorID
SELECT 
    ar.id, 
    ar.sensor_id, 
    s.type AS sensor_type,
    ar.condition, 
    ar.threshold, 
    s.unit, 
    ar.action,
    d.cage_id,   
    c.user_id,   
    d.type AS device_type 
FROM automation_rules ar
JOIN sensors s ON ar.sensor_id = s.id
JOIN devices d ON ar.device_id = d.id   
JOIN cages c ON d.cage_id = c.id   
WHERE ar.sensor_id = $1 AND d.mode = 'auto';

-- name: delete_automation_rules_by_device
DELETE FROM automation_rules WHERE device_id = $1;

-- name: delete_automation_rules_by_sensor
DELETE FROM automation_rules WHERE sensor_id = $1;

-- name: get_device_status_by_ID
SELECT d.status
FROM devices d
INNER JOIN automation_rules ar ON ar.device_id = d.id
WHERE ar.id = $1
LIMIT 1;

-- name: get_device_name_by_ID
SELECT d.name
FROM devices d
INNER JOIN automation_rules ar ON ar.device_id = d.id
WHERE ar.id = $1
LIMIT 1;

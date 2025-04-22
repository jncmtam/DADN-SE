-- name: get_sensors_by_cage_id
SELECT id, name, type, COALESCE(value, 0) AS value, COALESCE(unit, '') AS unit, cage_id, created_at
FROM sensors
WHERE cage_id = $1;

-- name: create_sensor
INSERT INTO sensors (name, type, cage_id)
VALUES ($1, $2, $3)
RETURNING id, name, type, value, unit, cage_id, created_at;

-- name: delete_sensor_by_id
DELETE FROM sensors WHERE id = $1;

-- name: check_sensor_exists
SELECT EXISTS(SELECT 1 FROM sensors WHERE id = $1);
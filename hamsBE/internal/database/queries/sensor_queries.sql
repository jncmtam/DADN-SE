-- name: get_sensors_by_cageID
SELECT id, type, COALESCE(value, 0) AS value, COALESCE(unit, '') AS unit
FROM sensors
WHERE cage_id = $1;

-- name: create_sensor
INSERT INTO sensors (name, type, cage_id) 
VALUES ($1, $2, $3) 
RETURNING id;

-- name: delete_sensor_by_id
DELETE FROM sensors WHERE id = $1;

-- name: check_sensor_exists
SELECT EXISTS(SELECT 1 FROM sensors WHERE id = $1);
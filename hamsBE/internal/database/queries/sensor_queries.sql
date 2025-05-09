-- name: get_sensors_by_cageID
SELECT id, type, COALESCE(unit, '') AS unit
FROM sensors
WHERE cage_id = $1;

-- name: create_sensor
INSERT INTO sensors (name, type, unit, cage_id) 
VALUES ($1, $2, $3, $4) 
RETURNING id, name;

-- name: delete_sensor_by_id
DELETE FROM sensors WHERE id = $1;

-- name: check_sensor_exists
SELECT EXISTS(SELECT 1 FROM sensors WHERE id = $1);

-- name: check_sensor_name_exists
SELECT EXISTS (
  SELECT 1 FROM sensors WHERE name = $1
);

-- name: assign_sensor_to_cage
UPDATE sensors SET cage_id = $1 WHERE id = $2;

-- name: get_sensors_assignable
SELECT id, name FROM sensors WHERE cage_id IS NULL;

-- name: get_sensors_values_by_cage
SELECT id, value, type
FROM sensors
WHERE cage_id = $1;

-- name: unassign_sensor_owner
UPDATE sensors SET cage_id = NULL, value = 0 WHERE id = $1;

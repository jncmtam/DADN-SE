-- name: create_device 
INSERT INTO devices (name, type, cage_id)
VALUES ($1, $2, $3)
RETURNING id, name;

-- name: get_devices_by_cageID
SELECT id, name, status
FROM devices
WHERE cage_id = $1;

-- name: get_device_by_deviceID
SELECT id, name, status
FROM devices
WHERE id = $1;

-- name: delete_device_by_id
DELETE FROM devices WHERE id = $1;

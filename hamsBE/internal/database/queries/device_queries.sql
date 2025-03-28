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

-- name: IsOwnedByUser_Device
SELECT COUNT(*) 
FROM devices JOIN cages ON devices.cage_id = cages.id 
WHERE devices.id = $1 AND cages.user_id = $2;

-- name: check_device_exists
SELECT EXISTS(SELECT 1 FROM devices WHERE id = $1);
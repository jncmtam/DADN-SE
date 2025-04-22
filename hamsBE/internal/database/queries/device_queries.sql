-- name: create_device
INSERT INTO devices (name, type, cage_id)
VALUES ($1, $2, $3)
RETURNING id, name, type, status, last_status, cage_id, created_at, updated_at;

-- name: get_devices_by_cage_id
SELECT id, name, type, status, last_status, cage_id, created_at, updated_at
FROM devices
WHERE cage_id = $1;

-- name: get_device_by_id
SELECT id, name, type, status, last_status, cage_id, created_at, updated_at
FROM devices
WHERE id = $1;

-- name: delete_device_by_id
DELETE FROM devices WHERE id = $1;

-- name: is_owned_by_user_device
SELECT EXISTS(
    SELECT 1 
    FROM devices d JOIN cages c ON d.cage_id = c.id 
    WHERE d.id = $1 AND c.user_id = $2
);

-- name: check_device_exists
SELECT EXISTS(SELECT 1 FROM devices WHERE id = $1);
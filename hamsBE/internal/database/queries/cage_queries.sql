-- name: create_cage
INSERT INTO cages (name, user_id)
VALUES ($1, $2)
RETURNING id, name, user_id, status, created_at, updated_at;

-- name: get_cages_by_user_id
SELECT 
    c.id, 
    c.name, 
    COUNT(d.id) AS num_devices, 
    c.status,
    c.created_at,
    c.updated_at
FROM cages c
LEFT JOIN devices d ON c.id = d.cage_id
WHERE c.user_id = $1
GROUP BY c.id, c.name, c.status, c.created_at, c.updated_at
ORDER BY c.name;

-- name: delete_cage_by_id
DELETE FROM cages WHERE id = $1;

-- name: get_cage_by_id
SELECT id, name, user_id, status, created_at, updated_at
FROM cages WHERE id = $1;

-- name: is_owned_by_user_cage
SELECT EXISTS(SELECT 1 FROM cages WHERE id = $1 AND user_id = $2);

-- name: check_cage_exists
SELECT EXISTS(SELECT 1 FROM cages WHERE id = $1);

-- name: check_device_and_sensor_in_same_cage
SELECT EXISTS(
    SELECT 1
    FROM devices d JOIN sensors s ON d.cage_id = s.cage_id
    WHERE d.id = $1 AND s.id = $2
);
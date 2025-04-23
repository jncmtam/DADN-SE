-- name: create_cage
INSERT INTO cages (name, user_id)
VALUES ($1, $2)
RETURNING id, name;

-- name: get_cages_by_ID 
SELECT 
    c.id, 
    c.name, 
    COUNT(d.id) AS num_device, 
    c.status
FROM cages c
LEFT JOIN devices d ON c.id = d.cage_id
WHERE c.user_id = $1
GROUP BY c.id, c.name, c.status
ORDER BY c.name;

-- name: delete_cage_by_id
DELETE FROM cages WHERE id = $1;

-- name: get_cage_by_ID
SELECT id, name, status FROM cages WHERE id = $1;

-- name: IsOwnedByUser_Cage
SELECT COUNT(*) FROM cages WHERE id = $1 AND user_id = $2;

-- name: check_cage_exists
SELECT EXISTS(SELECT 1 FROM cages WHERE id = $1);

-- name: check_deviceID_isSameCage_sensorID
SELECT COUNT(*)
FROM devices d JOIN sensors s 
    ON d.cage_id = s.cage_id
WHERE d.id = $1 AND s.id = $2;

-- name: check_cage_name_exists
SELECT EXISTS (
  SELECT 1 FROM cages WHERE user_id = $1 AND name = $2
);


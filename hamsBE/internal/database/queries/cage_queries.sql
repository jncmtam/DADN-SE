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

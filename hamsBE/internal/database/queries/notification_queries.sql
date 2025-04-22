-- name: create_notification
INSERT INTO notifications (message, user_id)
VALUES ($1, $2)
RETURNING id, message, user_id, created_at, is_read;

-- name: get_unread_notifications_by_user_id
SELECT id, message, created_at
FROM notifications
WHERE user_id = $1 AND is_read = FALSE
ORDER BY created_at DESC;

-- name: mark_notification_as_read
UPDATE notifications
SET is_read = TRUE
WHERE id = $1 AND user_id = $2
RETURNING id, message, user_id, created_at, is_read;
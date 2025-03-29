-- name: create_user
INSERT INTO users (username, email, password_hash, role, avatar_url)
VALUES ($1, $2, $3, $4, '')
RETURNING id, username, email, role, avatar_url, created_at;

-- name: find_user_by_email
SELECT id, username, email, password_hash, role, is_email_verified, created_at, updated_at, avatar_url
FROM users
WHERE email = $1;

-- name: get_user_by_id
SELECT id, username, email, password_hash, role, avatar_url, is_email_verified, created_at, updated_at
FROM users
WHERE id = $1;

-- name: update_password
UPDATE users
SET password_hash = $1, updated_at = CURRENT_TIMESTAMP
WHERE id = $2
RETURNING id, username, email, updated_at;

-- name: verify_email
UPDATE users
SET is_email_verified = TRUE, updated_at = CURRENT_TIMESTAMP
WHERE id = $1
RETURNING id, username, email, is_email_verified, updated_at;

-- name: create_otp_request
INSERT INTO otp_request (user_id, otp_code, expires_at)
VALUES ($1, $2, $3)
RETURNING id, user_id, otp_code, expires_at, created_at;

-- name: verify_otp
SELECT id, user_id, otp_code, expires_at, is_used
FROM otp_request
WHERE user_id = $1 AND otp_code = $2 AND expires_at > CURRENT_TIMESTAMP AND is_used = FALSE;

-- name: mark_otp_as_used
UPDATE otp_request
SET is_used = TRUE
WHERE id = $1
RETURNING id, user_id, otp_code, is_used;

-- name: delete_active_otps
DELETE FROM otp_request
WHERE user_id = $1 AND expires_at > CURRENT_TIMESTAMP AND is_used = FALSE;

-- name: delete_refresh_tokens
DELETE FROM refresh_tokens WHERE user_id = $1;

-- name: get_refresh_token
SELECT user_id, token, expires_at FROM refresh_tokens WHERE token = $1;

-- name: get_all_refresh_tokens
SELECT id, user_id, token, expires_at, created_at FROM refresh_tokens WHERE user_id = $1;

-- name: store_refresh_token
INSERT INTO refresh_tokens (user_id, token, expires_at)
VALUES ($1, $2, $3)
RETURNING id;

-- name: get_all_users
SELECT id, username, email, role, avatar_url, is_email_verified, created_at, updated_at
FROM users
ORDER BY created_at DESC;

-- name: update_avatar
UPDATE users
SET avatar_url = $1, updated_at = NOW()
WHERE id = $2
RETURNING id, username, email, avatar_url, updated_at;

-- name: find_user_by_username
SELECT id, username, email, avatar_url,  updated_at
FROM users
WHERE username = $1;

-- name: update_username
UPDATE users
SET username = $1, updated_at = CURRENT_TIMESTAMP
WHERE id = $2
RETURNING id, username, email, created_at, updated_at;

-- name: delete_user
DELETE FROM users
WHERE id = $1;

-- name: check_user_exists
SELECT EXISTS(SELECT 1 FROM users WHERE id = $1);
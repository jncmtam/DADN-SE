-- name: create_user
INSERT INTO users (username, email, password_hash, role)
VALUES ($1, $2, $3, $4)
RETURNING id, username, email, role, created_at;

-- name: find_user_by_email
SELECT id, username, email, password_hash, role, is_email_verified, created_at, updated_at
FROM users
WHERE email = $1;

-- name: get_user_by_id
SELECT id, username, email, password_hash, role, is_email_verified, created_at, updated_at
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
RETURNING id, user_id, otp_code, expires_at, create_at;

-- name: verify_otp
SELECT id, user_id, otp_code, expires_at, is_used
FROM otp_request
WHERE user_id = $1 AND otp_code = $2 AND expires_at > CURRENT_TIMESTAMP AND is_used = FALSE;

-- name: mark_otp_as_used
UPDATE otp_request
SET is_used = TRUE
WHERE id = $1
RETURNING id, user_id, otp_code, is_used;

-- name: check_user_exists
SELECT EXISTS(SELECT 1 FROM users WHERE id = $1);
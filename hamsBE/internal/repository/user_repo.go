package repository

import (
	"context"
	"database/sql"
	"fmt"
	"hamstercare/internal/database/queries"
	"hamstercare/internal/model"
	"time"
)

type UserRepository struct {
    db *sql.DB
}

func NewUserRepository(db *sql.DB) *UserRepository {
    return &UserRepository{db: db}
}

func (r *UserRepository) DB() *sql.DB {
    return r.db
}

func (r *UserRepository) CreateUser(ctx context.Context, username, email, passwordHash, role string) (*model.User, error) {
    user := &model.User{}
    query, err := queries.GetQuery("create_user")
    if err != nil {
        return nil, err
    }
    err = r.db.QueryRowContext(ctx, query, username, email, passwordHash, role).Scan(
        &user.ID, &user.Username, &user.Email, &user.Role, &user.AvatarURL, &user.CreatedAt,
    )
    if err != nil {
        return nil, err
    }
    return user, nil
}

func (r *UserRepository) FindUserByEmail(ctx context.Context, email string) (*model.User, error) {
    user := &model.User{}
    query, err := queries.GetQuery("find_user_by_email")
    if err != nil {
        return nil, err
    }
    err = r.db.QueryRowContext(ctx, query, email).Scan(
        &user.ID, &user.Username, &user.Email, &user.PasswordHash, &user.Role,
        &user.IsEmailVerified, &user.CreatedAt, &user.UpdatedAt, &user.AvatarURL,
    )
    if err == sql.ErrNoRows {
        return nil, sql.ErrNoRows
    }
    if err != nil {
        return nil, err
    }
    return user, nil
}

func (r *UserRepository) FindUserByUsername(ctx context.Context, username string) (*model.User, error) {
    user := &model.User{}
    query, err := queries.GetQuery("find_user_by_username")
    if err != nil {
        return nil, err
    }
    err = r.db.QueryRowContext(ctx, query, username).Scan(&user.ID, &user.Username, &user.Email,  
		&user.AvatarURL, &user.UpdatedAt,)
    if err == sql.ErrNoRows {
        return nil, sql.ErrNoRows
    }
    if err != nil {
        return nil, err
    }
    return user, nil
}

func (r *UserRepository) GetUserByID(ctx context.Context, id string) (*model.User, error) {
    user := &model.User{}
    query, err := queries.GetQuery("get_user_by_id")
    if err != nil {
        return nil, err
    }
    err = r.db.QueryRowContext(ctx, query, id).Scan(
        &user.ID, &user.Username, &user.Email, &user.PasswordHash, &user.Role,
        &user.AvatarURL, &user.IsEmailVerified, &user.CreatedAt, &user.UpdatedAt,
    )
    if err == sql.ErrNoRows {
        return nil, sql.ErrNoRows
    }
    if err != nil {
        return nil, err
    }
    return user, nil
}

func (r *UserRepository) UpdatePassword(ctx context.Context, userID, newPasswordHash string) (*model.User, error) {
    user := &model.User{}
    query, err := queries.GetQuery("update_password")
    if err != nil {
        return nil, err
    }
    err = r.db.QueryRowContext(ctx, query, newPasswordHash, userID).Scan(
        &user.ID, &user.Username, &user.Email, &user.UpdatedAt,
    )
    if err != nil {
        return nil, err
    }
    return user, nil
}

func (r *UserRepository) VerifyEmail(ctx context.Context, userID string) (*model.User, error) {
	user := &model.User{}
	query, err := queries.GetQuery("verify_email")
	if err != nil {
		return nil, err
	}
	err = r.db.QueryRowContext(ctx, query, userID).Scan(
		&user.ID, &user.Username, &user.Email, &user.IsEmailVerified, &user.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return user, nil
}



func (r *UserRepository) DeleteRefreshToken(ctx context.Context, userID string) error {
    query, err := queries.GetQuery("delete_refresh_tokens")
    if err != nil {
        return err
    }
    _, err = r.db.ExecContext(ctx, query, userID)
    return err
}

func (r *UserRepository) GetRefreshToken(ctx context.Context, token string) (*model.RefreshToken, error) {
    refreshToken := &model.RefreshToken{}
    query, err := queries.GetQuery("get_refresh_token")
    if err != nil {
        return nil, err
    }
    err = r.db.QueryRowContext(ctx, query, token).Scan(
        &refreshToken.UserID, &refreshToken.Token, &refreshToken.ExpiresAt,
    )
    if err == sql.ErrNoRows {
        return nil, sql.ErrNoRows
    }
    if err != nil {
        return nil, err
    }
    return refreshToken, nil
}
func (r *UserRepository) StoreRefreshToken(ctx context.Context, userID, token string, expiresAt time.Time) (string, error) {
    query, err := queries.GetQuery("store_refresh_token")
    if err != nil {
        return "", fmt.Errorf("failed to get store_refresh_token query: %v", err)
    }

    var refreshTokenID string
    err = r.db.QueryRowContext(ctx, query, userID, token, expiresAt).Scan(&refreshTokenID)
    if err != nil {
        return "", fmt.Errorf("failed to store refresh token: %v", err)
    }

    return refreshTokenID, nil
}
func (r *UserRepository) GetAllRefreshTokens(ctx context.Context, userID string) ([]*model.RefreshToken, error) {
    query, err := queries.GetQuery("get_all_refresh_tokens")
    if err != nil {
        return nil, err
    }
    rows, err := r.db.QueryContext(ctx, query, userID)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var refreshTokens []*model.RefreshToken
    for rows.Next() {
        refreshToken := &model.RefreshToken{}
        err := rows.Scan(
            &refreshToken.ID, &refreshToken.UserID, &refreshToken.Token,
            &refreshToken.ExpiresAt, &refreshToken.CreatedAt,
        )
        if err != nil {
            return nil, err
        }
        refreshTokens = append(refreshTokens, refreshToken)
    }
    if err = rows.Err(); err != nil {
        return nil, err
    }
    return refreshTokens, nil
}

func (r *UserRepository) UpdateAvatar(ctx context.Context, userID, avatarURL string) (*model.User, error) {
    user := &model.User{}
    query, err := queries.GetQuery("update_avatar")
    if err != nil {
        return nil, err
    }
    err = r.db.QueryRowContext(ctx, query, avatarURL, userID).Scan(
        &user.ID, &user.Username, &user.Email, &user.AvatarURL, &user.UpdatedAt,
    )
    if err != nil {
        return nil, err
    }
    return user, nil
}

func (r *UserRepository) UpdateUsername(ctx context.Context, userID, username string) (*model.User, error) {
    if r.db == nil {
        return nil, fmt.Errorf("database connection is nil")
    }
    user := &model.User{}
    query, err := queries.GetQuery("update_username")
    if err != nil {
        return nil, fmt.Errorf("failed to get update_username query: %v", err)
    }
    err = r.db.QueryRowContext(ctx, query, username, userID).Scan(
        &user.ID, &user.Username, &user.Email, &user.CreatedAt, &user.UpdatedAt,
    )
    // 
    if err != nil {
        return nil, fmt.Errorf("failed to update username: %v", err)
    }
    return user, nil
}

// Lấy tất cả danh sách người dung
func (r *UserRepository) GetAllUsers(ctx context.Context) ([]*model.User, error) {
    query, err := queries.GetQuery("get_all_users")
    if err != nil {
        return nil, err
    }
    rows, err := r.db.QueryContext(ctx, query)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var users []*model.User
    for rows.Next() {
        user := &model.User{}
        err := rows.Scan(
            &user.ID, &user.Username, &user.Email, &user.Role,
            &user.AvatarURL, &user.IsEmailVerified, &user.CreatedAt, &user.UpdatedAt,
        )
        if err != nil {
            return nil, err
        }
        users = append(users, user)
    }
    if err = rows.Err(); err != nil {
        return nil, err
    }
    return users, nil
}

func (r *UserRepository) DeleteUser(ctx context.Context, userID string) error {
    query, err := queries.GetQuery("delete_user")
    if err != nil {
        return fmt.Errorf("failed to get delete_user query: %v", err)
    }

    result, err := r.db.ExecContext(ctx, query, userID)
    if err != nil {
        return fmt.Errorf("failed to delete user: %v", err)
    }

    rowsAffected, err := result.RowsAffected()
    if err != nil {
        return fmt.Errorf("failed to check rows affected: %v", err)
    }
    if rowsAffected == 0 {
        return sql.ErrNoRows // Hoặc lỗi tùy chỉnh như errors.New("user not found")
    }

    return nil
}

func (r *UserRepository) UserExists(ctx context.Context, userID string) (bool, error) {
	query, err := queries.GetQuery("check_user_exists")
	if err != nil {
		return false, err
	}
	var exists bool
	err = r.db.QueryRowContext(ctx, query, userID).Scan(&exists)
	return exists, err
}
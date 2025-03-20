// internal/repository/user_repo.go
package repository

import (
	"context"
	"database/sql"
	"hamstercare/internal/database/queries"
	"hamstercare/internal/model"
)

type UserRepository struct {
	db *sql.DB
}

func NewUserRepository(db *sql.DB) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) CreateUser(ctx context.Context, username, email, passwordHash, role string) (*model.User, error) {
	user := &model.User{}
	query, err := queries.GetQuery("create_user")
	if err != nil {
		return nil, err
	}
	err = r.db.QueryRowContext(ctx, query, username, email, passwordHash, role).Scan(
		&user.ID, &user.Username, &user.Email, &user.Role, &user.CreatedAt,
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
		&user.IsEmailVerified, &user.CreatedAt, &user.UpdatedAt,
	)
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
		&user.IsEmailVerified, &user.CreatedAt, &user.UpdatedAt,
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
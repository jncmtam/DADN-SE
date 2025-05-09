// internal/repository/cage_repo.go
package repository

import (
	"context"
	"database/sql"
	"errors"
	"hamstercare/internal/database/queries"
	"hamstercare/internal/model"
)

type CageRepository struct {
	db *sql.DB
}

func NewCageRepository(db *sql.DB) *CageRepository {
	return &CageRepository{db: db}
}

func (r *CageRepository) CreateACageForID(ctx context.Context, nameCage string, userID string) (*model.Cage, error) {
	query, err := queries.GetQuery("create_cage")
	if err != nil {
		return nil, err
	}

	cage := &model.Cage{}
	err = r.db.QueryRowContext(ctx, query, nameCage, userID).Scan(
		&cage.ID, &cage.Name, &cage.UserID, &cage.Status, &cage.CreatedAt, &cage.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}
	return cage, nil
}

func (r *CageRepository) GetCagesByID(ctx context.Context, userID string) ([]*model.CageResponse, error) {
	query, err := queries.GetQuery("get_cages_by_user_id")
	if err != nil {
		return nil, err
	}

	rows, err := r.db.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var cages []*model.CageResponse
	for rows.Next() {
		cage := &model.CageResponse{}
		if err := rows.Scan(&cage.ID, &cage.Name, &cage.NumDevice, &cage.Status,
			&cage.CreatedAt, &cage.UpdatedAt); err != nil {
			return nil, err
		}
		cages = append(cages, cage)
	}

	return cages, nil
}

func (r *CageRepository) DeleteCageByID(ctx context.Context, cageID string) error {
	query, err := queries.GetQuery("delete_cage_by_id")
	if err != nil {
		return err
	}
	_, err = r.db.ExecContext(ctx, query, cageID)
	return err
}

func (r *CageRepository) GetACageByID(ctx context.Context, cageID string) (*model.Cage, error) {
	query, err := queries.GetQuery("get_cage_by_id")
	if err != nil {
		return nil, err
	}

	cage := &model.Cage{}
	err = r.db.QueryRowContext(ctx, query, cageID).Scan(&cage.ID, &cage.Name, &cage.UserID,
		&cage.Status, &cage.CreatedAt, &cage.UpdatedAt)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	return cage, nil
}

func (r *CageRepository) IsOwnedByUser(ctx context.Context, userID, cageID string) (bool, error) {
	query, err := queries.GetQuery("is_owned_by_user_cage")
	if err != nil {
		return false, err
	}
	var exists bool
	err = r.db.QueryRowContext(ctx, query, cageID, userID).Scan(&exists)
	return exists, err
}

func (r *CageRepository) CageExists(ctx context.Context, cageID string) (bool, error) {
	query, err := queries.GetQuery("check_cage_exists")
	if err != nil {
		return false, err
	}
	var exists bool
	err = r.db.QueryRowContext(ctx, query, cageID).Scan(&exists)
	return exists, err
}

func (r *CageRepository) IsExistsID(ctx context.Context, cageID string) (bool, error) {
	return r.CageExists(ctx, cageID)
}

// Kiểm tra device và sensor có cùng cage không bằng 1 query duy nhất
func (r *CageRepository) IsSameCage(ctx context.Context, deviceID, sensorID string) (bool, error) {
	query, err := queries.GetQuery("check_deviceID_isSameCage_sensorID")
	if err != nil {
		return false, err
	}
	var count int

	err = r.db.QueryRowContext(ctx, query, deviceID, sensorID).Scan(&count)
	if err != nil {
		return false, err
	}

	return count > 0, nil
}

func (r *CageRepository) DoesCageNameExist(ctx context.Context, userID string, name string) (bool, error) {
	query, err := queries.GetQuery("check_cage_name_exists")
	if err != nil {
		return false, err
	}
	var exists bool
	err = r.db.QueryRowContext(ctx, query, userID, name).Scan(&exists)
	return exists, err
}

func (r *CageRepository) UpdateStatus(ctx context.Context, cageID, status string) error {
	query, err := queries.GetQuery("update_cage_status")
	if err != nil {
		return err
	}

	_, err = r.db.ExecContext(ctx, query, status, cageID)
	if err != nil {
		return errors.New("failed to update cage status: " + err.Error())
	}

	return nil
}

func (r *CageRepository) GetCageNameByID(ctx context.Context, cageID string) (string, error) {
	query := `
		SELECT name
		FROM cages
		WHERE id = $1
	`
	var name string
	err := r.db.QueryRowContext(ctx, query, cageID).Scan(&name)
	if err != nil {
		if err == sql.ErrNoRows {
			return "", nil // Không tìm thấy thì trả về chuỗi rỗng
		}
		return "", err
	}
	return name, nil
}

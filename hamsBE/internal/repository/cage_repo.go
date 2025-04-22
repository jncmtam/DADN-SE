package repository

import (
	"context"
	"database/sql"
	"fmt"
	"hamstercare/internal/database/queries"
	"hamstercare/internal/model"
)

type CageRepository struct {
	db *sql.DB
}

func NewCageRepository(db *sql.DB) *CageRepository {
	return &CageRepository{db: db}
}

func (r *CageRepository) CreateACageForID(ctx context.Context, nameCage, userID string) (*model.Cage, error) {
	query, err := queries.GetQuery("create_cage")
	if err != nil {
		return nil, fmt.Errorf("failed to get query: %w", err)
	}

	cage := &model.Cage{}
	err = r.db.QueryRowContext(ctx, query, nameCage, userID).Scan(
		&cage.ID, &cage.Name, &cage.UserID, &cage.Status, &cage.CreatedAt, &cage.UpdatedAt,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create cage: %w", err)
	}
	return cage, nil
}

func (r *CageRepository) GetCagesByID(ctx context.Context, userID string) ([]*model.CageResponse, error) {
	query, err := queries.GetQuery("get_cages_by_ID")
	if err != nil {
		return nil, fmt.Errorf("failed to get query: %w", err)
	}

	rows, err := r.db.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to query cages: %w", err)
	}
	defer rows.Close()

	var cages []*model.CageResponse
	for rows.Next() {
		cage := &model.CageResponse{}
		if err := rows.Scan(&cage.ID, &cage.Name, &cage.NumDevice, &cage.Status); err != nil {
			return nil, fmt.Errorf("failed to scan cage: %w", err)
		}
		cages = append(cages, cage)
	}
	return cages, nil
}

func (r *CageRepository) DeleteCageByID(ctx context.Context, cageID string) error {
	query, err := queries.GetQuery("delete_cage_by_id")
	if err != nil {
		return fmt.Errorf("failed to get query: %w", err)
	}
	_, err = r.db.ExecContext(ctx, query, cageID)
	if err != nil {
		return fmt.Errorf("failed to delete cage: %w", err)
	}
	return nil
}

func (r *CageRepository) GetACageByID(ctx context.Context, cageID string) (*model.CageResponse, error) {
	query, err := queries.GetQuery("get_cage_by_ID")
	if err != nil {
		return nil, fmt.Errorf("failed to get query: %w", err)
	}

	cage := &model.CageResponse{}
	err = r.db.QueryRowContext(ctx, query, cageID).Scan(&cage.ID, &cage.Name, &cage.Status)
	if err != nil {
		return nil, fmt.Errorf("failed to get cage: %w", err)
	}
	return cage, nil
}

func (r *CageRepository) CageExists(ctx context.Context, cageID string) (bool, error) {
	query, err := queries.GetQuery("check_cage_exists")
	if err != nil {
		return false, fmt.Errorf("failed to get query: %w", err)
	}
	var exists bool
	err = r.db.QueryRowContext(ctx, query, cageID).Scan(&exists)
	if err != nil {
		return false, fmt.Errorf("failed to check cage existence: %w", err)
	}
	return exists, nil
}

func (r *CageRepository) IsSameCage(ctx context.Context, deviceID, sensorID string) (bool, error) {
	query, err := queries.GetQuery("check_deviceID_isSameCage_sensorID")
	if err != nil {
		return false, fmt.Errorf("failed to get query: %w", err)
	}
	var count int
	err = r.db.QueryRowContext(ctx, query, deviceID, sensorID).Scan(&count)
	if err != nil {
		return false, fmt.Errorf("failed to check same cage: %w", err)
	}
	return count > 0, nil
}
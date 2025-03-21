// internal/repository/cage_repo.go
package repository

import (
	"context"
	"database/sql"
	"hamstercare/internal/database/queries"
	"hamstercare/internal/model"
)

type CageRepository struct{
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
		&cage.ID, &cage.Name,
	)
	if err != nil {
		return nil, err
	}
	return cage, nil
}


func (r *CageRepository) GetCagesByID(ctx context.Context, userID string) ([]*model.CageResponse, error) {
	query, err := queries.GetQuery("get_cages_by_ID")
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
		if err := rows.Scan(&cage.ID, &cage.Name, &cage.NumDevice, &cage.Status); err != nil {
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

func (r *CageRepository) GetACageByID(ctx context.Context, cageID string) (*model.CageResponse, error) {
	query, err := queries.GetQuery("get_cage_by_ID")
	if err != nil {
		return nil, err
	}

	cage := &model.CageResponse{}
	err = r.db.QueryRowContext(ctx, query, cageID).Scan(&cage.ID, &cage.Name, &cage.Status)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil 
		}
		return nil, err
	}

	return cage, nil
}



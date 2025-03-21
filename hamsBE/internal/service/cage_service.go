package service

import (
	"context"
	"errors"
	"hamstercare/internal/model"
	"hamstercare/internal/repository"
)

type CageService struct {
	CageRepo *repository.CageRepository
}

func NewCageService(cageRepo *repository.CageRepository) *CageService {
	return &CageService{CageRepo: cageRepo}
}


func (s *CageService) CreateCage(ctx context.Context, nameCage, userID string) (*model.Cage, error) {
	if userID == "" || nameCage == "" {
		return nil, errors.New("userID and nameCage are required")
	}

	cage, err := s.CageRepo.CreateACageForID(ctx, nameCage, userID)
	if err != nil {
		return nil, err
	}

	return cage, nil
}

func (s *CageService) GetCagesByUserID(ctx context.Context, userID string) ([]*model.CageResponse, error) {
	if userID == "" {
		return nil, errors.New("userID is required")
	}

	cages, err := s.CageRepo.GetCagesByID(ctx, userID)
	if err != nil {
		return nil, err
	}

	return cages, nil
}

func (s *CageService) DeleteCage(ctx context.Context, cageID string) error {
	if cageID == "" {
		return errors.New("cageID is required")
	}

	return s.CageRepo.DeleteCageByID(ctx, cageID)
}

func (s *CageService) GetACageByCageID(ctx context.Context, cageID string) (*model.CageResponse, error) {
	if cageID == "" {
		return nil, errors.New("cageID is required")
	}

	cage, err := s.CageRepo.GetACageByID(ctx, cageID)
	if err != nil {
		return nil, err
	}

	return cage, nil
}
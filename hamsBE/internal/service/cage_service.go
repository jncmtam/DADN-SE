package service

import (
	"context"
	"errors"
	"fmt"
	"hamstercare/internal/model"
	"hamstercare/internal/repository"
	"github.com/google/uuid"
)

type CageService struct {
	CageRepo *repository.CageRepository
	UserRepo *repository.UserRepository
}

func NewCageService(cageRepo *repository.CageRepository, userRepo *repository.UserRepository) *CageService {
	return &CageService{CageRepo: cageRepo, UserRepo: userRepo}
}

func (s *CageService) CreateCage(ctx context.Context, nameCage, userID string) (*model.Cage, error) {
	if userID == "" || nameCage == "" {
		return nil, errors.New("userID and nameCage are required")
	}

	if err := IsValidUUID(userID); err != nil {
		return nil, err
	}

	exists, err := s.UserRepo.UserExists(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("error checking user existence: %w", err)
	}
	if !exists {
		return nil, fmt.Errorf("%w: user with ID %s does not exist", ErrUserNotFound, userID)
	}

	cage, err := s.CageRepo.CreateACageForID(ctx, nameCage, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to create cage: %w", err)
	}
	return cage, nil
}

func (s *CageService) GetCagesByUserID(ctx context.Context, userID string) ([]*model.CageResponse, error) {
	if userID == "" {
		return nil, errors.New("userID is required")
	}

	if err := IsValidUUID(userID); err != nil {
		return nil, err
	}

	exists, err := s.UserRepo.UserExists(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("error checking user existence: %w", err)
	}
	if !exists {
		return nil, fmt.Errorf("%w: user with ID %s does not exist", ErrUserNotFound, userID)
	}

	cages, err := s.CageRepo.GetCagesByID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get cages by userID: %w", err)
	}
	return cages, nil
}

func (s *CageService) DeleteCage(ctx context.Context, cageID string) error {
	if cageID == "" {
		return errors.New("cageID is required")
	}

	if err := IsValidUUID(cageID); err != nil {
		return err
	}

	exists, err := s.CageRepo.CageExists(ctx, cageID)
	if err != nil {
		return fmt.Errorf("error checking cage existence: %w", err)
	}
	if !exists {
		return fmt.Errorf("%w: cage with ID %s does not exist", ErrCageNotFound, cageID)
	}

	return s.CageRepo.DeleteCageByID(ctx, cageID)
}

func (s *CageService) GetACageByCageID(ctx context.Context, cageID string) (*model.CageResponse, error) {
	if cageID == "" {
		return nil, errors.New("cageID is required")
	}

	if err := IsValidUUID(cageID); err != nil {
		return nil, err
	}

	exists, err := s.CageRepo.CageExists(ctx, cageID)
	if err != nil {
		return nil, fmt.Errorf("error checking cage existence: %w", err)
	}
	if !exists {
		return nil, fmt.Errorf("%w: cage with ID %s does not exist", ErrCageNotFound, cageID)
	}

	cage, err := s.CageRepo.GetACageByID(ctx, cageID)
	if err != nil {
		return nil, fmt.Errorf("failed to get cage by ID: %w", err)
	}
	return cage, nil
}

// Shared errors (consider moving to a shared package)
var (
	ErrUserNotFound   = errors.New("user not found")
	ErrCageNotFound   = errors.New("cage not found")
	ErrDeviceNotFound = errors.New("device not found")
	ErrSensorNotFound = errors.New("sensor not found")
	ErrRuleNotFound   = errors.New("rule not found")
	ErrDifferentCage  = errors.New("sensor and device are not in the same cage")
	ErrInvalidUUID    = errors.New("invalid UUID format")
)

func IsValidUUID(id string) error {
	if _, err := uuid.Parse(id); err != nil {
		return ErrInvalidUUID
	}
	return nil
}

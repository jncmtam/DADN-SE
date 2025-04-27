package service

import (
	"context"
	"errors"
	"fmt"
	"hamstercare/internal/model"
	"hamstercare/internal/repository"
	//"log"

	"github.com/google/uuid"
)

type CageService struct {
	CageRepo *repository.CageRepository
	UserRepo *repository.UserRepository
}

func NewCageService(cageRepo *repository.CageRepository, UserRepo *repository.UserRepository) *CageService {
	return &CageService{CageRepo: cageRepo, UserRepo: UserRepo}
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
		return nil, err
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
		return nil, err
	}

	if cages == nil {
        cages = []*model.CageResponse{}
    }

	return cages, nil
}

var ErrUserNotFound = errors.New("user not found")
var ErrCageNotFound = errors.New("cage not found")
var ErrDeviceNotFound = errors.New("device not found")
var ErrSensorNotFound = errors.New("sensor not found")
var ErrRuleNotFound = errors.New("automation rule not found")
var ErrDifferentCage = errors.New("sensor and device are not in the same cage")


func (s *CageService) DeleteCage(ctx context.Context, cageID string) error {
	if cageID == "" {
		return errors.New("cageID is required")
	}

	// Kiểm tra cageID hợp lệ
	if err := IsValidUUID(cageID); err != nil {
		return err // Trả về ErrInvalidUUID 
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

func (s *CageService) GetACageByCageID(ctx context.Context, cageID string) (*model.Cage, error) {
	if cageID == "" {
		return nil, errors.New("cageID is required")
	}

	if err := IsValidUUID(cageID); err != nil {
		return nil, err // Trả về ErrInvalidUUID 
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
		return nil, err
	}

	return cage, nil
}

func (s *CageService) IsCageNameExists(ctx context.Context, userID, name string) (bool, error) {
	if userID == "" {
		return false, errors.New("userID is required")
	}

	if err := IsValidUUID(userID); err != nil {
		return false, fmt.Errorf("%w: invalid userID format", ErrInvalidUUID)
	}

	exists, err := s.CageRepo.DoesCageNameExist(ctx, userID, name)
	if err != nil {
		return false, fmt.Errorf("error checking cage name existence: %w", err)
	}

	return exists, nil
}




// ErrInvalidUUID là lỗi chung khi ID không đúng định dạng UUID
var ErrInvalidUUID = errors.New("invalid UUID format")

// IsValidUUID kiểm tra xem một chuỗi có phải UUID hợp lệ hay không
func IsValidUUID(id string) error {
	if _, err := uuid.Parse(id); err != nil {
		return ErrInvalidUUID
	}
	return nil
}

func (c *CageService) IsSameCage(ctx context.Context, deviceID, sensorID string) (bool, error) {
     
	isSame, err := c.CageRepo.IsSameCage(ctx, deviceID, sensorID)
	if err != nil {
		return false, fmt.Errorf("error checking cage existence: %w", err)
	}

	return isSame, nil
}

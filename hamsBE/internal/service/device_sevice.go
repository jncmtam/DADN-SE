package service

import (
	"context"
	"errors"
	"fmt"
	"hamstercare/internal/model"
	"hamstercare/internal/repository"
)

type DeviceService struct {
	DeviceRepo *repository.DeviceRepository
	CageRepo *repository.CageRepository
}

func NewDeviceService(deviceRepo *repository.DeviceRepository, CageRepo *repository.CageRepository) *DeviceService {
	return &DeviceService{DeviceRepo: deviceRepo, CageRepo: CageRepo}
}

func (s *DeviceService) CreateDevice(ctx context.Context, name, deviceType, cageID string) (*model.Device, error) {
	if name == "" || deviceType == "" || cageID == ""{
		return nil, errors.New("name, deviceType and cageID are required")
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

	device, err := s.DeviceRepo.CreateDevice(ctx, name, deviceType, cageID)
	if err != nil {
		return nil, err
	}
	return device, nil
}


func (s *DeviceService) GetDevicesByCageID(ctx context.Context, cageID string) ([]*model.DeviceResponse, error) {
	if cageID == "" {
		return nil, errors.New("cageID is required")
	}

	devices, err := s.DeviceRepo.GetDevicesByCageID(ctx, cageID)
	if err != nil {
		return nil, err
	}

	return devices, nil
}

func (s *DeviceService) GetDeviceByID(ctx context.Context, deviceID string) (*model.DeviceResponse, error) {
	if deviceID == "" {
		return nil, errors.New("deviceID is required")
	}
	device, err := s.DeviceRepo.GetDeviceByID(ctx, deviceID)
	if err != nil {
		return nil, err
	}

	return device, nil
}

func (s *DeviceService) DeleteDevice(ctx context.Context, deviceID string) error {
	if deviceID == "" {
		return errors.New("deviceID is required")
	}

	if err := IsValidUUID(deviceID); err != nil {
		return err 
	}
	
	exists, err := s.DeviceRepo.DeviceExists(ctx, deviceID)
	if err != nil {
		return fmt.Errorf("error checking device existence: %w", err)
	}
	if !exists {
		return fmt.Errorf("%w: device with ID %s does not exist", ErrDeviceNotFound, deviceID)
	}

	return s.DeviceRepo.DeleteDeviceByID(ctx, deviceID)
}

func (s *DeviceService) ValidateDeviceAction(ctx context.Context, deviceID, action string) error {
	deviceType, err := s.DeviceRepo.CheckType(ctx, deviceID)
	if err != nil {
		return err
	}
	if action == "refill" && deviceType != "pump" {
		return fmt.Errorf("only devices of type 'pump' can use action 'refill'")
	}
	return nil
}

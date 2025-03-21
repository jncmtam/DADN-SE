package service

import (
	"context"
	"errors"
	"hamstercare/internal/model"
	"hamstercare/internal/repository"
)

type DeviceService struct {
	DeviceRepo *repository.DeviceRepository
}

func NewDeviceService(deviceRepo *repository.DeviceRepository) *DeviceService {
	return &DeviceService{DeviceRepo: deviceRepo}
}

func (s *DeviceService) CreateDevice(ctx context.Context, name, deviceType, cageID string) (*model.Device, error) {
	if name == "" || deviceType == "" || cageID == ""{
		return nil, errors.New("name, deviceType and cageID are required")
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

	return s.DeviceRepo.DeleteDeviceByID(ctx, deviceID)
}

package service

import (
	"context"
	"errors"
	"fmt"
	"hamstercare/internal/model"
	"hamstercare/internal/repository"
)

type SensorService struct {
	SensorRepo *repository.SensorRepository
	CageRepo *repository.CageRepository
}

func NewSensorService(SensorRepo *repository.SensorRepository, CageRepo *repository.CageRepository) *SensorService {
	return &SensorService{SensorRepo: SensorRepo, CageRepo: CageRepo}
}

func (s *SensorService) GetSensorsByCageID(ctx context.Context, cageID string) ([]*model.SensorResponse, error) {
	if cageID == "" {
		return nil, errors.New("cageID is required")
	}

	sensors, err := s.SensorRepo.GetSensorsByCageID(ctx, cageID)
	if err != nil {
		return nil, err
	}

	if sensors == nil {
		sensors = []*model.SensorResponse{}
	}

	return sensors, nil
}

func (s *SensorService) AddSensor(ctx context.Context, name, sensorType, unit, cageID string) (*model.Sensor, error) {
	if name == "" || sensorType == "" || unit == "" {
		return nil, errors.New("name, sensorType are required")
	}

	// Nếu có cageID, kiểm tra tính hợp lệ và sự tồn tại của cageID
	if cageID != "" {
		if err := IsValidUUID(cageID); err != nil {
			return nil, ErrInvalidUUID
		}

		exists, err := s.CageRepo.CageExists(ctx, cageID)
		if err != nil {
			return nil, fmt.Errorf("error checking cage existence: %w", err)
		}
		if !exists {
			return nil, ErrCageNotFound
		}
	}


	sensor, err := s.SensorRepo.CreateSensor(ctx, name, sensorType, unit, cageID)
	if err != nil {
		return nil, err
	}

	return sensor, nil
}

func (s *SensorService) DeleteSensor(ctx context.Context, sensorID string) error {
	if sensorID == ""{
		return errors.New("name, sensorType and cageID are required")
	}
	
	if err := IsValidUUID(sensorID); err != nil {
		return err 
	}
	
	exists, err := s.SensorRepo.SensorExists(ctx, sensorID)
	if err != nil {
		return fmt.Errorf("error checking sensor existence: %w", err)
	}
	if !exists {
		return fmt.Errorf("%w: sensor with ID %s does not exist", ErrSensorNotFound, sensorID)
	}


	return s.SensorRepo.DeleteSensorByID(ctx, sensorID)
}

func (s *SensorService) IsSensorNameExists(ctx context.Context, name string) (bool, error) {
	if name == "" {
		return false, errors.New("sensor name is required")
	}
	return s.SensorRepo.DoesSensorNameExist(ctx, name)
}

func (s *SensorService) AssignSensorToCage(ctx context.Context, sensorID, cageID string) error {
	// Validate UUID
	if err := IsValidUUID(sensorID); err != nil {
		return ErrInvalidUUID
	}
	if err := IsValidUUID(cageID); err != nil {
		return ErrInvalidUUID
	}

	// Check if device exists
	exists, err := s.SensorRepo.SensorExists(ctx, sensorID)
	if err != nil {
		return fmt.Errorf("error checking sensor existence: %w", err)
	}
	if !exists {
		return ErrSensorNotFound
	}

	// Check if cage exists
	exists, err = s.CageRepo.CageExists(ctx, cageID)
	if err != nil {
		return fmt.Errorf("error checking cage existence: %w", err)
	}
	if !exists {
		return ErrCageNotFound
	}

	// Update device
	if err := s.SensorRepo.AssignToCage(ctx, sensorID, cageID); err != nil {
		return fmt.Errorf("error assigning sensor to cage: %w", err)
	}

	return nil
}

func (s *SensorService) GetSensorsAssignable(ctx context.Context) ([]*model.SensorListResponse, error) {
	sensors, err := s.SensorRepo.GetSensorsAssignable(ctx)
	if err != nil {
		return nil, err
	}

	if sensors == nil {
		sensors = []*model.SensorListResponse{}
	}

	return sensors, nil
}

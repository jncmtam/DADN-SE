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

	return sensors, nil
}

func (s *SensorService) AddSensor(ctx context.Context, name, sensorType, unit, cageID string) (*model.Sensor, error) {
	if name == "" || sensorType == "" || unit == "" || cageID == ""{
		return nil, errors.New("name, sensorType and cageID are required")
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

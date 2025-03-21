package service

import (
	"context"
	"errors"
	"hamstercare/internal/model"
	"hamstercare/internal/repository"
)

type SensorService struct {
	SensorRepo *repository.SensorRepository
}

func NewSensorService(SensorRepo *repository.SensorRepository) *SensorService {
	return &SensorService{SensorRepo: SensorRepo}
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

func (s *SensorService) AddSensor(ctx context.Context, name, sensorType, cageID string) (*model.Sensor, error) {
	if name == "" || sensorType == "" || cageID == ""{
		return nil, errors.New("name, sensorType and cageID are required")
	}

	sensor, err := s.SensorRepo.CreateSensor(ctx, name, sensorType, cageID)
	if err != nil {
		return nil, err
	}

	return sensor, nil
}

func (s *SensorService) DeleteSensor(ctx context.Context, sensorID string) error {
	if sensorID == ""{
		return errors.New("name, sensorType and cageID are required")
	}
	
	return s.SensorRepo.DeleteSensorByID(ctx, sensorID)
}

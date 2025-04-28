package service

import (
	"context"
	"errors"
	"fmt"
	"hamstercare/internal/model"
	//"hamstercare/internal/mqtt"
	"hamstercare/internal/repository"
	"log"
	"os"
)

type DeviceService struct {
	DeviceRepo *repository.DeviceRepository
	CageRepo *repository.CageRepository
}

func NewDeviceService(deviceRepo *repository.DeviceRepository, CageRepo *repository.CageRepository) *DeviceService {
	return &DeviceService{DeviceRepo: deviceRepo, CageRepo: CageRepo}
}

func (s *DeviceService) CreateDevice(ctx context.Context, name, deviceType, cageID string) (*model.Device, error) {
	if name == "" || deviceType == "" {
		return nil, errors.New("name and deviceType are required")
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

	device, err := s.DeviceRepo.CreateDevice(ctx, name, deviceType, cageID)
	if err != nil {
		return nil, fmt.Errorf("failed to create device: %w", err)
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

	if devices == nil {
		devices = []*model.DeviceResponse{}
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

func (s *DeviceService) GetDevicesAssignable(ctx context.Context) ([]*model.DeviceListResponse, error) {
	devices, err := s.DeviceRepo.GetDevicesAssignable(ctx)
	if err != nil {
		return nil, err
	}

	if devices == nil {
		devices = []*model.DeviceListResponse{}
	}

	return devices, nil
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

func (s *DeviceService) IsDeviceNameExists(ctx context.Context, name string) (bool, error) {
	if name == "" {
		return false, errors.New("device name is required")
	}
	return s.DeviceRepo.DoesDeviceNameExist(ctx, name)
}

func (s *DeviceService) AssignDeviceToCage(ctx context.Context, deviceID, cageID string) error {
	// Validate UUID
	if err := IsValidUUID(deviceID); err != nil {
		return ErrInvalidUUID
	}
	if err := IsValidUUID(cageID); err != nil {
		return ErrInvalidUUID
	}

	// Check if device exists
	exists, err := s.DeviceRepo.DeviceExists(ctx, deviceID)
	if err != nil {
		return fmt.Errorf("error checking device existence: %w", err)
	}
	if !exists {
		return ErrDeviceNotFound
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
	if err := s.DeviceRepo.AssignToCage(ctx, deviceID, cageID); err != nil {
		return fmt.Errorf("error assigning device to cage: %w", err)
	}

	return nil
}

func (s *DeviceService) CountActiveDevicesByUserID(ctx context.Context, userID string) (int, error) {
	return s.DeviceRepo.CountActiveDevicesByUser(ctx, userID)
}

func (s *DeviceService) UpdateDeviceMode(ctx context.Context, deviceID, status string) error {
	// Kiểm tra trạng thái hợp lệ
	validModes := []string{"on", "off", "auto"}
	modeValid := false
	for _, validMode := range validModes {
		if status == validMode {
			modeValid = true
			break
		}
	}

	if !modeValid {
		return errors.New("invalid mode value")
	}

	// Lấy thông tin thiết bị từ repository
	device, err := s.DeviceRepo.GetDeviceByID(ctx, deviceID)
	if err != nil {
		return err
	}
	if device == nil {
		return errors.New("device not found")
	}

	// Cập nhật trạng thái thiết bị
	err = s.DeviceRepo.UpdateDeviceMode(ctx, deviceID, status)
	if err != nil {
		return err
	}

	return nil
}

func (s *DeviceService) UpdateDeviceName(ctx context.Context, deviceID, newNameDevice string) error {
	// Kiểm tra tên tốn tại

	err := s.DeviceRepo.UpdateDeviceName(ctx, deviceID, newNameDevice)
	if err != nil {
		return err
	}

	return nil
}



func HandleDeviceAction(userID, cageID, deviceID, deviceType string, action int) error {
	log.Printf("[INFO] Handling %s device action %d ", deviceID, action)
	broker := os.Getenv("MQTT_BROKER")
    if broker == "" {
        return fmt.Errorf("MQTT_BROKER environment variable is not set")
    }
	// switch deviceType {
	// case "fan":
	// 	mqtt.StartMQTTClientPub(broker, "hamster/user1/cage1/device/6/fan", action, "device", 6, "fan")
	// case "light":
	// 	mqtt.StartMQTTClientPub(broker, "hamster/user1/cage1/device/7/led", action, "device", 7, "led")
	// case "pump":
	// 	mqtt.StartMQTTClientPub(broker, "hamster/user1/cage1/device/8/pump", action, "device", 8, "pump")
	// default:
	// 	return fmt.Errorf("unknown device type: %s", deviceType)
	// }
	return nil
}

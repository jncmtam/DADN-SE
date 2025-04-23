// internal/repository/device_repo.go
package repository

import (
	"context"
	"database/sql"
	"errors"
	"hamstercare/internal/database/queries"
	"hamstercare/internal/model"
)

type DeviceRepository struct{
	db *sql.DB
}

func NewDeviceRepository(db *sql.DB) *DeviceRepository {
	return &DeviceRepository{db: db}
}


func (r *DeviceRepository) CreateDevice(ctx context.Context, name, deviceType, cageID string) (*model.Device, error) {
	query, err := queries.GetQuery("create_device")
	if err != nil {
		return nil, err
	}

	var cageIDValue interface{}
	if cageID == "" {
		cageIDValue = nil // Gán NULL
	} else {
		cageIDValue = cageID
	}

	device := &model.Device{}
	err = r.db.QueryRowContext(ctx, query, name, deviceType, cageIDValue).Scan(
		&device.ID, &device.Name,
	)
	if err != nil {
		return nil, err
	}

	return device, nil
}


func (r *DeviceRepository) GetDevicesByCageID(ctx context.Context, cageID string) ([]*model.DeviceResponse, error) {
	query, err := queries.GetQuery("get_devices_by_cageID")
	if err != nil {
		return nil, err
	}
	rows, err := r.db.QueryContext(ctx, query, cageID)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var devices []*model.DeviceResponse
    for rows.Next() {
        device := &model.DeviceResponse{}
        if err := rows.Scan(
            &device.ID, &device.Name, &device.Status,
        ); err != nil {
            return nil, err
        }
        devices = append(devices, device)
    }

    return devices, nil
}

func (r *DeviceRepository) GetDevicesAssignable(ctx context.Context) ([]*model.DeviceListResponse, error) {
	// Lấy query từ queries (hoặc bạn có thể viết trực tiếp query ở đây)
	query := "SELECT id, name FROM devices WHERE cage_id IS NULL"
	rows, err := r.db.QueryContext(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var devices []*model.DeviceListResponse
	for rows.Next() {
		device := &model.DeviceListResponse{}
		if err := rows.Scan(&device.ID, &device.Name); err != nil {
			return nil, err
		}
		devices = append(devices, device)
	}

	return devices, nil
}


func (r *DeviceRepository) GetDeviceByID(ctx context.Context, deviceID string) (*model.DeviceResponse, error) {
	query, err := queries.GetQuery("get_device_by_deviceID")
	if err != nil {
		return nil, err
	}

	device := &model.DeviceResponse{}
	err = r.db.QueryRowContext(ctx, query, deviceID).Scan(
		&device.ID, &device.Name, &device.Status,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	return device, nil
}

func (r *DeviceRepository) DeleteDeviceByID(ctx context.Context, deviceID string) error {
	query, err := queries.GetQuery("delete_device_by_id")
	if err != nil {
		return err
	}
	_, err = r.db.ExecContext(ctx, query, deviceID)
	return err
}

func (r *DeviceRepository) IsOwnedByUser(ctx context.Context, userID, deviceID string) (bool, error) {
	query, err := queries.GetQuery("IsOwnedByUser_Device")
	if err != nil {
		return false, err
	}
	var count int
    err = r.db.QueryRowContext(ctx, query, deviceID, userID).Scan(&count)
    return count > 0, err
}

func (r *DeviceRepository) DeviceExists(ctx context.Context, deviceID string) (bool, error) {
	query, err := queries.GetQuery("check_device_exists")
	if err != nil {
		return false, err
	}
	var exists bool
	err = r.db.QueryRowContext(ctx, query, deviceID).Scan(&exists)
	return exists, err
}

func (r *DeviceRepository) IsExistsID(ctx context.Context, deviceID string) (bool, error) {
	return r.DeviceExists(ctx, deviceID)
}

func (r *DeviceRepository) CheckType(ctx context.Context, deviceID string) (string, error) {
	query, err := queries.GetQuery("check_device_type")
	if err != nil {
		return "", err
	}
	var deviceType string
	err = r.db.QueryRowContext(ctx, query, deviceID).Scan(&deviceType)
	if err == sql.ErrNoRows {
		return "", errors.New("device not found")
	}
	return deviceType, err
}


func (r *DeviceRepository) DoesDeviceNameExist(ctx context.Context, name string) (bool, error) {
	query, err := queries.GetQuery("check_device_name_exists")
	if err != nil {
		return false, err
	}
	var exists bool
	err = r.db.QueryRowContext(ctx, query, name).Scan(&exists)
	return exists, err
}

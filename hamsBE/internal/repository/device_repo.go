// internal/repository/device_repo.go
package repository

import (
	"context"
	"database/sql"
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

	device := &model.Device{}
	err = r.db.QueryRowContext(ctx, query, name, deviceType, cageID).Scan(
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
// internal/repository/sensor_repo.go
package repository

import (
	"context"
	"database/sql"
	"errors"
	"hamstercare/internal/database/queries"
	"hamstercare/internal/model"
)

type SensorRepository struct{
	db *sql.DB
}

func NewSensorRepository(db *sql.DB) *SensorRepository {
	return &SensorRepository{db: db}
}

func (r *SensorRepository) GetSensorsByCageID(ctx context.Context, cageID string) ([]*model.SensorResponse, error) {
	query, err := queries.GetQuery("get_sensors_by_cageID")
	if err != nil {
		return nil, err
	}

	rows, err := r.db.QueryContext(ctx, query, cageID)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var sensors []*model.SensorResponse
    for rows.Next() {
        sensor := &model.SensorResponse{}
        if err := rows.Scan(
            &sensor.ID, &sensor.Type,
            &sensor.Unit,
        ); err != nil {
            return nil, err
        }
        sensors = append(sensors, sensor)
    }
    return sensors, nil
}

func (r *SensorRepository) CreateSensor(ctx context.Context, name, sensorType, unit, cageID string) (*model.Sensor, error) {
	query, err := queries.GetQuery("create_sensor")
	if err != nil {
		return nil, err
	}

	var cageIDValue interface{}
	if cageID == "" {
		cageIDValue = nil // Gán NULL
	} else {
		cageIDValue = cageID
	}

	sensor := &model.Sensor{}
	err = r.db.QueryRowContext(ctx, query, name, sensorType, unit, cageIDValue).Scan(
		&sensor.ID, &sensor.Name,
	)
	if err != nil {
		return nil, err
	}
	return sensor, nil
}


func (r *SensorRepository) DeleteSensorByID(ctx context.Context, sensorID string) error {
	query, err := queries.GetQuery("delete_sensor_by_id")
	if err != nil {
		return err
	}
	_, err = r.db.ExecContext(ctx, query, sensorID)
	return err
}

func (r *SensorRepository) SensorExists(ctx context.Context, sensorID string) (bool, error) {
	query, err := queries.GetQuery("check_sensor_exists")
	if err != nil {
		return false, err
	}
	var exists bool
	err = r.db.QueryRowContext(ctx, query, sensorID).Scan(&exists)
	return exists, err
}

func (r *SensorRepository) DoesSensorNameExist(ctx context.Context, name string) (bool, error) {
	query, err := queries.GetQuery("check_sensor_name_exists")
	if err != nil {
		return false, err
	}
	var exists bool
	err = r.db.QueryRowContext(ctx, query, name).Scan(&exists)
	return exists, err
}

func (r *SensorRepository) AssignToCage(ctx context.Context, sensorID, cageID string) error {
	query, err := queries.GetQuery("assign_sensor_to_cage")
	if err != nil {
		return err
	}

	result, err := r.db.ExecContext(ctx, query, cageID, sensorID)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if rowsAffected == 0 {
		return errors.New("sensor not found")
	}
	return nil
}

func (r *SensorRepository) GetSensorsAssignable(ctx context.Context) ([]*model.SensorListResponse, error) {
	query, err := queries.GetQuery("get_sensors_assignable")
	if err != nil {
		return nil, err
	}

	rows, err := r.db.QueryContext(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var sensors []*model.SensorListResponse
	for rows.Next() {
		sensor := &model.SensorListResponse{}
		if err := rows.Scan(&sensor.ID, &sensor.Name); err != nil {
			return nil, err
		}
		sensors = append(sensors, sensor)
	}

	return sensors, nil
}

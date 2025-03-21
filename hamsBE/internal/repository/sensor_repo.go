// internal/repository/sensor_repo.go
package repository

import (
	"context"
	"database/sql"
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
            &sensor.Value, &sensor.Unit,
        ); err != nil {
            return nil, err
        }
        sensors = append(sensors, sensor)
    }
    return sensors, nil
}

func (r *SensorRepository) CreateSensor(ctx context.Context, name, sensorType, cageID string) (*model.Sensor, error) {
	query, err := queries.GetQuery("create_sensor")
	if err != nil {
		return nil, err
	}

	sensor := &model.Sensor{}
	err = r.db.QueryRowContext(ctx, query, name, sensorType, cageID).Scan(
		&sensor.ID,
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

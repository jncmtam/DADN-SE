package repository

import (
    "context"
    "database/sql"
    "hamstercare/internal/model"
    "time"
)

// StatisticRepository handles operations related to statistical/sensor data
type StatisticRepository struct {
    db *sql.DB
}

// NewStatisticRepository creates a new instance of StatisticRepository
func NewStatisticRepository(db *sql.DB) *StatisticRepository {
    return &StatisticRepository{db: db}
}

// InsertSensorData inserts sensor data into the database
func (r *StatisticRepository) InsertSensorData(ctx context.Context, data *model.SensorData) error {
    query := `
        INSERT INTO sensor_data (sensor_id, value, unit, condition_met, recorded_at)
        VALUES ($1, $2, $3, $4, $5)
    `
    _, err := r.db.ExecContext(ctx, query,
        data.SensorID,
        data.Value,
        data.Unit,
        data.ConditionMet,
        time.Now(),
    )
    if err != nil {
        return err
    }
    return nil
}
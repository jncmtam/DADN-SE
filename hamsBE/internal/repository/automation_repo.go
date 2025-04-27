// automation_repository.go
package repository

import (
	"context"
	"database/sql"
	"fmt"
	"hamstercare/internal/model"
	"log"

	"github.com/google/uuid"
)

type AutomationRepository struct {
    db *sql.DB
}

func NewAutomationRepository(db *sql.DB) *AutomationRepository {
    return &AutomationRepository{db: db}
}

func (r *AutomationRepository) CreateAutomationRule(ctx context.Context, rule *model.AutomationRule) (*model.AutomationRule, error) {
    var sensorType string
    err := r.db.QueryRowContext(ctx, `
        SELECT type FROM sensors WHERE id = $1
    `, rule.SensorID).Scan(&sensorType)
    if err != nil {
        return nil, fmt.Errorf("failed to fetch sensor type: %v", err)
    }

    rule.SensorType = sensorType

    err = r.db.QueryRowContext(ctx, `
        INSERT INTO automation_rules (id, sensor_id, device_id, cage_id, condition, threshold, action, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        RETURNING id
    `, uuid.New().String(), rule.SensorID, rule.DeviceID, rule.CageID, rule.Condition, rule.Threshold, rule.Action).Scan(&rule.ID)
    if err != nil {
        return nil, fmt.Errorf("failed to create automation rule: %v", err)
    }

    return rule, nil
}

func (r *AutomationRepository) DeleteAutomationRule(ctx context.Context, ruleID string) error {
    _, err := r.db.ExecContext(ctx, `DELETE FROM automation_rules WHERE id = $1`, ruleID)
    return err
}

func (r *AutomationRepository) GetAutomationRulesByDeviceID(ctx context.Context, deviceID string) ([]*model.AutoRuleResByDeviceID, error) {
    rows, err := r.db.QueryContext(ctx, `
        SELECT ar.id, ar.sensor_id, s.type, ar.condition, ar.threshold, ar.action, ar.unit
        FROM automation_rules ar
        JOIN sensors s ON ar.sensor_id = s.id
        WHERE ar.device_id = $1
    `, deviceID)
    if err != nil {
        return nil, fmt.Errorf("failed to query automation rules: %v", err)
    }
    defer rows.Close()

    var rules []*model.AutoRuleResByDeviceID
    for rows.Next() {
        var rule model.AutoRuleResByDeviceID
        if err := rows.Scan(&rule.ID, &rule.SensorID, &rule.SensorType, &rule.Condition, &rule.Threshold, &rule.Action, &rule.Unit); err != nil {
            log.Printf("Error scanning rule: %v", err)
            continue
        }
        rules = append(rules, &rule)
    }

    return rules, nil
}

func (r *AutomationRepository) RuleExists(ctx context.Context, ruleID string) (bool, error) {
    var exists bool
    err := r.db.QueryRowContext(ctx, `SELECT EXISTS (SELECT 1 FROM automation_rules WHERE id = $1)`, ruleID).Scan(&exists)
    return exists, err
}

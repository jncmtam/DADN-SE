// automation_repository.go
package repository

import (
	"context"
	"database/sql"
	"hamstercare/internal/model"

	"github.com/google/uuid"
)

type AutomationRepository struct {
    db *sql.DB
}

func NewAutomationRepository(db *sql.DB) *AutomationRepository {
    return &AutomationRepository{db: db}
}

func (r *AutomationRepository) CreateAutomationRule(ctx context.Context, rule *model.AutomationRule) (*model.AutomationRule, error) {
    rule.ID = uuid.New().String()
    query := `
        INSERT INTO automation_rules (id, sensor_id, device_id, cage_id, condition, threshold, unit, action, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        RETURNING id, sensor_id, device_id, cage_id, condition, threshold, unit, action, created_at, updated_at
    `
    err := r.db.QueryRowContext(ctx, query, rule.ID, rule.SensorID, rule.DeviceID, rule.CageID, rule.Condition, rule.Threshold, rule.Unit, rule.Action).
        Scan(&rule.ID, &rule.SensorID, &rule.DeviceID, &rule.CageID, &rule.Condition, &rule.Threshold, &rule.Unit, &rule.Action, &rule.CreatedAt, &rule.UpdatedAt)
    if err != nil {
        return nil, err
    }
    return rule, nil
}

func (r *AutomationRepository) DeleteAutomationRule(ctx context.Context, ruleID string) error {
    _, err := r.db.ExecContext(ctx, `DELETE FROM automation_rules WHERE id = $1`, ruleID)
    return err
}

func (r *AutomationRepository) GetAutomationRulesByDeviceID(ctx context.Context, deviceID string) ([]*model.AutoRuleResByDeviceID, error) {
    rows, err := r.db.QueryContext(ctx, `
        SELECT id, sensor_id, condition, threshold, unit, action 
        FROM automation_rules 
        WHERE device_id = $1
    `, deviceID)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var rules []*model.AutoRuleResByDeviceID
    for rows.Next() {
        rule := &model.AutoRuleResByDeviceID{}
        if err := rows.Scan(&rule.ID, &rule.SensorID, &rule.Condition, &rule.Threshold, &rule.Unit, &rule.Action); err != nil {
            return nil, err
        }
        rules = append(rules, rule)
    }
    return rules, nil
}

func (r *AutomationRepository) RuleExists(ctx context.Context, ruleID string) (bool, error) {
    var exists bool
    err := r.db.QueryRowContext(ctx, `SELECT EXISTS (SELECT 1 FROM automation_rules WHERE id = $1)`, ruleID).Scan(&exists)
    return exists, err
}
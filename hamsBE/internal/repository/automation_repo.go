// internal/repository/automation_repo.go
package repository

import (
	"context"
	"database/sql"
	"hamstercare/internal/database/queries"
	"hamstercare/internal/model"
)

type AutomationRepository struct{
	db *sql.DB
}

func NewAutomationRepository(db *sql.DB) *AutomationRepository {
	return &AutomationRepository{db: db}
}

func (r *AutomationRepository) CreateAutomationRule(ctx context.Context, rule *model.AutomationRule) (*model.AutomationRule, error) {
	query, err := queries.GetQuery("create_automation_rule")
	if err != nil {
		return nil, err
	}
	createdRule := &model.AutomationRule{}
	err = r.db.QueryRowContext(ctx, query,
		rule.SensorID, rule.DeviceID, rule.Condition, rule.Threshold, rule.Unit, rule.Action,
	).Scan(&createdRule.ID, &createdRule.CreatedAt)
	if err != nil {
		return nil, err
	}

	return createdRule, nil
}

func (r *AutomationRepository) DeleteAutomationRule(ctx context.Context, ruleID string) error {
	query, err := queries.GetQuery("delete_automation_rule")
	if err != nil {
		return err
	}

	_, err = r.db.ExecContext(ctx, query, ruleID)
	return err
}


func (r *AutomationRepository) GetAutomationRulesByDeviceID(ctx context.Context, deviceID string) ([]*model.AutomationRule, error) {
	query, err := queries.GetQuery("get_automation_rules_by_deviceID")
	if err != nil {
		return nil, err
	}

	rows, err := r.db.QueryContext(ctx, query, deviceID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var rules []*model.AutomationRule
	for rows.Next() {
		rule := &model.AutomationRule{}
		err := rows.Scan(&rule.ID, &rule.SensorID, &rule.Condition, &rule.Threshold, &rule.Unit, &rule.Action)
		if err != nil {
			return nil, err
		}
		rules = append(rules, rule)
	}
	return rules, nil
}
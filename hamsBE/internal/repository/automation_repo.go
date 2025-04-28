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


func (r *AutomationRepository) GetAutomationRulesByDeviceID(ctx context.Context, deviceID string) ([]*model.AutoRuleResByDeviceID, error) {
	query, err := queries.GetQuery("get_automation_rules_by_deviceID")
	if err != nil {
		return nil, err
	}

	rows, err := r.db.QueryContext(ctx, query, deviceID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var rules []*model.AutoRuleResByDeviceID
	for rows.Next() {
		rule := &model.AutoRuleResByDeviceID{}
		err := rows.Scan(&rule.ID, &rule.SensorID, &rule.SensorType, &rule.Condition, &rule.Threshold, &rule.Unit, &rule.Action)
		if err != nil {
			return nil, err
		}
		rules = append(rules, rule)
	}
	return rules, nil
}

func (r *AutomationRepository) IsOwnedByUser(ctx context.Context, userID, ruleID string) (bool, error) {
	query, err := queries.GetQuery("IsOwnedByUser_Automation")
	if err != nil {
		return false, err
	}
	var count int
    err = r.db.QueryRowContext(ctx, query, ruleID, userID).Scan(&count)
    return count > 0, err
}

func (r *AutomationRepository) RuleExists(ctx context.Context, ruleID string) (bool, error) {
	query, err := queries.GetQuery("check_automation_rule_exists")
	if err != nil {
		return false, err
	}
	var exists bool
	err = r.db.QueryRowContext(ctx, query, ruleID).Scan(&exists)
	return exists, err
}

func (r *AutomationRepository) IsExistsID(ctx context.Context, ruleID string) (bool, error) {
	return r.RuleExists(ctx, ruleID)
}

func (r *AutomationRepository) GetAutomationRulesBySensorID(ctx context.Context, sensorID string) ([]*model.AutoRuleResBySensorID, error) {
    query, err := queries.GetQuery("get_automation_rules_by_sensorID")
    if err != nil {
        return nil, err
    }

	//log.Printf("[DEBUG] Executing query with sensorID: %s", sensorID)

    rows, err := r.db.QueryContext(ctx, query, sensorID)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var rules []*model.AutoRuleResBySensorID
    for rows.Next() {
        rule := &model.AutoRuleResBySensorID{}
		//log.Printf("[DEBUG] Scanning row: %v", rows)
		err := rows.Scan(
			&rule.ID, 
			&rule.SensorID, 
			&rule.SensorType, 
			&rule.Condition, 
			&rule.Threshold, 
			&rule.Unit, 
			&rule.Action,
			&rule.CageID,    
			&rule.UserID,    
			&rule.DeviceType, 
		)
		if err != nil {
			//log.Printf("[ERROR] Error scanning row: %v", err)
			return nil, err
		}
		//log.Printf("[DEBUG] Successfully scanned rule: %+v", rule)
		
        rules = append(rules, rule)
    }
    return rules, nil
}

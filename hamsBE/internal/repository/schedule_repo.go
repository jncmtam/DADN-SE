// internal/repository/Schedule_repo.go
package repository

import (
	"context"
	"database/sql"
	"hamstercare/internal/database/queries"
	"hamstercare/internal/model"
	//"log"

	"github.com/lib/pq"
)

type ScheduleRepository struct{
	db *sql.DB
}

func NewScheduleRepository(db *sql.DB) *ScheduleRepository {
	return &ScheduleRepository{db: db}
}

func (r *ScheduleRepository) CreateScheduleRule(ctx context.Context, rule *model.ScheduleRule) (*model.ScheduleRule, error) {
	query, err := queries.GetQuery("create_schedule_rule")
	if err != nil {
		return nil, err
	}
	createdRule := &model.ScheduleRule{}
	err = r.db.QueryRowContext(ctx, query,
		rule.DeviceID, rule.ExecutionTime, pq.Array(rule.Days), rule.Action,
	).Scan(&createdRule.ID, &createdRule.CreatedAt)
	if err != nil {
		return nil, err
	}

	return createdRule, nil
}

func (r *ScheduleRepository) DeleteScheduleRule(ctx context.Context, ruleID string) error {
	query, err := queries.GetQuery("delete_schedule_rule")
	if err != nil {
		return err
	}

	_, err = r.db.ExecContext(ctx, query, ruleID)
	return err
}


func (r *ScheduleRepository) GetScheduleRulesByDeviceID(ctx context.Context, deviceID string) ([]*model.ScheduleResGetByDeviceID, error) {
	query, err := queries.GetQuery("get_schedule_rules_by_deviceID")
	if err != nil {
		return nil, err
	}

	rows, err := r.db.QueryContext(ctx, query, deviceID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var rules []*model.ScheduleResGetByDeviceID
	for rows.Next() {
		rule := &model.ScheduleResGetByDeviceID{}
		err := rows.Scan(&rule.ID, &rule.ExecutionTime, pq.Array(&rule.Days), &rule.Action)
		if err != nil {
			return nil, err
		}
		rules = append(rules, rule)
	}
	return rules, nil
}

func (r *ScheduleRepository) IsOwnedByUser(ctx context.Context, userID, ruleID string) (bool, error) {
	query, err := queries.GetQuery("IsOwnedByUser_Schedule")
	if err != nil {
		return false, err
	}
	var count int
    err = r.db.QueryRowContext(ctx, query, ruleID, userID).Scan(&count)
    return count > 0, err
}

func (r *ScheduleRepository) RuleExists(ctx context.Context, ruleID string) (bool, error) {
	query, err := queries.GetQuery("check_schedule_rule_exists")
	if err != nil {
		return false, err
	}
	var exists bool
	err = r.db.QueryRowContext(ctx, query, ruleID).Scan(&exists)
	return exists, err
}

func (r *ScheduleRepository) IsExistsID(ctx context.Context, ruleID string) (bool, error) {
	return r.RuleExists(ctx, ruleID)
}
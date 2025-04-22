package service

import (
	"context"
	"errors"
	"fmt"
	"hamstercare/internal/model"
	"hamstercare/internal/repository"
)

type ScheduleService struct {
	ScheduleRepo *repository.ScheduleRepository
}

func NewScheduleService(scheduleRepo *repository.ScheduleRepository) *ScheduleService {
	return &ScheduleService{ScheduleRepo: scheduleRepo}
}

func (s *ScheduleService) AddScheduleRule(ctx context.Context, rule *model.ScheduleRule) (*model.ScheduleRule, error) {
	if rule == nil {
		return nil, errors.New("schedule rule is required")
	}
	if rule.DeviceID == "" || rule.ExecutionTime == "" || len(rule.Days) == 0 || rule.Action == "" {
		return nil, errors.New("all fields are required")
	}

	// Validate Days and Action
	validDays := map[string]bool{"Mon": true, "Tue": true, "Wed": true, "Thu": true, "Fri": true, "Sat": true, "Sun": true}
	for _, day := range rule.Days {
		if !validDays[day] {
			return nil, fmt.Errorf("invalid day: %s", day)
		}
	}
	validActions := map[string]bool{"turn_on": true, "turn_off": true}
	if !validActions[rule.Action] {
		return nil, fmt.Errorf("invalid action: %s", rule.Action)
	}

	createdRule, err := s.ScheduleRepo.CreateScheduleRule(ctx, rule)
	if err != nil {
		return nil, fmt.Errorf("failed to create schedule rule: %w", err)
	}
	return createdRule, nil
}

func (s *ScheduleService) RemoveScheduleRule(ctx context.Context, ruleID string) error {
	if ruleID == "" {
		return errors.New("ruleID is required")
	}

	if err := IsValidUUID(ruleID); err != nil {
		return err
	}

	exists, err := s.ScheduleRepo.RuleExists(ctx, ruleID)
	if err != nil {
		return fmt.Errorf("error checking schedule rule existence: %w", err)
	}
	if !exists {
		return fmt.Errorf("%w: schedule rule with ID %s does not exist", ErrRuleNotFound, ruleID)
	}

	return s.ScheduleRepo.DeleteScheduleRule(ctx, ruleID)
}

func (s *ScheduleService) GetRulesByDeviceID(ctx context.Context, deviceID string) ([]*model.ScheduleResGetByDeviceID, error) {
	if deviceID == "" {
		return nil, errors.New("deviceID is required")
	}

	rules, err := s.ScheduleRepo.GetScheduleRulesByDeviceID(ctx, deviceID)
	if err != nil {
		return nil, fmt.Errorf("failed to get schedule rules by deviceID: %w", err)
	}
	return rules, nil
}
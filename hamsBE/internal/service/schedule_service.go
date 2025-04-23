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

func NewScheduleService(ScheduleRepo *repository.ScheduleRepository) *ScheduleService {
	return &ScheduleService{ScheduleRepo: ScheduleRepo}
}


func (s *ScheduleService) AddScheduleRule(ctx context.Context, rule *model.ScheduleRule) (*model.ScheduleRule, error) {
	if rule == nil {
		return nil, errors.New("schedule rule is required")
	}
	if rule.DeviceID == "" || rule.ExecutionTime == "" ||
		rule.Days == nil   || rule.Action == "" {
		return nil, errors.New("all fields are required")
	}

	rule, err := s.ScheduleRepo.CreateScheduleRule(ctx, rule)
	if err != nil {
		return nil, err
	}

	return rule, nil
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
			return fmt.Errorf("%w: Schedule rule with ID %s does not exist", ErrRuleNotFound, ruleID)
		}
	
	return s.ScheduleRepo.DeleteScheduleRule(ctx, ruleID)
}

func (s *ScheduleService) GetRulesByDeviceID(ctx context.Context, deviceID string) ([]*model.ScheduleResGetByDeviceID, error) {
	if deviceID == "" {
		return nil, errors.New("deviceID is required")
	}

	rules, err := s.ScheduleRepo.GetScheduleRulesByDeviceID(ctx, deviceID)
	if err != nil {
		return nil, err
	}

	if rules == nil {
		rules = []*model.ScheduleResGetByDeviceID{}
	}

	return rules, nil
}


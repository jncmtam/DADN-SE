package service

import (
	"context"
	"errors"
	"fmt"
	"hamstercare/internal/model"
	"hamstercare/internal/repository"
)

type AutomationService struct {
	AutomationRepo *repository.AutomationRepository
}

func NewAutomationService(AutomationRepo *repository.AutomationRepository) *AutomationService {
	return &AutomationService{AutomationRepo: AutomationRepo}
}


func (s *AutomationService) AddAutomationRule(ctx context.Context, rule *model.AutomationRule) (*model.AutomationRule, error) {
	if rule == nil {
		return nil, errors.New("automation rule is required")
	}
	if rule.SensorID == "" || rule.DeviceID == "" || rule.Condition == "" ||
		rule.Threshold == 0 || rule.Unit == "" || rule.Action == "" {
		return nil, errors.New("all fields are required")
	}

	rule, err := s.AutomationRepo.CreateAutomationRule(ctx, rule)
	if err != nil {
		return nil, err
	}

	return rule, nil
}

func (s *AutomationService) RemoveAutomationRule(ctx context.Context, ruleID string) error {
	if ruleID == "" {
		return errors.New("ruleID is required")
	}

		// Kiểm tra cageID hợp lệ
		if err := IsValidUUID(ruleID); err != nil {
			return err 
		}
		
		exists, err := s.AutomationRepo.RuleExists(ctx, ruleID)
		if err != nil {
			return fmt.Errorf("error checking automation rule existence: %w", err)
		}
		if !exists {
			return fmt.Errorf("%w: automation rule with ID %s does not exist", ErrRuleNotFound, ruleID)
		}
	
	return s.AutomationRepo.DeleteAutomationRule(ctx, ruleID)
}

func (s *AutomationService) GetRulesByDeviceID(ctx context.Context, deviceID string) ([]*model.AutoRuleResByDeviceID, error) {
	if deviceID == "" {
		return nil, errors.New("deviceID is required")
	}

	rules, err := s.AutomationRepo.GetAutomationRulesByDeviceID(ctx, deviceID)
	if err != nil {
		return nil, err
	}

	return rules, nil
}


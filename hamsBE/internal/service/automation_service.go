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
	CageRepo       *repository.CageRepository
}

func NewAutomationService(automationRepo *repository.AutomationRepository, cageRepo *repository.CageRepository) *AutomationService {
	return &AutomationService{AutomationRepo: automationRepo, CageRepo: cageRepo}
}

func (s *AutomationService) AddAutomationRule(ctx context.Context, rule *model.AutomationRule) (*model.AutomationRule, error) {
	if rule == nil {
		return nil, errors.New("automation rule is required")
	}
	if rule.SensorID == "" || rule.DeviceID == "" || rule.Condition == "" ||
		rule.Threshold == 0 || rule.Unit == "" || rule.Action == "" {
		return nil, errors.New("all fields are required")
	}

	// Validate Condition and Action
	validConditions := map[string]bool{">": true, "<": true, "=": true, ">=": true, "<=": true}
	if !validConditions[rule.Condition] {
		return nil, fmt.Errorf("invalid condition: %s", rule.Condition)
	}
	validActions := map[string]bool{"turn_on": true, "turn_off": true}
	if !validActions[rule.Action] {
		return nil, fmt.Errorf("invalid action: %s", rule.Action)
	}

	// Check if sensor and device are in the same cage
	isSame, err := s.CageRepo.IsSameCage(ctx, rule.DeviceID, rule.SensorID)
	if err != nil {
		return nil, fmt.Errorf("failed to check if sensor and device are in the same cage: %w", err)
	}
	if !isSame {
		return nil, fmt.Errorf("%w: sensor %s and device %s", ErrDifferentCage, rule.SensorID, rule.DeviceID)
	}

	createdRule, err := s.AutomationRepo.CreateAutomationRule(ctx, rule)
	if err != nil {
		return nil, fmt.Errorf("failed to create automation rule: %w", err)
	}
	return createdRule, nil
}

func (s *AutomationService) RemoveAutomationRule(ctx context.Context, ruleID string) error {
	if ruleID == "" {
		return errors.New("ruleID is required")
	}

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
		return nil, fmt.Errorf("failed to get automation rules by deviceID: %w", err)
	}
	return rules, nil
}
package service

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"hamstercare/internal/model"
	"hamstercare/internal/repository"
)

type AutomationService struct {
	AutomationRepo *repository.AutomationRepository
}
type AutomationRepository struct {
	db *sql.DB
}

func NewAutomationService(AutomationRepo *repository.AutomationRepository) *AutomationService {
	return &AutomationService{AutomationRepo: AutomationRepo}
}

func (s *AutomationService) AddAutomationRule(ctx context.Context, rule *model.AutomationRule, cageService *CageService) (*model.AutomationRule, error) {
	if rule == nil {
		return nil, errors.New("automation rule is required")
	}
	if rule.SensorID == "" || rule.DeviceID == "" || rule.CageID == "" || rule.Condition == "" ||
		rule.Threshold == 0 || rule.Action == "" {
		return nil, errors.New("all fields are required")
	}

	// Verify sensor and device are in the same cage
	isSame, err := cageService.CageRepo.IsSameCage(ctx, rule.DeviceID, rule.SensorID)
	if err != nil {
		return nil, fmt.Errorf("error checking cage: %w", err)
	}
	if !isSame {
		return nil, fmt.Errorf("%w: sensor %s and device %s", ErrDifferentCage, rule.SensorID, rule.DeviceID)
	}

	rule, err = s.AutomationRepo.CreateAutomationRule(ctx, rule)
	if err != nil {
		return nil, fmt.Errorf("failed to create automation rule: %w", err)
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

	if rules == nil {
		rules = []*model.AutoRuleResByDeviceID{}
	}

	return rules, nil
}

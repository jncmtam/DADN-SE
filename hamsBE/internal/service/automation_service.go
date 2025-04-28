package service

import (
	"context"
	"errors"
	"fmt"
	"hamstercare/internal/model"
	"hamstercare/internal/repository"
	"log"
	"time"
)

type AutomationService struct {
	AutomationRepo *repository.AutomationRepository
}

func NewAutomationService(AutomationRepo *repository.AutomationRepository) *AutomationService {
	return &AutomationService{AutomationRepo: AutomationRepo}
}


func (s *AutomationService) AddAutomationRule(ctx context.Context, rule *model.AutomationRule, cageService *CageService) (*model.AutomationRule, error) {
	if rule == nil {
		return nil, errors.New("automation rule is required")
	}
	if rule.SensorID == "" || rule.DeviceID == "" || rule.Condition == "" ||
		rule.Threshold == 0 || rule.Action == "" {
		return nil, errors.New("all fields are required")
	}

	// Kiem tra sensorID cùng cage với deviceID
	isSame, err := cageService.CageRepo.IsSameCage(ctx, rule.DeviceID, rule.SensorID)
	if err != nil {
		return nil, err
	}

	if !isSame {
		return nil, fmt.Errorf("%w: sensor %s and device %s", ErrDifferentCage, rule.SensorID, rule.DeviceID)
	}
	
	rule, err = s.AutomationRepo.CreateAutomationRule(ctx, rule)
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

	if rules == nil {
		rules = []*model.AutoRuleResByDeviceID{}
	}

	return rules, nil
}

func (s *AutomationService) GetRulesBySensorID(ctx context.Context, sensorID string) ([]*model.AutoRuleResBySensorID, error) {
	if sensorID == "" {
		return nil, errors.New("sensorID is required")
	}

	rules, err := s.AutomationRepo.GetAutomationRulesBySensorID(ctx, sensorID)
	if err != nil {
		return nil, err
	}

	if rules == nil {
		rules = []*model.AutoRuleResBySensorID{}
	}

	return rules, nil
}


func HandleSensorUpdate(payload map[string]interface{}, automationService *AutomationService) {
	log.Println("[DEBUG] HandleSensorUpdate called with payload:", payload)

	// Parse sensorID và value
	sensorID, _ := payload["sensor_id"].(string)
	value, _ := payload["value"].(float64)
	log.Printf("[DEBUG] Parsed sensorID: %s, value: %f", sensorID, value)

	// Lấy các automation rule của device có mode auto theo sensorID
	rules, err := automationService.GetRulesBySensorID(context.Background(), sensorID)
	if err != nil {
		log.Printf("[ERROR] Failed to get automation rules for sensorID %s: %v", sensorID, err)
		return
	}

	log.Printf("[DEBUG] Found %d automation rules for sensorID %s", len(rules), sensorID)

	// Duyệt từng rule
	for _, rule := range rules {
		log.Printf("[DEBUG] Processing rule: %+v", rule)

		condition := rule.Condition
		threshold := rule.Threshold
		action := rule.Action

		log.Printf("[DEBUG] Rule details - Condition: %s, Threshold: %f, Action: %s", condition, threshold, action)

		// Kiểm tra điều kiện
		var match bool
		switch condition {
		case ">":
			match = value > threshold
		case "<":
			match = value < threshold
		case "=":
			match = value == threshold
		default:
			log.Printf("[WARN] Unknown condition '%s' in rule", condition)
		}

		log.Printf("[DEBUG] Condition %s evaluated for sensorID %s: match=%v", condition, sensorID, match)

		if match {
			// Điều kiện đúng, thực hiện action
			var actionValue int
			switch action {
			case "turn_on":
				actionValue = 1
				log.Printf("[DEBUG] Condition matched: turning ON device for sensorID %s", sensorID)
			case "turn_off":
				actionValue = 0
				log.Printf("[DEBUG] Condition matched: turning OFF device for sensorID %s", sensorID)
			case "re_fill":
				actionValue = 1
				log.Printf("[DEBUG] Condition matched: starting refill for sensorID %s", sensorID)

				// Bật thiết bị
				HandleDeviceAction(rule.CageID, rule.UserID, rule.SensorID, rule.DeviceType, actionValue)

				// Tự động tắt sau 5 giây // tạm thời update sau
				go func() {
					time.Sleep(5 * time.Second)
					HandleDeviceAction(rule.CageID, rule.UserID, rule.SensorID, rule.DeviceType, 0)
					log.Printf("[DEBUG] Device auto-turned off after 5s for sensorID %s", rule.SensorID)
				}()
				continue // Với "re_fill" thì skip bước gọi HandleDeviceAction thêm lần nữa bên dưới
			default:
				log.Printf("[WARN] Unknown action '%s' in rule", action)
			}

			HandleDeviceAction(rule.CageID, rule.UserID, rule.SensorID, rule.DeviceType, actionValue)
		} else {
			// Điều kiện sai, thực hiện reverse action
			// Lấy status của device từ db 
			var reverseActionValue int
			switch action {
			case "turn_on":
				reverseActionValue = 0
				// Kiểm tra status có đang off
				// Không thì gọi tắt
				// Có thi bỏ qua
				log.Printf("[DEBUG] Condition not matched: turning OFF device for sensorID %s", sensorID)
			case "turn_off":
				reverseActionValue = 1
				// Kiểm tra status có đang onl
				// Không thì gọi tắt
				// Có thi bỏ qua
				log.Printf("[DEBUG] Condition not matched: turning ON device for sensorID %s", sensorID)
			case "re_fill":
				log.Printf("[DEBUG] Condition not matched: stopping refill for sensorID %s", sensorID)
				continue
			default:
				log.Printf("[WARN] Unknown action '%s' for reverse in rule", action)
			}

			HandleDeviceAction(rule.CageID, rule.UserID, rule.SensorID, rule.DeviceType, reverseActionValue)
		}
	}

	log.Println("[DEBUG] HandleSensorUpdate completed")
}

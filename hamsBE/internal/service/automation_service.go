package service

import (
	"context"
	"errors"
	"fmt"
	"hamstercare/internal/model"
	"hamstercare/internal/repository"
	"log"
	"sync"
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



// Biến global lưu lần cuối đã gửi warning
var lastWarningTimes = make(map[string]time.Time)
var warningMutex sync.Mutex

func evaluateCondition(condition string, value, threshold float64) bool {
	switch condition {
	case ">":
		return value > threshold
	case "<":
		return value < threshold
	case "=":
		return value == threshold
	default:
		log.Printf("[WARN] Unknown condition: %s", condition)
		return false
	}
}

func getReverseAction(action string) string {
	switch action {
	case "turn_on":
		return "turn_off"
	case "turn_off":
		return "turn_on"
	case "re_fill":
		return "" 
	default:
		log.Printf("[WARN] Unknown action: %s", action)
		return ""
	}
}

func formatActionText(action string) string {
	switch action {
	case "turn_on":
		return "turn on"
	case "turn_off":
		return "turn off"
	case "re_fill":
		return "refill"
	default:
		return action
	}
}


func handleAutomationAction(ctx context.Context, automationService *AutomationService, notiService *NotiService, rule *model.AutoRuleResBySensorID, action string) {
	deviceStatus, err := automationService.AutomationRepo.GetDeviceStatusByID(ctx, rule.ID)
	if err != nil {
		log.Printf("[ERROR] Failed to get device status: %v", err)
		return
	}

	desiredStatus := map[string]string{
		"turn_on": "on",
		"turn_off": "off",
		"re_fill": "on",
	}[action]

	if deviceStatus == desiredStatus {
		log.Printf("[DEBUG] Device already in desired state for sensorID %s", rule.SensorID)
		return
	}

	var actionValue int
	switch action {
	case "turn_on", "re_fill":
		actionValue = 1
	case "turn_off":
		actionValue = 0
	default:
		log.Printf("[WARN] Unknown action: %s", action)
		return
	}

	// Thực hiện action
	if err := HandleDeviceAction(rule.CageID, rule.UserID, rule.SensorID, rule.DeviceType, actionValue); err != nil {
		log.Printf("[ERROR] Failed to handle device action: %v", err)
		return
	}

	newStatus := desiredStatus

	// Note: Tạm thời command do chưa kết nối thiết bị để thiết bị tự cập nhật status trong database

	// // Kiểm tra kết quả action
	// newStatus, err := automationService.AutomationRepo.GetDeviceStatusByID(ctx, rule.ID)
	// if err != nil {
	// 	log.Printf("[ERROR] Failed to get updated device status: %v", err)
	// 	return
	// }

	// Lấy device name
	deviceName, err := automationService.AutomationRepo.GetDeviceNameByID(ctx, rule.ID)
	if err != nil {
		log.Printf("[ERROR] Failed to get device name: %v", err)
		deviceName = "Unknown Device"
	}

	// Gửi notification
	var title, notifType, message string
	if newStatus == desiredStatus {
		title = fmt.Sprintf("Device %s: %s successful", deviceName, formatActionText(action))
		notifType = "info"
		message = fmt.Sprintf("The device %s has been successfully %s.", deviceName, formatActionText(action))
	} else {
		title = fmt.Sprintf("Device %s: Failed to %s", deviceName, formatActionText(action))
		notifType = "error"
		message = fmt.Sprintf("The device %s failed to %s.", deviceName, formatActionText(action))
	}

	if err := notiService.SendNotificationToUser(ctx, rule.UserID, rule.CageID, title, notifType, message); err != nil {
		log.Printf("[ERROR] Failed to send notification: %v", err)
	}

	// Tính năng sẽ được update sau, tạm thời cho 5s 1 lần refill

	// "re_fill" thì tự động off sau 5s	
	if action == "re_fill" {
		go func() {
			time.Sleep(5 * time.Second)
			if err := HandleDeviceAction(rule.CageID, rule.UserID, rule.SensorID, rule.DeviceType, 0); err != nil {
				log.Printf("[ERROR] Failed to auto-stop device: %v", err)
			}
		}()
	}
}



func HandleSensorUpdate(ctx context.Context, payload map[string]interface{}, automationService *AutomationService, notiService *NotiService) {
	log.Println("[DEBUG] HandleSensorUpdate called with payload:", payload)

	// Parse sensorID và value
	sensorID, _ := payload["sensor_id"].(string)
	value, _ := payload["value"].(float64)
	sensorType, _ := payload["type"].(string)
	log.Printf("[DEBUG] Parsed sensorID: %s, value: %f, type: %s", sensorID, value, sensorType)

	now := time.Now()
	key := sensorID + "_" + sensorType

	// 1. Gửi cảnh báo sensor nếu sensor có value vượt ngưỡng
	warningMutex.Lock()
	lastSent, exists := lastWarningTimes[key]
	if !exists || now.Sub(lastSent) >= 20*time.Minute {
		log.Printf("[DEBUG] Sending warning notification for sensorID %s", sensorID)
		if err := notiService.SendNotiToUserWithSensorID(ctx, sensorID, sensorType, value); err != nil {
			log.Printf("[ERROR] Failed to send notification for sensorID %s: %v", sensorID, err)
		}
		lastWarningTimes[key] = now
	} else {
		log.Printf("[DEBUG] Skipping warning for sensorID %s, only %v minutes passed", sensorID, now.Sub(lastSent).Minutes())
	}
	warningMutex.Unlock()

	// 2. Xử lý automation rule
	rules, err := automationService.GetRulesBySensorID(ctx, sensorID)
	if err != nil {
		log.Printf("[ERROR] Failed to get automation rules for sensorID %s: %v", sensorID, err)
		return
	}
	log.Printf("[DEBUG] Found %d automation rules for sensorID %s", len(rules), sensorID)

	for _, rule := range rules {
		log.Printf("[DEBUG] Processing rule: %+v", rule)

		match := evaluateCondition(rule.Condition, value, rule.Threshold)
		action := rule.Action

		if match {
			handleAutomationAction(ctx, automationService, notiService, rule, action)
		} else {
			// Nếu không match điều kiện, thực hiện reverse
			reverseAction := getReverseAction(action)
			if reverseAction != "" {
				handleAutomationAction(ctx, automationService, notiService, rule, reverseAction)
			}
		}
	}
	log.Println("[DEBUG] HandleSensorUpdate completed")
}



// func HandleSensorUpdate(payload map[string]interface{}, automationService *AutomationService, notiService *NotiService) {
// 	log.Println("[DEBUG] HandleSensorUpdate called with payload:", payload)

// 	// Parse sensorID và value
// 	sensorID, _ := payload["sensor_id"].(string)
// 	value, _ := payload["value"].(float64)
// 	sensorType, _ := payload["type"].(string)
// 	log.Printf("[DEBUG] Parsed sensorID: %s, value: %f, type: %s", sensorID, value, sensorType)

// 	// Lấy userID, type: warning, 

// 	notiService.SendNotiToUserWithSensorID(context.Background(), sensorID, sensorType, value)

// 	// Lấy các automation rule của device có mode auto theo sensorID
// 	rules, err := automationService.GetRulesBySensorID(context.Background(), sensorID)
// 	if err != nil {
// 		log.Printf("[ERROR] Failed to get automation rules for sensorID %s: %v", sensorID, err)
// 		return
// 	}

// 	log.Printf("[DEBUG] Found %d automation rules for sensorID %s", len(rules), sensorID)

// 	// Duyệt từng rule
// 	for _, rule := range rules {
// 		log.Printf("[DEBUG] Processing rule: %+v", rule)

// 		condition := rule.Condition
// 		threshold := rule.Threshold
// 		action := rule.Action

// 		log.Printf("[DEBUG] Rule details - Condition: %s, Threshold: %f, Action: %s", condition, threshold, action)

// 		// Kiểm tra điều kiện
// 		var match bool
// 		switch condition {
// 		case ">":
// 			match = value > threshold
// 		case "<":
// 			match = value < threshold
// 		case "=":
// 			match = value == threshold
// 		default:
// 			log.Printf("[WARN] Unknown condition '%s' in rule", condition)
// 		}

// 		log.Printf("[DEBUG] Condition %s evaluated for sensorID %s: match=%v", condition, sensorID, match)

// 		if match {
// 			// Điều kiện đúng, thực hiện action
// 			var actionValue int
// 			switch action {
// 			case "turn_on":
// 				actionValue = 1
// 				log.Printf("[DEBUG] Condition matched: turning ON device for sensorID %s", sensorID)
// 			case "turn_off":
// 				actionValue = 0
// 				log.Printf("[DEBUG] Condition matched: turning OFF device for sensorID %s", sensorID)
// 			case "re_fill":
// 				actionValue = 1
// 				log.Printf("[DEBUG] Condition matched: starting refill for sensorID %s", sensorID)

// 				// Bật thiết bị
// 				HandleDeviceAction(rule.CageID, rule.UserID, rule.SensorID, rule.DeviceType, actionValue)

// 				// Tự động tắt sau 5 giây // tạm thời update sau
// 				go func() {
// 					time.Sleep(5 * time.Second)
// 					HandleDeviceAction(rule.CageID, rule.UserID, rule.SensorID, rule.DeviceType, 0)
// 					log.Printf("[DEBUG] Device auto-turned off after 5s for sensorID %s", rule.SensorID)
// 				}()
// 				continue // Với "re_fill" thì skip bước gọi HandleDeviceAction thêm lần nữa bên dưới
// 			default:
// 				log.Printf("[WARN] Unknown action '%s' in rule", action)
// 			}

// 			HandleDeviceAction(rule.CageID, rule.UserID, rule.SensorID, rule.DeviceType, actionValue)
// 		} else {
// 			// Điều kiện sai, thực hiện reverse action
// 			// Lấy status của device từ db 
// 			var reverseActionValue int
// 			switch action {
// 			case "turn_on":
// 				reverseActionValue = 0
// 				// Kiểm tra status có đang off
// 				// Không thì gọi tắt
// 				// Có thi bỏ qua
// 				log.Printf("[DEBUG] Condition not matched: turning OFF device for sensorID %s", sensorID)
// 			case "turn_off":
// 				reverseActionValue = 1
// 				// Kiểm tra status có đang onl
// 				// Không thì gọi tắt
// 				// Có thi bỏ qua
// 				log.Printf("[DEBUG] Condition not matched: turning ON device for sensorID %s", sensorID)
// 			case "re_fill":
// 				log.Printf("[DEBUG] Condition not matched: stopping refill for sensorID %s", sensorID)
// 				continue
// 			default:
// 				log.Printf("[WARN] Unknown action '%s' for reverse in rule", action)
// 			}

// 			HandleDeviceAction(rule.CageID, rule.UserID, rule.SensorID, rule.DeviceType, reverseActionValue)
// 		}
// 	}

// 	log.Println("[DEBUG] HandleSensorUpdate completed")
// }

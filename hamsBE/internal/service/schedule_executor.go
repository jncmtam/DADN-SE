package service

import (
	"fmt"
	"hamstercare/internal/mqtt"
	"log"
)

func HandleDeviceAction(userID, cageID, deviceID, deviceType string, action int) error {
	log.Printf("[INFO] Handling %s device action %d ", deviceID, action)
	var broker ="10.28.129.171:1883"
	switch deviceType {
	case "fan":
		if err := mqtt.StartMQTTClientPub(broker, "hamster/user1/cage1/device/6/fan", action, "device", 6, "fan"); err != nil {
			return fmt.Errorf("error handling fan device action: %v", err)
		}
	case "light":
		if err := mqtt.StartMQTTClientPub(broker, "hamster/user1/cage1/device/7/led", action, "device", 7, "led"); err != nil {
			return fmt.Errorf("error handling led device action: %v", err)
		}
	case "pump":
		if err := mqtt.StartMQTTClientPub(broker, "hamster/user1/cage1/device/8/pump", action, "device", 8, "pump"); err != nil {
			return fmt.Errorf("error handling pump device action: %v", err)
		}
	default:
		return fmt.Errorf("unknown device type: %s", deviceType)
	}
	return nil
}



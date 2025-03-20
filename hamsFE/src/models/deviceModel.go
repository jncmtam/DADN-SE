package models

import (
	"hamstercare/config"
)

type Device struct {
	ID     uint   `json:"id"`
	Name   string `json:"name"`
	Status string `json:"status"`
}

func GetAllDevices() []Device {
	var devices []Device
	config.DB.Find(&devices)
	return devices
}

func CreateDevice(device *Device) {
	config.DB.Create(device)
}

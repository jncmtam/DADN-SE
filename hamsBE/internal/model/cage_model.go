package model

import "time"

type Cage struct {
	ID              string    	`json:"id"`
	Name 			string		`json:"name"`
	UserID        	string    	`json:"user_id"`
	Status			string		`json:"status"`
	CreatedAt       time.Time 	`json:"created_at"`
	UpdatedAt       time.Time 	`json:"updated_at"`
}

type CageResponse struct {
	ID        string `json:"id"`
	Name      string `json:"name"`
	NumDevice int    `json:"num_device"`
	Status    string `json:"status"`
}


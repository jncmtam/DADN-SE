package model

import "time"

type Sensor struct{
	ID 			string 		`json:"id"`
	Name 		string 		`json:"name"`
	Type 		string 		`json:"type"`
	Value 		float64 	`json:"value"`
	Unit 		string 		`json:"unit"`
	CageID 		bool 		`json:"cage_id"`
	CreatedAt 	time.Time 	`json:"created_at"`
}

type SensorResponse struct{
	ID 			string 		`json:"id"`
	Type 		string 		`json:"type"`
	Unit 		string 		`json:"unit"`
}

type SensorListResponse struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}
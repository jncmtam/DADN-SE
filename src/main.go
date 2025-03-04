package main

import (
	"fmt"
	"hamstercare/config"
	"hamstercare/routes"
	"os"
	"github.com/gin-contrib/cors"
)

func main() {
	config.ConnectDB()
	// config.ConnectMQTT()

	r := routes.InitRoutes()

	// Cấu hình CORS
	config := cors.DefaultConfig()
	config.AllowAllOrigins = true
	config.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}
	config.AllowHeaders = []string{"Origin", "Content-Type", "Authorization"}
	r.Use(cors.New(config))

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080" // default port nếu không có env
	}
	fmt.Printf("Server is running on Port : %s\n", port)
	r.Run(":" + port)
}
// # Database config
// DB_USER=hamster
// DB_PASSWORD=hamster
// DB_NAME=iotdb
// DB_HOST=localhost
// DB_PORT=5432
// # 

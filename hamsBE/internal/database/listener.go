package database

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"os"

	"github.com/jackc/pgx/v4"

	"hamstercare/internal/repository"
	"hamstercare/internal/service"
)

func StartSensorListener(db *sql.DB) {
    dbUser := os.Getenv("DB_USER")
    dbPassword := os.Getenv("DB_PASSWORD")
    dbHost := os.Getenv("DB_HOST")
    dbPort := os.Getenv("DB_PORT")
    dbName := os.Getenv("DB_NAME")

    if dbUser == "" || dbPassword == "" || dbHost == "" || dbPort == "" || dbName == "" {
        log.Fatal("Database environment variables are not set properly")
    }

    dbURL := fmt.Sprintf("postgres://%s:%s@%s:%s/%s", dbUser, dbPassword, dbHost, dbPort, dbName)

    conn, err := pgx.Connect(context.Background(), dbURL)
    if err != nil {
        log.Fatalf("Failed to connect for LISTEN: %v", err)
    }

    _, err = conn.Exec(context.Background(), "LISTEN sensor_updates")
    if err != nil {
        log.Fatalf("Failed to LISTEN: %v", err)
    }

    log.Println("[INFO] Listening for sensor updates...")

    automationRepo := repository.NewAutomationRepository(db)
    automationService := service.NewAutomationService(automationRepo)

    userRepo := repository.NewUserRepository(db)
    cageRepo := repository.NewCageRepository(db)
    notiRepo := repository.NewNotificationRepository(db)
    notiService := service.NewNotiService(cageRepo, userRepo, notiRepo)

    go func() {
        for {
            ctx := context.Background() // mỗi lần loop có thể tạo ctx mới nếu muốn timeout control

            notification, err := conn.WaitForNotification(ctx)
            if err != nil {
                log.Println("[ERROR] WaitForNotification:", err)
                continue
            }

            var payload map[string]interface{}
            if err := json.Unmarshal([]byte(notification.Payload), &payload); err != nil {
                log.Println("[ERROR] Invalid payload:", err)
                continue
            }

            service.HandleSensorUpdate(ctx, payload, automationService, notiService)
        }
    }()
}



// func StartSensorListener(db *sql.DB) {
//     dbUser := os.Getenv("DB_USER")
//     dbPassword := os.Getenv("DB_PASSWORD")
//     dbHost := os.Getenv("DB_HOST")
//     dbPort := os.Getenv("DB_PORT")
//     dbName := os.Getenv("DB_NAME")

//     if dbUser == "" || dbPassword == "" || dbHost == "" || dbPort == "" || dbName == "" {
//         log.Fatal("Database environment variables are not set properly")
//     }

//     dbURL := fmt.Sprintf("postgres://%s:%s@%s:%s/%s", dbUser, dbPassword, dbHost, dbPort, dbName)

//     conn, err := pgx.Connect(context.Background(), dbURL)
//     if err != nil {
//         log.Fatalf("Failed to connect for LISTEN: %v", err)
//     }

//     _, err = conn.Exec(context.Background(), "LISTEN sensor_updates")
//     if err != nil {
//         log.Fatalf("Failed to LISTEN: %v", err)
//     }

//     log.Println("[INFO] Listening for sensor updates...")

//     go func() {
//         for {
//             notification, err := conn.WaitForNotification(context.Background())
//             if err != nil {
//                 log.Println("[ERROR] WaitForNotification:", err)
//                 continue
//             }

//             var payload map[string]interface{}
//             if err := json.Unmarshal([]byte(notification.Payload), &payload); err != nil {
//                 log.Println("[ERROR] Invalid payload:", err)
//                 continue
//             }

// 			automationRepo := repository.NewAutomationRepository(db)
// 			automationService := service.NewAutomationService(automationRepo)

//             userRepo := repository.NewUserRepository(db)
//             cageRepo := repository.NewCageRepository(db)
//             notiRepo := repository.NewNotificationRepository(db)
//             notiService := service.NewNotiService(cageRepo, userRepo, notiRepo)
            
            

//             // Gọi hàm automation xử lý
//             service.HandleSensorUpdate(payload, automationService, notiService)
//         }
//     }()
// }

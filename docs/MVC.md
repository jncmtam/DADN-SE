```bash
project-iot/
├─ main.go       # Entry Point
├─ config/       # Kết nối DB, MQTT, .env
│  ├─ database.go
│  └─ mqtt.go
├─ models/       # Định nghĩa Struct + DB Query
│  ├─ device.go
│  └─ user.go
├─ controllers/  # Xử lý Request
│  ├─ auth.go
│  └─ device.go
└─ routes/       # Khai báo API
   └─ api.go
```bash
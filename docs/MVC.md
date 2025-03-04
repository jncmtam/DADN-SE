```bash
hamstercare/
├── config                     # Cấu hình hệ thống
│     ├── database.go          # Kết nối cơ sở dữ liệu MongoDB
│     ├── mqtt.go              # Cấu hình MQTT Broker
│     └── env.go               # Load các biến môi trường từ file .env
├── controllers                # Xử lý logic nghiệp vụ
│     ├── authController.go    # Xử lý Đăng ký, Đăng nhập, Hồ sơ cá nhân
│     ├── deviceController.go  # Quản lý thiết bị (Tạo, Cập nhật, Xóa)
│     ├── cageController.go    # Quản lý lồng
│     └── notiController.go    # Quản lý thông báo
├── models                     # Định nghĩa các struct cho dữ liệu
│     ├── userModel.go         # Model Người dùng
│     ├── deviceModel.go       # Model Thiết bị
│     ├── cageModel.go         # Model Lồng
│     └── notiModel.go         # Model Thông báo
├── routes                     # Định nghĩa các route API
│     ├── authRoute.go         # Route Đăng nhập, Đăng ký
│     ├── deviceRoute.go       # Route quản lý thiết bị
│     ├── cageRoute.go         # Route quản lý lồng
│     └── notificationRoute.go # Route thông báo
├── utils                      # Các hàm tiện ích
│     ├── hash.go              # Hash và Kiểm tra mật khẩu
│     └── jwt.go               # Tạo và Xác thực JWT
├── middlewares                # Xử lý trung gian
│     ├── authentication.go    # Xác thực JWT
│     └── validation.go        # Kiểm tra dữ liệu đầu vào
└── main.go                    # Khởi động server và ánh xạ các route
```

### ERD

| Entity     | Liên Quan Tới        | Loại Quan Hệ |
| ---------- | -------------------- | ------------ |
| **User**   | **Cage**             | 1:N          |
| **Cage**   | **Device**           | 1:N          |
| **Device** | **Logs**             | 1:N          |
| **Device** | **Automation Rules** | 1:N          |
| **User**   | **Notification**     | 1:N          |
| **User**   | **Settings**         | 1:1          |

# REST API Design

## 1. Xác thực & Người dùng

### **Admin**
- `POST /admin/login` → Đăng nhập admin  
  **Request:**  
  ```json
  {
    "email": "admin@example.com",
    "password": "password123"
  }
  ```
  **Response:**  
  ```json
  {
    "token": "jwt-token",
    "role": "admin"
  }
  ```

- `GET /admin/users` → Xem danh sách người dùng  
  **Response:**  
  ```json
  [
    {
      "id": 1,
      "name": "User A",
      "email": "usera@example.com",
      "role": "user"
    }
  ]
  ```

- `POST /admin/users` → Tạo người dùng mới  
  **Request:**  
  ```json
  {
    "name": "User B",
    "email": "userb@example.com",
    "role": "user"
  }
  ```
  **Response:**  
  ```json
  {
    "id": 2,
    "name": "User B",
    "email": "userb@example.com",
    "role": "user"
  }
  ```

- `DELETE /admin/users/:id` → Xóa người dùng  
  **Response:**  
  ```json
  {
    "message": "User deleted successfully"
  }
  ```

### **User**
- `POST /user/login` → Đăng nhập bằng số điện thoại hoặc email  
  **Request:**  
  ```json
  {
    "identifier": "user@example.com" 
  }
  ```
  **Response:**  
  ```json
  {
    "message": "OTP sent to email or phone"
  }
  ```

- `POST /user/verify-otp` → Xác thực OTP  
  **Request:**  
  ```json
  {
    "identifier": "user@example.com",
    "otp": "123456"
  }
  ```
  **Response:**  
  ```json
  {
    "token": "jwt-token",
    "role": "user"
  }
  ```

## 2. Quản lý Chuồng (Cages)

### **User**
- `GET /api/cages` → Xem danh sách chuồng  
  **Response:**  
  ```json
  [
    {
      "id": 1,
      "name": "Chuồng A"
    },
    {
      "id": 2,
      "name": "Chuồng B"
    }
  ]
  ```

- `GET /api/cages/:id` → Xem chi tiết chuồng, bao gồm cảm biến và thiết bị  
  **Response:**  
  ```json
  {
    "id": 1,
    "name": "Chuồng A",
    "sensors": [
      {
        "id": 1,
        "type": "temperature",
        "value": 28.5,
        "unit": "°C"
      },
      {
        "id": 2,
        "type": "humidity",
        "value": 70,
        "unit": "%"
      }
    ],
    "devices": [
      {
        "id": 1,
        "name": "Quạt",
        "status": "on"
      },
      {
        "id": 2,
        "name": "Đèn LED",
        "status": "off"
      }
    ]
  }
  ```

- `POST /api/cages` → Tạo chuồng mới  
  **Request:**  
  ```json
  {
    "name": "Chuồng B"
  }
  ```
  **Response:**  
  ```json
  {
    "id": 2,
    "name": "Chuồng B"
  }
  ```

## 3. Quản lý Cảm biến (Sensors)

### **User**
- `MQTT topic` : username/feeds/sensor# → Lấy dữ liệu từ cảm biến trực tiếp qua MQTT và chỉ lưu lại vào database những sự kiện vi phạm Automation Rule  
  **Response:**  
  ```json
  {
    "sensor_id": 1,
    "type": "temperature",
    "value": 28.5,
    "unit": "°C",
    "timestamp": "2024-03-09T12:00:00Z"
  }
  ```

## 4. Quản lý Thiết bị (Devices)

### **User**
- `PUT /api/devices/:id` → Cập nhật trạng thái thiết bị (bật/tắt/auto)  
  **Request:**  
  ```json
  {
    "status": "on"
  }
  ```
  **Response:**  
  ```json
  {
    "id": 1,
    "name": "Quạt",
    "status": "on"
  }
  ```

## 5. Quy tắc Tự động (Automation Rules)

### **User**
- `POST /api/automation` → Tạo quy tắc tự động mới  
  **Request:**  
  ```json
  {
    "sensor_id": 1,
    "device_id": 2,
    "condition": ">",
    "threshold": 30,
    "action": "turn_on"
  }
  ```
  **Response:**  
  ```json
  {
    "id": 1,
    "sensor_id": 1,
    "device_id": 2,
    "condition": ">",
    "threshold": 30,
    "action": "turn_on"
  }
  ```
## 6. Thông báo (Notifications)

### **User**
- `POST /api/notifications/register` → Đăng ký token FCM của thiết bị  
  **Request:**  
  ```json
  {
    "device_id": "user-device-123",
    "fcm_token": "fcm-token-string"
  }
  ```
  **Response:**  
  ```json
  {
    "message": "Device registered successfully"
  }
  ```

- `POST /api/notifications/send` → Gửi thông báo đến thiết bị qua FCM  
  **Request:**  
  ```json
  {
    "device_id": "user-device-123",
    "title": "Cảnh báo nhiệt độ",
    "message": "Nhiệt độ vượt quá 30°C"
  }
  ```
  **Response:**  
  ```json
  {
    "message": "Notification sent successfully"
  }
  ```
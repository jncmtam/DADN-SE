# REST API Design

## 1. Xác thực & Người dùng
- `POST : admin/login`
- `POST : admin/logout`

- ` Get : admin/`
- ` Get, Delete : admin/users`
- ` Get, Delete : admin/users/:user_id`
- `Get : admin/users/cages & admin/user/cages/:cage_id`

- `Post : api/login`
- `Post : api/logout`
- `Post : api/register`
- `Post : api/changePW` -> token
- `Post : api/forgetPW` -> OTP email

## 2. Quản lý Chuồng (Cages)
- Inactive / Active  -> Giữ nguyên trạng thái trước lúc tắt của device & sensor

### **User**
- `GET /api/cages` → Xem danh sách chuồng 
- `Bearer Token`

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

- `GET /api/cages/:cage_id` → Xem chi tiết chuồng, bao gồm cảm biến và thiết bị  
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
## Admin
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
- `PUT /api/devices/:device_id` → Cập nhật trạng thái thiết bị (bật/tắt/auto)  
  **Request:**  
  ```json
  {
    "status": "on" // off , auto
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
    "unit" : "C",
    "action": "turn_on"
  }
  ```
  **Response:**  
  ```json
  {
    "automation_id" : "xxxx-000012012-123123", //hash
    "sensor_id": 1,
    "device_id": 2,
    "condition": ">",
    "threshold": 30,
    "unit" : "C",
    "action": "turn_on"
  }
  ```
- `Get api/automation/automation_id` -> Display data onto dashboard

## 6. Thông báo (Notifications)
- Alert : 
  - Inactive/active - cage - device - sensor

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

  - Control sao cho noti gửi liên tục sau ${time} 
  - Quá nhiệt -> Thông báo sau ~ 15 phút
  - Nếu hết water/food -> Luôn mở van -> Thông báo sau ~ 2 tiếng

  **Request:**  
```json
[ 
  {
    "device_id": "user-device-123",
    "title": "Hết đồ ăn",
    "message": "Thùng đựng hết đồ ăn",
    "timestamp" : "9/3/2025 11PM"
  },
  {
    "device_id": "user-device-456",
    "title": "Quá nhiệt",
    "message": "Nhiệt độ vượt quá 35 độ C",
    "timestamp" : "9/3/2025 11PM"
  }
  ]
```
  **Response:**  
  ```json
  {
    "message": "Notification sent successfully"
  }
  ```

### 7. Thống kê
 - `Get api/:cage_id/stat/{type=food?water}?startDate={}&endDate{}` 
 #### res 
 ```json
 {
   "food_refill_SL" : int,
   "water_refill_SL" : int,
 }
 ```

while measureing -> hamster consume water / food 
-> show cho thầy



# Stat Method
refill_sum = 50 mil * refill_time -> dashboard display
refill_cal_food() , refill_cal_water()

  RefillDB (day) 
  - cage_id 
  - food_refill_SL : int -> 0
  - water_refill_SL : int -> 0
  - timestamp : 23/2/2025 


  # Note : 
- Admin đăng kí tk user
- Forget password -> OTP GMail
- Login -> Change password 



- Admin 
  - User
    - Cage
      - Device & Sensor

- cage 1
   - energy -> tổng tgian hoạt động của từng device *  mức tiêu thụ điện
   - water stat
   - food stat

- cage 2
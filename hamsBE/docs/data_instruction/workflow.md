# HamsterCare API Documentation

Base URL: `{{base_url}}` (e.g. `http://localhost:8080/api`)

## Authentication
All endpoints (except `GET /` and WebSocket) require a header:
```
Authorization: Bearer <token>
```

## Endpoints

### 1. Devices
- **GET /devices/{deviceID}**
  - Lấy thông tin chi tiết thiết bị cùng các rule tự động và lịch trình.
  - **Params**: `deviceID` (UUID)
  - **Response**: 
    ```json
    {
      "id": "...",
      "name": "...",
      "status": "...",
      "action_type": "...",
      "automation_rule": [...],
      "schedule_rule": [...]
    }
    ```

- **POST /devices/{deviceID}/control**
  - Điều khiển thiết bị thủ công.
  - **Body**:
    ```json
    {
      "action": "turn_on" | "turn_off" | "refill" | "lock"
    }
    ```
  - **Response**:
    ```json
    { "message": "Device action executed successfully" }
    ```

### 2. Sensors
- **GET /cages/{cageID}/sensors**
  - Lấy danh sách sensor trong chuồng.
  - **Response**:
    ```json
    { "sensors": [...] }
    ```

- **GET /cages/{cageID}/sensors-data**
  - Lấy dữ liệu sensor mới nhất (4 bản ghi).
  - **Response**:
    ```json
    {
      "temperature": { "value": 24.5, "unit": "°C", "timestamp": "2025-04-24T..." },
      ...
    }
    ```

### 3. Rule Configuration
- **POST /devices/{deviceID}/automations**
  - Tạo automation rule.
  - **Body**:
    ```json
    {
      "sensor_id": "{sensorID}",
      "condition": "<" | ">" | "=",
      "threshold": 30.0,
      "action": "turn_on" | "turn_off" | "refill" | "lock"
    }
    ```
  - **Response**:
    ```json
    { "message": "Automation rule created successfully", "id": "..." }
    ```

- **DELETE /automations/{ruleID}**
  - Xóa automation rule.
  - **Response**:
    ```json
    { "message": "Automation rule deleted successfully" }
    ```

- **POST /devices/{deviceID}/schedules**
  - Tạo schedule rule.
  - **Body**:
    ```json
    {
      "execution_time": "HH:MM",
      "days": ["mon","tue",...],
      "action": "turn_on" | "turn_off" | "refill" | "lock"
    }
    ```
  - **Response**:
    ```json
    { "message": "Schedule rule created successfully", "id": "..." }
    ```

- **DELETE /schedules/{ruleID}**
  - Xóa schedule rule.
  - **Response**:
    ```json
    { "message": "Schedule rule deleted successfully" }
    ```

### 4. Statistics
- **GET /cages/{cageID}/statistics?range=daily|weekly|monthly&start_date=YYYY-MM-DD&end_date=YYYY-MM-DD**
  - Lấy thống kê nước refill.
  - **Response**:
    ```json
    {
      "statistics": [{ "date": "2025-04-20", "water_refill_sl": 5 }, ...],
      "summary": { "total_refills": 20, "average_per_day": 2.5 }
    }
    ```

- **GET /cages/general-info**
  - Lấy số thiết bị active.
  - **Response**:
    ```json
    { "active_devices": 3 }
    ```

### 5. Notifications
- **GET /notifications**
  - Lấy thông báo chưa đọc.
  - **Response**:
    ```json
    { "notifications": [ ... ] }
    ```

- **PUT /notifications/{notificationID}/read**
  - Đánh dấu thông báo đã đọc.
  - **Response**:
    ```json
    { "message": "Notification marked as read" }
    ```

### 6. Real-time via WebSocket
- **Connect** to:
  ```
  ws://localhost:8080/api/cages/{cageID}/sensors-data/ws
  ```
- **Functionality**:
  - Đẩy dữ liệu sensor mới, thống kê và notification real-time.

## Code Testing (sensor_data.sh)
```bash
# Cấu hình USER_ID, CAGE_ID
export USER_ID="1111..."
export CAGE_ID="3333..."

# Chạy script
bash sensor_data.sh
```

- Script sẽ publish MQTT messages, backend tự động lưu DB, check rule, gửi WebSocket & notification.

---


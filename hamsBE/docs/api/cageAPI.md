
# API Documentation (for Cage)

## I. Admin Routes

### 1. Create A Cage 
- **Method**: `POST`
- **URL**: `/admin/users/:id/cages`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Parameters**:
    - id (string, required): ID user muốn tạo chuồng
- **Request Body**:
  ```json
  {
    "name_cage": "Cage 1",
  }
  ```
  
- **Response**:
  - `201 Created`: Cage created successfully
    ```json
    {
        "id": "2a4666c4-df8f-41cf-b59f-3ca72c16019c",
        "message": "Cage created successfully",
        "name": "Cage 1"
    }
    ```
  - `400 Bad Request`: Invalid request body
    ```json
    {
      "error": "Invalid request body"
    }
    ```
  - `401 Unauthorized`: Invalid token (miss token, expired, invalid)
    ```json
    {
      "error": "Invalid or expired token"
    }
    ```
  - `403 Forbidden`: Permission denied
    ```json
    {
        "error": "Permission denied"
    }
    ```
  - `404 Not Found`: User not found 
    ```json
    {
        "error": "User not found"
    }
    ``` 
  - `500 Internal Server Error`:
    ```json
    {
      "error": "Internal Server Error"
    }
    ```


### 2. Delete A Cage 
- **Method**: `DELETE`
- **URL**: `/admin/cages/:cageID`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Parameters**:
    - cageID (string, required): ID của chuồng cần xóa.

- **Response**:
  - `200 OK`: 
    ```json
    {
        "message": "Cage deleted successfully"
    }
    ```
  - `401 Unauthorized`: Invalid token (miss token, expired, invalid)
    ```json
    {
      "error": "Invalid or expired token"
    }
    ```
  - `403 Forbidden`: 
    ```json
    {
        "error": "Permission denied"
    }
    ```
  - `404 Not Found`: CageID not found 
    ```json
    {
        "error": "Cage not found"
    }
    ``` 
  - `500 Internal Server Error`:
    ```json
    {
      "error": "Internal Server Error"
    }
    ```

### 3. Add A Device To A Cage 
- **Method**: `POST`
- **URL**: `/admin/cages/:cageID/devices`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Parameters**:
    - cageID (string, required): ID của chuồng muốn thêm thiết bị.
- **Request Body**:
  ```json
  {
    "name": "Device Name",
    "type": "display" // display lock light pump fan
  }
  ```
  
- **Response**:
  - `201 Created`: 
    ```json
    {
      "id": "6e60d331-8f97-4eef-a1bc-e467ac6ccb79",
      "message": "Device created successfully",
      "name": "Fan 2"
    }
    ```
  - `400 Bad Request`: Invalid request body
    ```json
    {
      "error": "Invalid request body"
    }
    ```
  - `401 Unauthorized`: Invalid token (miss token, expired, invalid)
    ```json
    {
      "error": "Invalid or expired token"
    }
    ```
  - `403 Forbidden`: Permission denied
    ```json
    {
        "error": "Permission denied"
    }
    ```
  - `404 Not Found`: cageID not found
    ```json
    {
        "error": "Cage not found"
    }
    ```
  - `500 Internal Server Error`:
    ```json
    {
      "error": "Internal Server Error"
    }
    ```

### 4. Delete A Device 
- **Method**: `DELETE`
- **URL**: `/admin/devices/:deviceID`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Parameters**:
    - deviceID (string, required): ID của thiét bị cần xóa.

- **Response**:
  - `200 OK`: 
    ```json
    {
        "message": "Device deleted successfully"
    }
    ```
  - `401 Unauthorized`: Invalid token (miss token, expired, invalid)
    ```json
    {
      "error": "Invalid or expired token"
    }
    ```
  - `403 Forbidden`: 
    ```json
    {
        "error": "Permission denied"
    }
    ```
  - `404 Not Found`: deviceID not found 
    ```json
    {
      "error": "Device not found"
    }
    ```
  - `500 Internal Server Error`:
    ```json
    {
      "error": "Internal Server Error"
    }
    ```

### 5. Add A Sensor To A Cage 
- **Method**: `POST`
- **URL**: `/admin/cages/:cageID/sensors`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Parameters**:
    - cageID (string, required): ID của chuồng muốn thêm thiết bị.
- **Request Body**:
  ```json
  {
    "name": "Sensor Name",
    "type": "temperature" // temperature humidity light distance
  }
  ```
  
- **Response**:
  - `201 Created`: 
    ```json
    {
        "id": "3268d027-9226-4114-bce4-cb141ea37528",
        "message": "Sensor created successfully",
        "name": "Nhiet do"
    }
    ```
  - `400 Bad Request`: Invalid request body
    ```json
    {
      "error": "Invalid request body"
    }
    ```
  - `401 Unauthorized`: Invalid token (miss token, expired, invalid)
    ```json
    {
      "error": "Invalid or expired token"
    }
    ```
  - `403 Forbidden`: Permission denied
    ```json
    {
        "error": "Permission denied"
    }
    ```
  - `404 Not Found`: cageID not found 
    ```json
    {
        "error": "Cage not found"
    }
    ```
  - `500 Internal Server Error`:
    ```json
    {
      "error": "Internal Server Error"
    }
    ```

### 6. Delete A Sensor 
- **Method**: `DELETE`
- **URL**: `/admin/sensors/:sensorID`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Parameters**:
    - sensorID (string, required): ID của cảm biến cần xóa.

- **Response**:
  - `200 OK`: 
    ```json
    {
        "message": "Sensor deleted successfully"
    }
    ```
  - `401 Unauthorized`: Invalid token (miss token, expired, invalid)
    ```json
    {
      "error": "Invalid or expired token"
    }
    ```
  - `403 Forbidden`: 
    ```json
    {
        "error": "Permission denied"
    }
    ```
  - `404 Not Found`: sensorID not found
    ```json
    {
        "error": "Sensor not found"
    }
    ```
  - `500 Internal Server Error`:
    ```json
    {
      "error": "Internal Server Error"
    }
    ```

### 7. Get Cages By User
- **Method**: `GET`
- **URL**: `/admin/users/:id/cages`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Parameters**:
    - id (string, required): ID của user cần xem.

- **Response**:
  - `200 OK`: 
    ```json
    [
      {
          "id": "2a4666c4-df8f-41cf-b59f-3ca72c16019c",
          "name": "Cage 1",
          "num_device": 1,
          "status": "off"
      }
    ]
    ```
  - `401 Unauthorized`: Invalid token (miss token, expired, invalid)
    ```json
    {
      "error": "Invalid or expired token"
    }
    ```
  - `403 Forbidden`: 
    ```json
    {
        "error": "Permission denied"
    }
    ```
  - `404 Not Found`: user not found
    ```json
    {
        "error": "User not found"
    }
    ```
  - `500 Internal Server Error`:
    ```json
    {
      "error": "Internal Server Error"
    }
    ```

### 8. Get Cage Details
- **Method**: `GET`
- **URL**: `/admin/cages/:cageID`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Parameters**:
    - cageID (string, required): ID của chuồng cần xem.

- **Response**:
  - `200 OK`: 
    ```json
    {
        "id": "2dab4c20-bf70-4d60-8d9f-d29dcb41cdc6",
        "name": "Cage 1",
        "devices": [
            {
                "id": "243ef9e1-5cde-4aa8-8b69-e4ff304c88eb",
                "name": "Fan 1",
                "status": "off" // on / auto
            }
        ],
        "sensors": [
            {
                "id": "5ca7747f-2e0d-4eb5-9b62-3d17e9a77c2b",
                "type": "temperature",
                "value": 0,
                "unit": "oC" 
            }
        ]
    }
    ```
  - `401 Unauthorized`: Invalid token (miss token, expired, invalid)
    ```json
    {
      "error": "Invalid or expired token"
    }
    ```
  - `403 Forbidden`: 
    ```json
    {
        "error": "Permission denied"
    }
    ```
  - `404 Not Found`: cageID not found
    ```json
    {
        "error": "Cage not found"
    }
    ```
  - `500 Internal Server Error`:
    ```json
    {
      "error": "Internal Server Error"
    }
    ```


## II. User Routes

### 1. Get Cages for Logged-in User
- **Method**: `GET`
- **URL**: `/user/cages`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Response**:
  - `200 OK`: 
    ```json
    [
      {
          "id": "2a4666c4-df8f-41cf-b59f-3ca72c16019c",
          "name": "Cage 1",
          "num_device": 1,
          "status": "off" // on
      }
    ]
    ```
  - `401 Unauthorized`: Invalid token (miss token, expired, invalid)
    ```json
    {
      "error": "Invalid or expired token"
    }
    ```
  - `403 Forbidden`: 
    ```json
    {
        "error": "Permission denied"
    }
    ```
  - `500 Internal Server Error`:
    ```json
    {
      "error": "Internal Server Error"
    }
    ```

### 2. Get Cage Details for Logged-in User
- **Method**: `GET`
- **URL**: `/user/cages/:cageID`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Parameters**:
    - cageID (string, required): ID của chuồng cần xem.

- **Response**:
  - `200 OK`: 
    ```json
    {
        "id": "2dab4c20-bf70-4d60-8d9f-d29dcb41cdc6",
        "name": "Cage 1",
        "devices": [
            {
                "id": "243ef9e1-5cde-4aa8-8b69-e4ff304c88eb",
                "name": "Fan 1",
                "status": "off" // on / auto
            }
        ],
        "sensors": [
            {
                "id": "5ca7747f-2e0d-4eb5-9b62-3d17e9a77c2b",
                "type": "temperature",
                "value": 0,
                "unit": "oC" 
            }
        ]
    }
    ```
  - `401 Unauthorized`: Invalid token (miss token, expired, invalid)
    ```json
    {
      "error": "Invalid or expired token"
    }
    ```
  - `403 Forbidden`: 
    ```json
    {
        "error": "Permission denied"
    }
    ```
  - `404 Not Found`: cageID not found
    ```json
    {
        "error": "Cage not found"
    }
    ```
  - `500 Internal Server Error`:
    ```json
    {
      "error": "Internal Server Error"
    }
    ```

### 3. Get Device Details for Logged-in User
- **Method**: `GET`
- **URL**: `/user/devices/:deviceID`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Parameters**:
    - deviceID (string, required): ID của thiết bị cần xem.

- **Response**:
  - `200 OK`: 
    ```json
    {
        "id": "243ef9e1-5cde-4aa8-8b69-e4ff304c88eb",
        "name": "Fan 1",
        "status": "off",
        "automation_rule": [
            {
                "id": "c0c5b77b-2ba9-4292-b2ba-bd9cec11c394",
                "sensor_id": "5ca7747f-2e0d-4eb5-9b62-3d17e9a77c2b", 
                "condition": ">",
                "threshold": 30,
                "unit": "oC",
                "action": "turn_on",
            }
        ],
        "schedule_rule": [
          {
              "id": "3d142e2a-8d48-4bc8-8ff1-eadf2a9211bf",
              "execution_time": "0000-01-01T17:17:00Z",
              "days": [
                  "Mon",
                  "Tue"
              ],
              "action": "turn_on"
          }
        ]
    }
    ```
  - `401 Unauthorized`: Invalid token (miss token, expired, invalid)
    ```json
    {
      "error": "Invalid or expired token"
    }
    ```
  - `403 Forbidden`: 
    ```json
    {
        "error": "Permission denied"
    }
    ```
  - `404 Not Found`: deviceID not found
    ```json
    {
        "error": "Device not found"
    }
    ```
  - `500 Internal Server Error`:
    ```json
    {
      "error": "Internal Server Error"
    }
    ```

### 4. Add Automation Rule for Device 
- **Method**: `POST`
- **URL**: `/user/devices/:deviceID/automations`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Parameters**:
    - deviceID (string, required): ID thiết bị muốn tạo automation rule.
- **Request Body**:
  ```json
    {
      "sensor_id": "5ca7747f-2e0d-4eb5-9b62-3d17e9a77c2b",
      "condition": "<",
      "threshold": 30,
      "unit": "°C",
      "action": "turn_on"
    }

  ```
  
- **Response**:
  - `201 Created`: 
    ```json
    {
      "message": "Automation rule created successfully",
      "id": "c0c5b77b-2ba9-4292-b2ba-bd9cec11c394"
    }
    ```
  - `400 Bad Request`: Invalid request body
    ```json
    {
      "error": "Invalid request body"
    }
    ```
  - `401 Unauthorized`: Invalid token (miss token, expired, invalid)
    ```json
    {
      "error": "Invalid or expired token"
    }
    ```
  - `403 Forbidden`: Permission denied
    ```json
    {
        "error": "Permission denied"
    }
    ```
  - `404 Not Found`: deviceID not found
     ```json
    {
        "error": "Device not found"
    }
    ```
  - `500 Internal Server Error`:
    ```json
    {
      "error": "Internal Server Error"
    }
    ```

### 5. Delete Automation Rule
- **Method**: `DELETE`
- **URL**: `/user/automations/:ruleID`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Parameters**:
    - ruleID (string, required): ID của lệnh automation cần xóa.

- **Response**:
  - `200 OK`: 
    ```json
    {
        "message": "Automation rule deleted successfully"
    }
    ```
  - `401 Unauthorized`: Invalid token (miss token, expired, invalid)
    ```json
    {
      "error": "Invalid or expired token"
    }
    ```
  - `403 Forbidden`: 
    ```json
    {
        "error": "Permission denied"
    }
    ```
  - `404 Not Found`: ruleID not found
    ```json
    {
        "error": "Automation rule not found"
    }
    ```
  - `500 Internal Server Error`:
    ```json
    {
      "error": "Internal Server Error"
    }
    ```

### 6. Add Schedule Rule for Device 
- **Method**: `POST`
- **URL**: `/user/devices/:deviceID/schedules`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Parameters**:
    - deviceID (string, required): ID thiết bị muốn tạo schedules rule.
- **Request Body**:
  ```json
    {
        "execution_time": "17:17"
        , "days": ["Mon", "Tue"]
        , "action": "turn_on"
    }
  ```
  
- **Response**:
  - `201 Created`: 
    ```json
    {
      "id": "8e12c57f-62bf-4706-9f4f-eb1e8db8f382",
      "message": "Schedule rule created successfully"
    }
    ```
  - `400 Bad Request`: Invalid request body
    ```json
    {
      "error": "Invalid request body"
    }
    ```
  - `401 Unauthorized`: Invalid token (miss token, expired, invalid)
    ```json
    {
      "error": "Invalid or expired token"
    }
    ```
  - `403 Forbidden`: Permission denied
    ```json
    {
        "error": "Permission denied"
    }
    ```
  - `404 Not Found`: deviceID not found
     ```json
    {
        "error": "Device not found"
    }
    ```
  - `500 Internal Server Error`:
    ```json
    {
      "error": "Internal Server Error"
    }
    ```

### 7. Delete Schedule Rule
- **Method**: `DELETE`
- **URL**: `/user/schedules/:ruleID`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Parameters**:
    - ruleID (string, required): ID của lệnh schedule cần xóa.

- **Response**:
  - `200 OK`: 
    ```json
    {
      "message": "Schedule rule deleted successfully"
    }
    ```
  - `401 Unauthorized`: Invalid token (miss token, expired, invalid)
    ```json
    {
      "error": "Invalid or expired token"
    }
    ```
  - `403 Forbidden`: 
    ```json
    {
        "error": "Permission denied"
    }
    ```
  - `404 Not Found`: ruleID not found
    ```json
    {
        "error": "Automation rule not found"
    }
    ```
  - `500 Internal Server Error`:
    ```json
    {
      "error": "Internal Server Error"
    }
    ```
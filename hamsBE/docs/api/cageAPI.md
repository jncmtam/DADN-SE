
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

### 3. Add A Device  
- **Method**: `POST`
- **URL**: `/admin/devices`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Request Body**:
  ```json
  {
    "name": "Device Name",
    "type": "display", // display lock light pump fan
    "cageID": "ff6ef8f2-0222-4b09-a52d-a8a3bec48a83" // có thể null
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

### 4. Assign A Device To A Cage 
 - **Method**: `PUT`
 - **URL**: `/admin/devices/:deviceID/cage`
 - **Headers**: 
   - `Authorization: Bearer <token>`
 - **Parameters**:
     - deviceID (string, required): The ID of the device you want to assign.
 - **Request Body**:
   ```json
   {
         "cageID": "ff6ef8f2-0222-4b09-a52d-a8a3bec48a83"
   }
   ```
 
 - **Response**:
   - `200 OK`: Device successfully assigned to the cage:
     ```json
      {
        "id": "6e60d331-8f97-4eef-a1bc-e467ac6ccb79",
        "message": "Device assigned to cage successfully",
        "cageID": "ff6ef8f2-0222-4b09-a52d-a8a3bec48a83"
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
   - `404 Not Found`: Either device or cage not found
      - Device not found
        ```json
        {
            "error": "Device not found"
        }
        ```
      - Cage not found
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


### 5. Remove A Device From Cage
- **Method**: `DELETE`
- **URL**: `/admin/devices/:deviceID`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Parameters**:
  - `deviceID` (string, required): ID của thiết bị cần xóa khỏi cage.

- **Description**:
  - Endpoint này sẽ **xóa thiết bị khỏi cage** hiện tại mà không xóa thiết bị khỏi hệ thống.
  - Thiết bị sẽ không còn liên kết với cage, nhưng vẫn còn tồn tại trong hệ thống.

- **Response**:
  - `200 OK`: 
    ```json
    {
        "message": "Device removed from cage successfully"
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


### 6. Add A Sensor  
- **Method**: `POST`  
- **URL**: `/admin/sensors`  
- **Headers**:  
  - `Authorization: Bearer <token>`  
- **Request Body**:  
  ```json
  {
    "name": "Sensor Name",
    "type": "temperature", // temperature humidity light water
    "cageID": "ff6ef8f2-0222-4b09-a52d-a8a3bec48a83" // có thể null
  }
  ```  

- **Response**:
  - `201 Created`:  
    ```json
    {
      "id": "9fc0d5f3-a1f0-43c4-bd0e-8e7fa09f95d2",
      "message": "Sensor created successfully",
      "name": "Temperature 1"
    }
    ```
  - `400 Bad Request`: Invalid request body  
    ```json
    {
      "error": "Invalid request body"
    }
    ```
  - `401 Unauthorized`: Invalid token (missing, expired, invalid)  
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


### 7. Assign A Sensor To A Cage  
- **Method**: `PUT`  
- **URL**: `/admin/sensors/:sensorID/cage`  
- **Headers**:  
  - `Authorization: Bearer <token>`  
- **Parameters**:
  - `sensorID` (string, required): ID của cảm biến cần gán vào chuồng.  
- **Request Body**:  
  ```json
  {
    "cageID": "ff6ef8f2-0222-4b09-a52d-a8a3bec48a83"
  }
  ```

- **Response**:
  - `200 OK`: Sensor successfully assigned to the cage  
    ```json
    {
      "id": "9fc0d5f3-a1f0-43c4-bd0e-8e7fa09f95d2",
      "message": "Sensor assigned to cage successfully",
      "cageID": "ff6ef8f2-0222-4b09-a52d-a8a3bec48a83"
    }
    ```
  - `400 Bad Request`: Invalid request body  
    ```json
    {
      "error": "Invalid request body"
    }
    ```
  - `401 Unauthorized`: Invalid token  
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
  - `404 Not Found`: Sensor hoặc cage không tồn tại  
    - Sensor not found:
      ```json
      {
        "error": "Sensor not found"
      }
      ```
    - Cage not found:
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

### 8. Remove A Sensor From Cage
- **Method**: `DELETE`
- **URL**: `/admin/sensors/:sensorID`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Parameters**:
  - `sensorID` (string, required): ID của cảm biến cần xóa khỏi cage.

- **Description**:
  - Endpoint này sẽ **xóa cảm biến khỏi cage** hiện tại mà không xóa cảm biến khỏi hệ thống.
  - Cảm biến sẽ không còn liên kết với cage, nhưng vẫn còn tồn tại trong hệ thống.

- **Response**:
  - `200 OK`: 
    ```json
    {
        "message": "Sensor removed from cage successfully"
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

### 9. Get Cages By User
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
          "status": "active" //inactive
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

### 10. Get Cage Details
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
        "status": "active", // inactive
        "devices": [
            {
                "id": "243ef9e1-5cde-4aa8-8b69-e4ff304c88eb",
                "name": "Fan 1",
                "status": "off" // on / auto,
                
            }
        ],
        "sensors": [
            {
                "id": "5ca7747f-2e0d-4eb5-9b62-3d17e9a77c2b",
                "type": "temperature",
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

### 11. Get List Available Devices
- **Method**: `GET`
- **URL**: `/admin/devices`
- **Headers**:
  - `Authorization: Bearer <token>`
- **Response**:
  - **200 OK**: 
    ```json
    [
        {
            "id": "2dab4c20-bf70-4d60-8d9f-d29dcb41cdc6",
            "name": "Fan 1"
        },
        {
            "id": "5f74e3d1-a327-42d5-a5e2-d6b9b46d1f50",
            "name": "Light 1"
        }
    ]
    ```
  - **401 Unauthorized**: Invalid token (missing token, expired, invalid)
    ```json
    {
      "error": "Invalid or expired token"
    }
    ```
  - **403 Forbidden**: Permission denied
    ```json
    {
      "error": "Permission denied"
    }
    ```
  - **500 Internal Server Error**: 
    ```json
    {
      "error": "Internal Server Error"
    }
    ```
### 11. Get List Available Sensors  
- **Method**: `GET`  
- **URL**: `/admin/sensors`  
- **Headers**:  
  - `Authorization: Bearer <token>`  

- **Response**:  
  - **200 OK**:  
    ```json
    [
        {
            "id": "bba6e308-f5a2-423b-8a1f-4de9371b0f20",
            "name": "Temperature Sensor 1"
        },
        {
            "id": "a7e0c3c5-52b9-4bb6-9ae0-7b4e7a83a5df",
            "name": "Humidity Sensor 2"
        }
    ]
    ```
  - **401 Unauthorized**: Invalid or expired token  
    ```json
    {
      "error": "Invalid or expired token"
    }
    ```
  - **403 Forbidden**: Permission denied 
    ```json
    {
      "error": "Permission denied"
    }
    ```
  - **500 Internal Server Error**:  
    ```json
    {
      "error": "Internal Server Error"
    }
    ```


## II. User Routes

### 1. Get Cages for Logged-in User
- **Method**: `GET`
- **URL**: `/cages`
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
          "status": "active" // inactive
      }
    ]
    ```
  - `401 Unauthorized`: Invalid token (miss token, expired, invalid)
    ```json
    {
      "error": "Invalid or expired token"
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
- **URL**: `/cages/:cageID`
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
        "status": "active", // inactive
        "devices": [
            {
                "id": "243ef9e1-5cde-4aa8-8b69-e4ff304c88eb",
                "name": "Fan 1",
                "status": "off", // on / auto
                "action_type": "on_off" // refill
            }
        ],
        "sensors": [
            {
                "id": "27bd5a13-a77e-4a28-9741-a6a08a1094cd",
                "type": "temperature",
                "unit": "oC"
            }
        ],
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
- **URL**: `/devices/:deviceID`
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
        "status": "off", // on auto
        "action_type": "on_off", // refill
        "automation_rule": [
            {
                "id": "c0c5b77b-2ba9-4292-b2ba-bd9cec11c394",
                "sensor_id": "5ca7747f-2e0d-4eb5-9b62-3d17e9a77c2b", 
                "sensor_type": "temperature", // humidity light water
                "condition": ">", // > < =
                "threshold": 30, // float
                "unit": "oC", // % lux %
                "action": "turn_on", // turn_off refill
            }
        ],
        "schedule_rule": [
          {
              "id": "3d142e2a-8d48-4bc8-8ff1-eadf2a9211bf",
              "execution_time": "17:17",
              "days": [
                  "mon",
                  "tue"
              ], // sun, mon, tue, wed, thu, fri, sat
              "action": "turn_on" //turn_off refill
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
- **URL**: `/devices/:deviceID/automations`
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
- **URL**: `/automations/:ruleID`
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
- **URL**: `/devices/:deviceID/schedules`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Parameters**:
    - deviceID (string, required): ID thiết bị muốn tạo schedules rule.
- **Request Body**:
  ```json
    {
        "execution_time": "17:17"
        , "days": ["mon", "tue"]
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
- **URL**: `/schedules/:ruleID`
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
        "error": "Schedule rule not found"
    }
    ```
  - `500 Internal Server Error`:
    ```json
    {
      "error": "Internal Server Error"
    }
    ```

### 8. Get Sensors in a Cage
- **Method**: `GET`
- **URL**: `/cages/:cageID/sensors`
- **Headers**:
  - `Authorization: Bearer <token>`
- **Parameters**:
  - `cageID` (string, required): ID của chuồng cần lấy danh sách cảm biến.
  
- **Response**:
  - **200 OK**: 
    ```json
    {
        "sensors": [
            {
                "id": "5ca7747f-2e0d-4eb5-9b62-3d17e9a77c2b",
                "type": "temperature",
                "unit": "°C"
            },
            {
                "id": "9c1b5747-d97a-429e-9b0a-8b7be87901db",
                "type": "humidity",
                "unit": "%"
            }
        ]
    }
    ```
  - **401 Unauthorized**: Invalid token (missing token, expired, invalid)
    ```json
    {
      "error": "Invalid or expired token"
    }
    ```
  - **403 Forbidden**: Permission denied (if the user does not have ownership of the cage)
    ```json
    {
      "error": "Permission denied"
    }
    ```
  - **404 Not Found**: Cage not found or no sensors found
    ```json
    {
      "error": "Sensors not found for the specified cage"
    }
    ```
  - **500 Internal Server Error**: 
    ```json
    {
      "error": "Internal Server Error"
    }
    ```

### 9. Get General Info
- **Method**: `GET`
- **URL**: `/api/cages/general-info`
- **Headers**:
  - `Authorization: Bearer <token>`
- **Response**:
  - **200 OK**: 
    ```json
    {
      "active_devices": 3
    }
    ```
  - **401 Unauthorized**: Invalid token (missing token, expired, invalid)
    ```json
    {
      "error": "Invalid or expired token"
    }
    ```

  - **500 Internal Server Error**: 
    ```json
    {
      "error": "Internal Server Error"
    }
    ```

### 10. Set Device Status
- **Method**: `PUT`
- **URL**: `/devices/:deviceID/status`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Parameters**:
  - `deviceID` (string, required): ID của thiết bị cần cập nhật trạng thái.
- **Request Body**:
  ```json
    {
      "status": "on" // off auto
    }
  ```
- **Response**:
  - **200 OK**: 
    ```json
    {
        "message": "Device status updated successfully"
    }
    ```
  - **400 Bad Request**: Invalid request body or missing status
    ```json
    {
        "error": "Invalid request body or Status is required"
    }
    ```
  - **401 Unauthorized**: Invalid token (missing token, expired, invalid)
    ```json
    {
        "error": "Invalid or expired token"
    }
    ```
  - **403 Forbidden**: Permission denied (if the user does not have ownership of the device)
    ```json
    {
      "error": "Permission denied"
    }
    ```
  - **404 Not Found**: Device not found 
    ```json
    {
      "error": "Device not found"
    }
    ```
  - **500 Internal Server Error**: 
    ```json
    {
        "error": "Failed to update device status"
    }
    ```


### 11. Update Device Name
- **Method**: `PUT`
- **URL**: `/devices/:deviceID/name`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Parameters**:
  - `deviceID` (string, required): ID của thiết bị cần cập nhật tên.
- **Request Body**:
  ```json
    {
      "name": "new_name" // off auto
    }
  ```
- **Response**:
  - **200 OK**: 
    ```json
    {
        "message": "Device name updated successfully"
    }
    ```
  - **400 Bad Request**: Invalid request body or duplicate name
    ```json
    {
        "error": "Invalid request body or Device name already exists"
    }
    ```
  - **401 Unauthorized**: Invalid token (missing token, expired, invalid)
    ```json
    {
        "error": "Invalid or expired token"
    }
    ```
  - **403 Forbidden**: Permission denied (if the user does not have ownership of the device)
    ```json
    {
      "error": "Permission denied"
    }
    ```
  - **404 Not Found**: Device not found 
    ```json
    {
      "error": "Device not found"
    }
    ```
  - **500 Internal Server Error**: 
    ```json
    {
        "error": "Failed to update device name"
    }
    ```

### 12. Active/Inactive A Cage 
- **Method**: `PUT`
- **URL**: `/cages/:cageID/status`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Parameters**:
  - `cageID` (string, required): ID của cage cần cập nhật trạng thái.
- **Request Body**:
  ```json
    {
      "status": "active" // inactive
    }
  ```
- **Response**:
  - **200 OK**: 
    ```json
    {
        "message": "Cage status updated successfully"
    }
    ```
  - **400 Bad Request**: Invalid status value
    ```json
    {
        "error": "Invalid status value"
    }
    ```
  - **401 Unauthorized**: Invalid token (missing token, expired, invalid)
    ```json
    {
        "error": "Invalid or expired token"
    }
    ```
  - **403 Forbidden**: Permission denied
    ```json
    {
        "error": "Permission denied"
    }
    ```
  - **500 Internal Server Error**: 
    ```json
    {
        "error": "Failed to update cage status"
    }
    ```

### 13. WebSocket - Receive Sensor Data for a Cage
- **Method**: `WebSocket`
- **URL**: `ws://{{base_url}}/api/user/cages/:cageID/sensors-data?token=<token>`
- **Parameters**:
  - `cageID` (string, required): ID của cage cần nhận dữ liệu cảm biến.
  - `token` (string, required): Token xác thực người dùng (được truyền dưới dạng query parameter).

- **Response**:
  - **200 OK**: 
    - Dữ liệu cảm biến sẽ được stream trực tiếp tới client qua kết nối WebSocket.
    ```json
      {
          "18f09a51-7777-4fbd-a036-5a28973ef080": 166.67,
          "ca8d27f8-ce9e-4198-9601-37cb9e0989d8": 28
      }
    ```
  - **400 Bad Request**: 
    - **Missing token**: 
    ```json
    {
      "error": "Authorization token is required"
    }
    ```
  - **401 Unauthorized**: 
    - **Invalid token**: 
    ```json
    {
      "error": "Invalid token"
    }
    ```
  - **403 Forbidden**: 
    - **Permission denied**: 
    ```json
    {
      "error": "Permission denied"
    }
    ```
  - **404 Not Found**: 
    - **Cage not found**: 
    ```json
    {
      "error": "Cage not found"
    }
    ```
  - **500 Internal Server Error**: 
    - **Internal Server Error**: 
    ```json
    {
      "error": "Internal Server Error"
    }
    ```

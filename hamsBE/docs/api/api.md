# HamsterCare API Specification

## Base Information
- **Base URL**: `http://localhost:8080/api`
- **Authentication**: Use `Authorization: Bearer <JWT_TOKEN>` for protected routes.
- **Content-Type**: `application/json` (except for file uploads).
- **Environment Variables**:
  - `JWT_SECRET_KEY`: Used for JWT signing/verification.
  - `SENDGRID_API_KEY`: For sending emails.
  - `EMAIL`: Sender email address.

## Authentication Routes (`/api/auth`)

### POST /auth/login
Authenticates a user and returns tokens.

- **Request**:
  ```json
  {
    "email": "string",
    "password": "string"
  }
  ```
- **Responses**:
  - **200**: 
    ```json
    {
      "access_token": "string",
      "refresh_token": "string",
      "user": {...}
    }
    ```

### POST /auth/logout
Logs out a user.

- **Request**: None
- **Responses**:
  - **200**: 
    ```json
    {
      "message": "Successfully logged out",
      "timestamp": "string"
    }
    ```

### POST /auth/change-password
Changes the user's password.

- **Request**:
  ```json
  {
    "old_password": "string",
    "new_password": "string"
  }
  ```
- **Responses**:
  - **200**: 
    ```json
    {
      "message": "Password changed successfully"
    }
    ```

### POST /auth/forgot-password
Sends an OTP for password reset.

- **Request**:
  ```json
  {
    "email": "string"
  }
  ```
- **Responses**:
  - **200**: 
    ```json
    {
      "message": "OTP sent to your email",
      "expires_at": "string"
    }
    ```
    or
    ```json
    {
      "message": "If the email exists, an OTP has been sent"
    }
    ```

### POST /auth/reset-password
Resets password using OTP.

- **Request**:
  ```json
  {
    "email": "string",
    "otp_code": "string",
    "new_password": "string"
  }
  ```
- **Responses**:
  - **200**: 
    ```json
    {
      "message": "Password reset successfully"
    }
    ```

### POST /auth/refresh
Refreshes access token.

- **Request**:
  ```json
  {
    "refresh_token": "string"
  }
  ```
- **Responses**:
  - **200**: 
    ```json
    {
      "access_token": "string",
      "refresh_token": "string"
    }
    ```

## OTP Routes (`/api`)

### POST /otp/create
Creates an OTP.

- **Request**:
  ```json
  {
    "user_id": "string"
  }
  ```
- **Responses**:
  - **200**: 
    ```json
    {
      "otp_code": "string",
      "expires_at": "string"
    }
    ```

### POST /otp/verify
Verifies an OTP.

- **Request**:
  ```json
  {
    "user_id": "string",
    "otp_code": "string"
  }
  ```
- **Responses**:
  - **200**: 
    ```json
    {
      "message": "Email verified successfully"
    }
    ```

## Profile Routes (`/api/profile`)

### GET /profile
Retrieves user profile.

- **Request**: None
- **Responses**:
  - **200**: 
    ```json
    {
      "message": "Profile retrieved successfully",
      "user": {...}
    }
    ```

### POST /profile/avatar
Updates user avatar.

- **Request**: `multipart/form-data`, `avatar: file`
- **Responses**:
  - **200**: 
    ```json
    {
      "message": "Avatar updated successfully",
      "user": {...}
    }
    ```

### GET /profile/avatar
Retrieves user avatar image.

- **Responses**:
  - **200**: JPEG image

### POST /profile/username
Updates username.

- **Request**:
  ```json
  {
    "username": "string"
  }
  ```
- **Responses**:
  - **200**: 
    ```json
    {
      "message": "Username updated successfully",
      "user": {...}
    }
    ```

## User Routes (`/api/users`)

### GET /users/:id
Gets user by ID.

- **Responses**:
  - **200**: 
    ```json
    {
      "id": "string",
      ...
    }
    ```

### GET /users/cages
Gets user cages.

- **Responses**:
  - **200**: 
    ```json
    [
      {
        "id": "string",
        ...
      }
    ]
    ```

### GET /users/cages/general-info
Counts active devices.

- **Responses**:
  - **200**: 
    ```json
    {
      "active_devices": 0
    }
    ```

### GET /users/cages/:cageID/sensors
Gets cage sensors.

- **Responses**:
  - **200**: 
    ```json
    {
      "sensors": [
        {...}
      ]
    }
    ```

### GET /users/cages/:cageID/sensors-data
Gets latest sensor data.

- **Responses**:
  - **200**: 
    ```json
    {
      "<sensor_type>": {...}
    }
    ```

### GET /users/cages/:cageID/statistics
Gets cage statistics.

- **Query Parameters**: `range`, `start_date`, `end_date`
- **Responses**:
  - **200**: 
    ```json
    {
      "statistics": [
        {...}
      ],
      "summary": {...}
    }
    ```

### PUT /users/cages/:cageID/settings
Updates cage settings.

- **Request**:
  ```json
  {
    "high_water_usage_threshold": 10
  }
  ```
- **Responses**:
  - **200**: 
    ```json
    {
      "message": "Settings updated successfully"
    }
    ```

### GET /users/cages/:cageID/sensors-data/ws
WebSocket for sensor data.

- **Messages**:
  ```json
  {
    "user_id": "string",
    "cage_id": "string",
    "type": "string",
    "title": "string",
    "message": "string",
    "time": 1697059200,
    "value": 0.0
  }
  ```
- **Responses**:
  - **101**: WebSocket established

### GET /users/cages/:cageID/notifications/ws
WebSocket for notifications.

- **Messages**:
  ```json
  {
    "user_id": "string",
    "cage_id": "string",
    "type": "notification",
    "title": "string",
    "message": "string",
    "time": 1697059200,
    "value": 0.0
  }
  ```
- **Responses**:
  - **101**: WebSocket established

### GET /users/cages/:cageID
Gets cage details.

- **Responses**:
  - **200**: 
    ```json
    {
      "id": "string",
      ...
    }
    ```

### GET /users/devices/:deviceID
Gets device details.

- **Responses**:
  - **200**: 
    ```json
    {
      "id": "string",
      ...
    }
    ```

### POST /users/devices/:deviceID/automations
Creates automation rule.

- **Request**:
  ```json
  {
    "sensor_id": "string",
    "condition": "string",
    "threshold": 0.0,
    "action": "string"
  }
  ```
- **Responses**:
  - **201**: 
    ```json
    {
      "message": "Automation rule created successfully",
      "id": "string"
    }
    ```

### DELETE /users/schedules/:ruleID
Deletes schedule rule.

- **Responses**:
  - **200**: 
    ```json
    {
      "message": "Schedule rule deleted successfully"
    }
    ```

### POST /users/devices/:deviceID/control
Controls a device.

- **Request**:
  ```json
  {
    "action": "string"
  }
  ```
- **Responses**:
  - **200**: 
    ```json
    {
      "message": "Device action executed successfully"
    }
    ```

### GET /users/notifications
Gets user notifications.

- **Responses**:
  - **200**: 
    ```json
    {
      "notifications": [
        {...}
      ]
    }
    ```

### PATCH /users/notifications/:notiID/read
Marks notification as read.

- **Responses**:
  - **200**: 
    ```json
    {
      "message": "Notification marked as read"
    }
    ```

## Admin Routes (`/api/admin`)

### GET /admin/users/:id
Gets user by ID.

- **Responses**:
  - **200**: 
    ```json
    {
      "id": "string",
      ...
    }
    ```

### GET /admin/users
Gets all users.

- **Responses**:
  - **200**: 
    ```json
    {
      "message": "Users retrieved successfully",
      "users": [
        {...}
      ]
    }
    ```

### POST /admin/auth/register
Registers a new user.

- **Request**:
  ```json
  {
    "username": "string",
    "email": "string",
    "password": "string",
    "role": "string"
  }
  ```
- **Responses**:
  - **201**: 
    ```json
    {
      "message": "User registered successfully",
      "user_id": "string"
    }
    ```

### DELETE /admin/users/:user_id
Deletes a user.

- **Responses**:
  - **200**: 
    ```json
    {
      "message": "User deleted successfully",
      "user_id": "string",
      "timestamp": "string"
    }
    ```

### POST /admin/users/:id/cages
Creates a cage.

- **Request**:
  ```json
  {
    "name_cage": "string"
  }
  ```
- **Responses**:
  - **201**: 
    ```json
    {
      "message": "Cage created successfully",
      "id": "string",
      "name": "string"
    }
    ```

### POST /admin/devices
Creates a device.

- **Request**:
  ```json
  {
    "name": "string",
    "type": "string",
    "cageID": "string"
  }
  ```
- **Responses**:
  - **201**: 
    ```json
    {
      "message": "Device created successfully",
      "id": "string",
      "name": "string"
    }
    ```

### PUT /admin/devices/:deviceID/cage
Assigns device to cage.

- **Request**:
  ```json
  {
    "cageID": "string"
  }
  ```
- **Responses**:
  - **200**: 
    ```json
    {
      "message": "Device assigned to cage successfully",
      "id": "string",
      "cageID": "string"
    }
    ```

### GET /admin/devices
Gets assignable devices.

- **Responses**:
  - **200**: 
    ```json
    [
      {...}
    ]
    ```

### GET /admin/sensors
Gets assignable sensors.

- **Responses**:
  - **200**: 
    ```json
    [
      {...}
    ]
    ```

### POST /admin/sensors
Creates a sensor.

- **Request**:
  ```json
  {
    "name": "string",
    "type": "string",
    "cageID": "string"
  }
  ```
- **Responses**:
  - **201**: 
    ```json
    {
      "message": "Sensor created successfully",
      "id": "string",
      "name": "string"
    }
    ```

### PUT /admin/sensors/:sensorID/cage
Assigns sensor to cage.

- **Request**:
  ```json
  {
    "cageID": "string"
  }
  ```
- **Responses**:
  - **200**: 
    ```json
    {
      "message": "Sensor assigned to cage successfully",
      "id": "string",
      "cageID": "string"
    }
    ```

### DELETE /admin/cages/:cageID
Deletes a cage.

- **Responses**:
  - **200**: 
    ```json
    {
      "message": "Cage deleted successfully"
    }
    ```
## I. Adafruit response body
```json
{
  "id": "abc123",
  "value": "25.6",
  "feed_key": "temperature",
  "created_at": "2025-03-04T10:30:00Z"
}
```
## II. IoT HamsterCare API Documentation

### 1. Authentication
#### POST /auth/register
**Request:**
```json
{
  "name": "string",
  "email": "string",
  "username": "string",
  "password": "string"
}
```
**Response:**
```json
{
  "message": "User Registered",
  "user": {
    "id": "string",
    "name": "string",
    "email": "string"
  }
}
```

#### POST /auth/login
**Request:**
```json
{
  "email": "string",
  "password": "string"
}
```
**Response:**
```json
{
  "token": "string",
  "user": {
    "id": "string",
    "name": "string",
    "email": "string"
  }
}
```

#### POST /auth/logout
**Request Header:**
```json
{
  "Authorization": "Bearer token"
}
```
**Response:**
```json
{
  "message": "Logout successfully"
}
```

#### GET /auth/profile
**Request Header:**
```json
{
  "Authorization": "Bearer token"
}
```
**Response:**
```json
{
  "id": "string",
  "name": "string",
  "email": "string",
  "startDate": "date"
}
```

---
### 2. Device Management
#### GET /devices
**Request Header:**
```json
{
  "Authorization": "Bearer token"
}
```
**Response:**
```json
[
  {
    "id": "string",
    "name": "Fan",
    "status": "ON/OFF",
    "mode": "Auto/Manual",
    "type": "Actuator",
    "cage_id": "string"
  }
]
```

#### POST /devices
**Request:**
```json
{
  "name": "string",
  "type": "Actuator",
  "cage_id": "string"
}
```
**Response:**
```json
{
  "message": "Device Created",
  "device": {
    "id": "string",
    "name": "string",
    "status": "OFF",
    "type": "Actuator"
  }
}
```

#### PUT /devices/:id
**Request:**
```json
{
  "status": "ON/OFF"
}
```
**Response:**
```json
{
  "message": "Device Updated",
  "device": {
    "id": "string",
    "status": "ON"
  }
}
```

#### PATCH /devices/:id/mode
**Request:**
```json
{
  "mode": "Auto/Manual"
}
```
**Response:**
```json
{
  "message": "Mode Updated",
  "device": {
    "id": "string",
    "mode": "Auto"
  }
}
```

#### DELETE /devices/:id
**Response:**
```json
{
  "message": "Device Deleted"
}
```

#### GET /devices/:id/logs
**Response:**
```json
[
  {
    "timestamp": "datetime",
    "status": "ON/OFF"
  }
]
```

---
### 3. Cage Management
#### GET /cages
**Response:**
```json
[
  {
    "id": "string",
    "name": "Cage 1",
    "temperature": "number",
    "humidity": "number",
    "water_level": "number"
  }
]
```

#### POST /cages
**Request:**
```json
{
  "name": "string",
  "devices": ["device_id1", "device_id2"]
}
```
**Response:**
```json
{
  "message": "Cage Created",
  "cage": {
    "id": "string",
    "name": "string"
  }
}
```

#### PUT /cages/:id
**Request:**
```json
{
  "name": "string"
}
```
**Response:**
```json
{
  "message": "Cage Updated"
}
```

#### DELETE /cages/:id
**Response:**
```json
{
  "message": "Cage Deleted"
}
```

---
### 4. Automation Rules
#### GET /devices/:id/rules
**Response:**
```json
[
  {
    "id": "string",
    "condition": "temp > 28",
    "action": "turn on Fan"
  }
]
```

#### POST /devices/:id/rules
**Request:**
```json
{
  "condition": "temp > 28",
  "action": "turn on Fan"
}
```
**Response:**
```json
{
  "message": "Rule Created"
}
```

#### PATCH /devices/:id/rules/:ruleId
**Request:**
```json
{
  "condition": "temp > 30"
}
```
**Response:**
```json
{
  "message": "Rule Updated"
}
```

#### DELETE /devices/:id/rules/:ruleId
**Response:**
```json
{
  "message": "Rule Deleted"
}
```

---
### 5. Notifications
#### GET /notifications
**Response:**
```json
[
  {
    "id": "string",
    "title": "Temperature Alert",
    "body": "Overheat!",
    "read": false
  }
]
```

#### PUT /notifications/:id
**Request:**
```json
{
  "read": true
}
```
**Response:**
```json
{
  "message": "Notification Read"
}
```

#### DELETE /notifications/:id
**Response:**
```json
{
  "message": "Notification Deleted"
}
```

---
### 6. Realtime Communication
#### WebSocket URL: /realtime
Payload:
```json
{
  "temperature": 30,
  "humidity": 80,
  "water_level": 50
}
```

---
### 7. User Settings
#### GET /users/:id/settings
**Response:**
```json
{
  "notification": true,
  "language": "en"
}
```

#### PUT /users/:id/settings
**Request:**
```json
{
  "notification": false,
  "language": "vi"
}
```
**Response:**
```json
{
  "message": "Settings Updated"
}
```

---

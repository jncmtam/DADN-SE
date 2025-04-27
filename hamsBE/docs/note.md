# API Documentation for Hamster Cage Management System

## 1. Admin Routes (REST APIs)

These APIs are defined in `admin_route.go` and require admin privileges, enforced by `JWTMiddleware()` and `authMiddleware("admin")`. They are used to manage users, cages, devices, and sensors.

| Method | Endpoint | Description | Parameters/Body | Success Response | Issue Relevance |
|--------|----------|-------------|-----------------|------------------|-----------------|
| GET | `/admin/users/:id` | Retrieves user information by ID. | Path: `id` (user ID) | HTTP 200: `{ "id": <string>, "username": <string>, "email": <string>, "role": <string> }` | Verifies user ownership of cages containing lamps/sensors. |
| GET | `/admin/users` | Lists all users. | - | HTTP 200: `{ "message": "Users retrieved successfully", "users": [{ "id", "username", "email", "role" }, ...] }` | Confirms users for assigning cages/devices. |
| POST | `/admin/auth/register` | Registers a new user (admin only). | Body: `{ "username": <string>, "email": <string>, "password": <string>, "role": <string> }` | HTTP 201: `{ "message": "User registered successfully", "user_id": <string> }` | Creates users for testing cage/device ownership. |
| DELETE | `/admin/users/:user_id` | Deletes a user by ID. | Path: `user_id` | HTTP 200: `{ "message": "User deleted successfully", "user_id": <string>, "timestamp": <time> }` | Cleans up user data during debugging. |
| POST | `/admin/users/:id/cages` | Creates a new cage for a user. | Path: `id` (user ID), Body: `{ "name_cage": <string> }` | HTTP 201: `{ "message": "Cage created successfully", "id": <string>, "name": <string> }` | Creates cages for assigning lamps/sensors, ensuring correct MQTT topics. |
| POST | `/admin/devices` | Creates a new device (e.g., lamp, pump). | Body: `{ "name": <string>, "type": "display/lock/light/pump/fan", "cageID": <optional string> }` | HTTP 201: `{ "message": "Device created successfully", "id": <string>, "name": <string> }` | Creates lamps (`type: "light"`) or sensors; critical for lamp issue. |
| PUT | `/admin/devices/:deviceID/cage` | Assigns a device to a cage. | Path: `deviceID`, Body: `{ "cageID": <string> }` | HTTP 200: `{ "message": "Device assigned to cage successfully", "id": <string>, "cageID": <string> }` | Ensures lamps are assigned to cages for correct MQTT topics. |
| DELETE | `/admin/devices/:deviceID` | Deletes a device. | Path: `deviceID` | HTTP 200: `{ "message": "Device deleted successfully" }` | Removes misconfigured lamps during debugging. |
| GET | `/admin/devices` | Lists assignable devices (not yet assigned to a cage). | - | HTTP 200: `[{ "id": <string>, "name": <string>, "type": <string> }, ...]` | Verifies lamp existence and configuration. |
| POST | `/admin/sensors` | Creates a new sensor (temperature, humidity, light, distance). | Body: `{ "name": <string>, "type": "temperature/humidity/light/distance", "cageID": <optional string> }` | HTTP 201: `{ "message": "Sensor created successfully", "id": <string>, "name": <string> }` | Creates sensors (`distance` for water level); misconfiguration can cause `water-level` error. |
| PUT | `/admin/sensors/:sensorID/cage` | Assigns a sensor to a cage. | Path: `sensorID`, Body: `{ "cageID": <string> }` | HTTP 200: `{ "message": "Sensor assigned to cage successfully", "id": <string>, "cageID": <string> }` | Ensures sensors are in the correct cage for automation rules. |
| DELETE | `/admin/sensors/:sensorID` | Deletes a sensor. | Path: `sensorID` | HTTP 200: `{ "message": "Sensor deleted successfully" }` | Removes misconfigured sensors (e.g., incorrect `water-level`). |
| GET | `/admin/sensors` | Lists assignable sensors. | - | HTTP 200: `[{ "id": <string>, "name": <string>, "type": <string> }, ...]` | Verifies sensor types (e.g., `distance` vs. `water_level`). |
| DELETE | `/admin/cages/:cageID` | Deletes a cage. | Path: `cageID` | HTTP 200: `{ "message": "Cage deleted successfully" }` | Cleans up misconfigured cages during debugging. |
| GET | `/admin/cages/:cageID` | Retrieves cage details, including sensors and devices. | Path: `cageID` | HTTP 200: `{ "id": <string>, "name": <string>, "status": <string>, "sensors": [...], "devices": [...] }` | Verifies lamp/sensor assignments in the cage. |
| GET | `/admin/users/:id/cages` | Lists cages for a user. | Path: `id` (user ID) | HTTP 200: `[{ "id": <string>, "name": <string>, "num_device": <int>, "status": <string> }, ...]` | Checks user cages for debugging ownership. |

## 2. User Routes (REST APIs)

These APIs are defined in `user_route.go` and are accessible to authenticated users, enforced by `JWTMiddleware()` and `ownershipMiddleware`. They focus on viewing data, controlling devices, and managing automation rules.

| Method | Endpoint | Description | Parameters/Body | Success Response | Issue Relevance |
|--------|----------|-------------|-----------------|------------------|-----------------|
| GET | `/:id` | Retrieves user information by ID. | Path: `id` (user ID) | HTTP 200: `{ "id": <string>, "username": <string>, "email": <string>, "role": <string> }` | Verifies user identity for ownership checks. |
| GET | `/cages` | Lists all user cages, including sensors and devices. | - | HTTP 200: `[{ "id": <string>, "name": <string>, "num_sensor": <int>, "num_device": <int>, "status": <string>, "sensors": [...], "devices": [...] }, ...]` | Confirms lamp/sensor assignments in user cages. |
| GET | `/cages/general-info` | Retrieves general info (e.g., count of active devices). | - | HTTP 200: `{ "active_devices": <int> }` | Checks device status, including lamps. |
| GET | `/cages/:cageID/sensors` | Lists sensors in a cage. | Path: `cageID` | HTTP 200: `{ "sensors": [{ "id": <string>, "name": <string>, "type": <string>, ... }, ...] }` | Verifies sensor types (e.g., `water_level`) for debugging sensor type error. |
| GET | `/cages/:cageID/sensors-data` | Retrieves recent sensor data (last 4 records). | Path: `cageID` | HTTP 200: `{ <sensor_type>: { "id": <string>, "value": <float>, "unit": <string>, "timestamp": <int> }, ... }` | Verifies `water_level` data for automation debugging. |
| GET | `/cages/:cageID/statistics` | Retrieves cage statistics (e.g., water refill amounts). | Path: `cageID`, Query: `range`, `start_date`, `end_date` | HTTP 200: `{ "statistics": [{ "date": <string>, "water_refill_sl": <int> }, ...], "summary": { "total_refills": <int>, "average_per_day": <float> } }` | Debugs automation related to pumps. |
| DELETE | `/automations/:ruleID` | Deletes an automation rule. | Path: `ruleID` | HTTP 200: `{ "message": "Automation rule deleted successfully" }` | Removes conflicting rules that may turn off the lamp. |
| GET | `/notifications` | Lists user notifications. | Query: `limit`, `offset` | HTTP 200: `{ "notifications": [{ "id": <string>, "cage_id": <string>, "type": <string>, "title": <string>, "message": <string>, "is_read": <bool>, "created_at": <string> }, ...], "count": <int> }` | Views notifications about lamp/sensor status. |
| PUT | `/cages/:cageID/settings` | Updates cage settings (e.g., high water usage threshold). | Path: `cageID`, Body: `{ "high_water_usage_threshold": <int> }` | HTTP 200: `{ "message": "Settings updated successfully" }` | Updates thresholds for automation rules. |
| POST | `/devices/:deviceID/control` | Controls a device (e.g., turn on/off lamp). | Path: `deviceID`, Body: `{ "action": "turn_on/turn_off/refill/lock/auto" }` | HTTP 200: `{ "message": "Device action executed successfully" }` | Primary endpoint for lamp control; incorrect MQTT payload (`1.0` vs. `"ON"`) causes lamp issue. |
| GET | `/devices/:deviceID` | Retrieves device details, including automation rules. | Path: `deviceID` | HTTP 200: `{ "id": <string>, "name": <string>, "status": <string>, "type": <string>, "automation_rule": [{ "id", "sensor_id", "sensor_type", "condition", "threshold", "unit", "action" }, ...] }` | Checks automation rules affecting the lamp. |
| POST | `/devices/:deviceID/automations` | Creates an automation rule for a device. | Path: `deviceID`, Body: `{ "sensor_id": <string>, "condition": ">/<=", "threshold": <float>, "action": "turn_on/turn_off/refill" }` | HTTP 201: `{ "message": "Automation rule created successfully", "automation_rule": { "id", "sensor_id", "sensor_type", "condition", "threshold", "unit", "action" } }` | Creates rules to turn on lamp based on `water_level` sensor. |
| GET | `/cages/:cageID` | Retrieves cage details, including sensors and devices. | Path: `cageID` | HTTP 200: `{ "id": <string>, "name": <string>, "status": <string>, "sensors": [...], "devices": [{ "id", "name", "status", "action_type" }, ...] }` | Verifies cage configuration with lamps/sensors. |
| GET | `/sensors/:sensorID` | Retrieves sensor details. | Path: `sensorID` | HTTP 200: `{ "id": <string>, "name": <string>, "type": <string>, "value": <float>, "unit": <string>, "cage_id": <string> }` | Confirms sensor type (e.g., `distance` vs. `water_level`). |
| PATCH | `/notifications/:notiID/read` | Marks a notification as read. | Path: `notiID` | HTTP 200: `{ "message": "Notification marked as read" }` | Manages notifications during lamp debugging. |

## 3. WebSocket Routes

These WebSocket endpoints are defined in `user_route.go` and provide real-time notifications and sensor data for users.

| Endpoint | Description | Parameters | Messages Received | Issue Relevance |
|----------|-------------|------------|-------------------|-----------------|
| `/cages/:cageID/sensors-data/ws` | Establishes a WebSocket connection for real-time sensor data. | Path: `cageID` | Type: `sensor_data`, Payload: `{ "user_id": <string>, "type": "sensor_data", "title": <string>, "message": <string>, "cage_id": <string>, "sensor_id": <string>, "unit": <string>, "time": <int>, "value": <float> }` | Receives `water_level` data to debug automation rules. |
| `/cages/:cageID/notifications/ws` | Establishes a WebSocket connection for notifications (e.g., device status changes). | Path: `cageID` | Types: `info`, `device_status_change`, Payload: `{ "user_id": <string>, "type": <string>, "title": <string>, "message": <string>, "cage_id": <string>, "time": <int>, "value": <float>, "data": <optional object> }` | Receives notifications when lamp turns on/off or sensor reports anomalies. |

## 4. Issue Analysis and API Relevance

### 4.1 Lamp Not Turning On
- **Problem**: The `POST /devices/:deviceID/control` endpoint updates the lamp status to `"on"` in the database but sends an MQTT payload with `value: 1.0`. The lamp firmware may expect `value: "ON"`, causing it to remain off.
- **Related APIs**:
  - `POST /admin/devices`: Creates the lamp with `type: "light"`.
  - `PUT /admin/devices/:deviceID/cage`: Assigns the lamp to a cage, ensuring correct MQTT topic.
  - `POST /devices/:deviceID/control`: Sends the control command; needs to use `value: "ON"`.
  - `POST /devices/:deviceID/automations`: Automation rules may turn on the lamp but are affected by the same payload issue.
- **Solution**: Modified `POST /devices/:deviceID/control` to send `value: "ON"` for lamps.

### 4.2 Invalid Sensor Type: `water-level`
- **Problem**: MQTT payloads use `dataname: "water-level"`, which isn't normalized to `water_level` in `handleMessage`. Additionally, `POST /admin/sensors` only supports `distance` for water level sensors.
- **Related APIs**:
  - `POST /admin/sensors`: Creates sensors with `type: "distance"`, which should support `water_level`.
  - `GET /cages/:cageID/sensors-data`: Verifies sensor data to debug `water_level`.
  - `POST /devices/:deviceID/automations`: Automation rules fail if the sensor type is invalid.
- **Solution**: Updated `POST /admin/sensors` to include `water_level` and normalized `distance`/`water-level` to `water_level` in `handleMessage`.

### 4.3 PostgreSQL Transaction Error
- **Problem**: The `SaveMessageToDB` function attempts to commit a transaction after `checkAutomationRules` fails due to an invalid sensor type.
- **Related APIs**:
  - `POST /devices/:deviceID/automations`: Creates automation rules triggered by sensor data via MQTT.
  - `/cages/:cageID/sensors-data/ws`: Real-time sensor data may trigger automation rules.
- **Solution**: Improved error handling in `SaveMessageToDB` to return errors before committing transactions.

## 5. Verification Steps

1. **Create and Assign Lamp/Sensor**:
   - Create a lamp:
     ```bash
     curl -X POST http://localhost:8080/admin/devices \
     -H "Authorization: Bearer <admin_jwt>" \
     -H "Content-Type: application/json" \
     -d '{"name":"Lamp1","type":"light","cageID":""}'
     ```
   - Assign lamp to a cage:
     ```bash
     curl -X PUT http://localhost:8080/admin/devices/<lamp_deviceID>/cage \
     -H "Authorization: Bearer <admin_jwt>" \
     -H "Content-Type: application/json" \
     -d '{"cageID":"<cageID>"}'
     ```
   - Create a water level sensor:
     ```bash
     curl -X POST http://localhost:8080/admin/sensors \
     -H "Authorization: Bearer <admin_jwt>" \
     -H "Content-Type: application/json" \
     -d '{"name":"WaterLevel1","type":"water_level","cageID":""}'
     ```
   - Assign sensor to the same cage:
     ```bash
     curl -X PUT http://localhost:8080/admin/sensors/<sensorID>/cage \
     -H "Authorization: Bearer <admin_jwt>" \
     -H "Content-Type: application/json" \
     -d '{"cageID":"<cageID>"}'
     ```

2. **Test Lamp Control**:
   - Call the control endpoint:
     ```bash
     curl -X POST http://localhost:8080/devices/<lamp_deviceID>/control \
     -H "Authorization: Bearer <user_jwt>" \
     -H "Content-Type: application/json" \
     -d '{"action":"turn_on"}'
     ```
   - Check logs for:
     - `[INFO] Publishing to MQTT topic ...: {"value":"ON"}`
     - `[INFO] Sent WebSocket notification ...`
   - Verify database:
     ```sql
     SELECT status FROM devices WHERE id = '<lamp_deviceID>';
     ```
     Expected: `status = 'on'`.
   - Monitor MQTT:
     ```bash
     mosquitto_sub -h <broker_host> -t 'hamster/+/+/device/<lamp_deviceID>/+'
     ```
     Expected: `{"value":"ON"}`.

3. **Test Sensor Data**:
   - Publish a sensor message:
     ```bash
     mosquitto_pub -h <broker_host> -t 'hamster/testuser/cage1/sensor/<sensorID>/water-level' -m '{"username":"testuser","cagename":"cage1","type":"sensor","id":"<sensorID>","dataname":"water-level","value":"10.0","time":1730013600000}'
     ```
   - Check logs for:
     - `[DEBUG] MQTT message dataname=water-level, normalized sensorType=water_level`
     - No `Invalid sensor type` errors.
   - Verify database:
     ```sql
     SELECT * FROM sensor_data WHERE sensor_id = '<sensorID>' ORDER BY created_at DESC LIMIT 1;
     ```
     Expected: `value = 10.0`.

4. **Test Automation Rule**:
   - Create a rule to turn on the lamp when water level is low:
     ```bash
     curl -X POST http://localhost:8080/devices/<lamp_deviceID>/automations \
     -H "Authorization: Bearer <user_jwt>" \
     -H "Content-Type: application/json" \
     -d '{"sensor_id":"<sensorID>","condition":"=","threshold":10.0,"action":"turn_on"}'
     ```
   - Publish the sensor message again and verify the lamp turns on (MQTT payload: `{"value":"ON"}`).

5. **Check WebSocket Notifications**:
   - Connect to WebSocket:
     ```bash
     wscat -c ws://localhost:8080/cages/<cageID>/notifications/ws -H "Authorization: Bearer <user_jwt>"
     ```
   - Verify `info` or `device_status_change` messages for lamp status changes.

## 6. Notes

- The APIs provide comprehensive functionality for managing cages, devices, sensors, and automation rules in the hamster cage system.
- Solutions have been implemented to address the lamp issue (`value: "ON"`), sensor type error (`water_level` normalization), and transaction error (improved error handling).
- If issues persist, provide logs, MQTT payloads, or database query results for further assistance.

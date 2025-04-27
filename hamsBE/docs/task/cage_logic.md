# Hamstercare Project

- Target : To supply customers customized hamster cages with sensors and devices to control hamsters' life. The admin will come directively to customers' house and set up everything for them.

## Task

```txt
- Implement logical constraint between cages, devices, sensors via automation rules.
    + Users can change the automation rules for sensors (condition, schedule{time, date}).
    + If users don't set automation rules all sensors status will be the latest status.
- Setup dynamic topics for mosquitto mqtt and specify pub/sub data.
- Implement API and functions below.
```

## IOT

- Just have 4 sensor and 3 device connected to a ESP32.
- Required a dynamic topics for each user:
  - e.g : `user1` has many `cages` and in each cage there would be one or more `sensors` and `devices` so the topics should be:

```txt
1. hamster/:userID/:cageID/sensor/:sensorID/{sensorType}
  - sensorType :
    + dht20 (temperature, humidity)
    + distance sensor (to measure water level) -> distance sensor is placed on the top of the botte
    + light sensor
2. hamster/:userID/:cageID/device/:deviceID/{deviceType}
  - deviceType :
    + led (auto/on/off) -> light > 100 lux
    + fan (auto/on/off) -> temp > 31°C || humid > 70%
    + pump (auto/off) -> water level < 10% and stop pumping ~90%
```

## Prompts

- - Write full backend services. `Golang` and `Postgres` only !
- Comment the code in detailed with the syntax e.g : // Get device from cage
- If the functions have been declared, compare the new functions with the old one.
- Create MQTT dynamic topic through (pub/sub) -> use `bash scripts` to generate data and `automation rules` for devices. `Not random` because i want to change the value. Just declare not enter from keyboard.
- Write API (`functions`, `repo`, `service`, `model`) to perform cages, sensors, devices, automation rules, statistic relationship.
- Write SQL (migrate and queries) then call it from repo, not implement in the Go code.
- Calculate statistic directively in database.
- Congfig `Websocket` to send realtime notification to Flutter.
- Config `Websocket` to send `realtime data` from Mosquitto MQTT to FE for visualizing.
- Data from sensors ain't saved into database, just data which satisfy conditions are caught by Backend to calculate the statistics.
  - Water left (10% < x < 90%)
  ```txt
  distance sensor
  | |
  | |
  | |
  d1--> current water level
  | |
  | |
  ⇩ ⇩
  d--->height of bottle
  -> %water_left = (d-d1)/d * 100%
  ```
  - Energy consume = Energy(5w for mini devices)\*Time(operand time)
    - Store devices' energy daily and monthly.
    -

## API

1. Set Cage Status -> `PUT` /user/cages/:cageID

```json
{
  "status": "off" // on/off
}
```

2. Get Cage Details for Logged-in User -> `GET` /user/cages/:cageID

```json
{
    "id": "2dab4c20-bf70-4d60-8d9f-d29dcb41cdc6",
    "name": "Cage 1",
    "status": "on" // on/off
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
            "unit": "°C"
        }
    ]
}
```

3. WebSocket: user/cages/:cageID/sensors-data?token=<jwtToken>

```json
{
	"sensorId": value,
	"5ca7747f-2e0d-4eb5-9b62-3d17e9a77c2b": 30,
}

// WebSocket -> ws://localhost:8080/api/user/cages/:cageId/sensors-data?token=<jwtToken>
// HTTP -> http://localhost:8080/api/user/cages/:cageId/sensors-data (token in header)
```

4. Get Device Details for Logged-in User -> `GET` /user/devices/:deviceID

```json
{
  "id": "243ef9e1-5cde-4aa8-8b69-e4ff304c88eb",
  "name": "Fan 1",
  "status": "off",
  "automation_rule": [
    {
      "id": "c0c5b77b-2ba9-4292-b2ba-bd9cec11c394",
      "sensor_id": "5ca7747f-2e0d-4eb5-9b62-3d17e9a77c2b",
      "sensor_type": "temperature", // temperature, humidity, infrared, light, distance
      "condition": ">", // > < = ?
      "threshold": 30, // float?
      "unit": "oC", // should be % for water
      "action": "turn_on" // on/off/refill
    }
  ],
  "schedule_rule": [
    {
      "id": "3d142e2a-8d48-4bc8-8ff1-eadf2a9211bf",
      "execution_time": "0000-01-01T17:17:00Z", // HH:MM (21:40)
      "days": ["Mon", "Tue"], // sun, mon, tue, wed, thu, fri, sat
      "action": "turn_on" // on/off/refill
    }
  ]
}
```

5. Set Device Status -> `PUT` /user/devices/:deviceID

```json
{
  "status": "off" // on/off/auto
}
```

6. Add Automation Rule for Device -> Modify

```json
{
  "sensor_id": "5ca7747f-2e0d-4eb5-9b62-3d17e9a77c2b",
  "condition": "<",
  "threshold": 30,
  "action": "turn_on" // on/off/refill
}
```

## MQTT

- Mostquitto config

```sh
mosquitto -c mosquitto.conf
```

- Bash scripts

```sh
chmod +x scripts/simulate_sensor.sh scripts/simulate_device.sh
./scripts/simulate_sensor.sh &
./scripts/simulate_device.sh &
```

## BE project structure

```json
┣ hamsBE
 ┃ ┣ api
 ┃ ┃ ┣ routes
 ┃ ┃ ┃ ┣ admin_route.go
 ┃ ┃ ┃ ┣ auth_route.go
 ┃ ┃ ┃ ┗ user_route.go
 ┃ ┃ ┗ router.go
 ┃ ┣ internal
 ┃ ┃ ┣ database
 ┃ ┃ ┃ ┣ migrations
 ┃ ┃ ┃ ┃ ┣ 001_create_users.up.sql
 ┃ ┃ ┃ ┃ ┣ 002_create_cages.up.sql
 ┃ ┃ ┃ ┃ ┣ 003_create_sensors.up.sql
 ┃ ┃ ┃ ┃ ┣ 004_create_devices.up.sql
 ┃ ┃ ┃ ┃ ┣ 005_create_automationrules.up.sql
 ┃ ┃ ┃ ┃ ┣ 006_create_notifications.up.sql
 ┃ ┃ ┃ ┃ ┣ 007_create_statistic.up.sql
 ┃ ┃ ┃ ┃ ┗ 008_create_schedulerules.up.sql
 ┃ ┃ ┃ ┣ queries
 ┃ ┃ ┃ ┃ ┣ automation_queries.sql
 ┃ ┃ ┃ ┃ ┣ cage_queries.sql
 ┃ ┃ ┃ ┃ ┣ device_queries.sql
 ┃ ┃ ┃ ┃ ┣ loader.go
 ┃ ┃ ┃ ┃ ┣ notification_queries.sql
 ┃ ┃ ┃ ┃ ┣ schedule_queries.sql
 ┃ ┃ ┃ ┃ ┣ sensor_queries.sql
 ┃ ┃ ┃ ┃ ┣ statistic_queries.sql
 ┃ ┃ ┃ ┃ ┗ user_queries.sql
 ┃ ┃ ┃ ┣ connectDB.go
 ┃ ┃ ┃ ┣ init.sh
 ┃ ┃ ┃ ┣ schema.sql
 ┃ ┃ ┃ ┗ tempCodeRunnerFile.sh
 ┃ ┃ ┣ middleware
 ┃ ┃ ┃ ┣ jwt.go
 ┃ ┃ ┃ ┗ validate.go
 ┃ ┃ ┣ model
 ┃ ┃ ┃ ┣ auth_model.go
 ┃ ┃ ┃ ┣ automation_model.go
 ┃ ┃ ┃ ┣ cage_model.go
 ┃ ┃ ┃ ┣ device_model.go
 ┃ ┃ ┃ ┣ otp_model.go
 ┃ ┃ ┃ ┣ schedule_model.go
 ┃ ┃ ┃ ┣ sensor_model.go
 ┃ ┃ ┃ ┗ user_model.go
 ┃ ┃ ┣ mqtt
 ┃ ┃ ┃ ┗ mqtt.go
 ┃ ┃ ┣ repository
 ┃ ┃ ┃ ┣ automation_repo.go
 ┃ ┃ ┃ ┣ cage_repo.go
 ┃ ┃ ┃ ┣ device_repo.go
 ┃ ┃ ┃ ┣ notification_repo.go
 ┃ ┃ ┃ ┣ otp_repo.go
 ┃ ┃ ┃ ┣ schedule_repo.go
 ┃ ┃ ┃ ┣ sensor_repo.go
 ┃ ┃ ┃ ┣ statistic_repo.go
 ┃ ┃ ┃ ┗ user_repo.go
 ┃ ┃ ┣ service
 ┃ ┃ ┃ ┣ auth_service.go
 ┃ ┃ ┃ ┣ automation_service.go
 ┃ ┃ ┃ ┣ cage_service.go
 ┃ ┃ ┃ ┣ device_sevice.go
 ┃ ┃ ┃ ┣ schedule_service.go
 ┃ ┃ ┃ ┗ sensor_service.go
 ┃ ┃ ┣ utils
 ┃ ┃ ┃ ┗ sendMail.go
 ┃ ┃ ┣ websocket
 ┃ ┃ ┃ ┗ ws.go
 ┃ ┃ ┗ .DS_Store
 ┃ ┣ iot_hardware
 ┃ ┃ ┣ mosquitto
 ┃ ┃ ┃ ┗ mosquitto.conf
 ┃ ┃ ┣ yolobit
 ┃ ┃ ┃ ┣ dht11_test.ino
 ┃ ┃ ┃ ┣ yolobit.h
 ┃ ┃ ┃ ┗ yolobit.ino
 ┃ ┣ public
 ┃ ┃ ┗ avatars
 ┃ ┃ ┃ ┣ 57c72939-64a2-4dcf-94b7-fe890df1ec99.jpg
 ┃ ┃ ┃ ┣ 59709685-21e1-4553-8cd0-70120e8e4a9e.jpg
 ┃ ┃ ┃ ┗ default.jpg
 ┃ ┣ scripts
 ┃ ┃ ┣ migrate.sh
 ┃ ┃ ┣ simulate_device.sh
 ┃ ┃ ┗ simulate_sensor.sh
 ┃ ┣ .air.toml
 ┃ ┣ .env
 ┃ ┣ .gitignore
 ┃ ┣ Dockerfile
 ┃ ┣ Makefile
 ┃ ┣ README.md
 ┃ ┣ docker-compose.yml
 ┃ ┣ go.mod
 ┃ ┣ go.sum
 ┃ ┣ main
 ┃ ┗ main.go
```

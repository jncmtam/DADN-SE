#!/bin/bash

# Simulate sensor data for a specific user and cage
USER_ID="user1"
CAGE_ID="cage1"
SENSOR_ID="sensor1"
BROKER="localhost:1883"

# Temperature sensor (dht20)
mosquitto_pub -h $BROKER -t "hamster/$USER_ID/$CAGE_ID/sensor/$SENSOR_ID/temperature" -m "25.5"

# Humidity sensor (dht20)
mosquitto_pub -h $BROKER -t "hamster/$USER_ID/$CAGE_ID/sensor/$SENSOR_ID/humidity" -m "60.0"

# Distance sensor (water level, d1 in cm)
mosquitto_pub -h $BROKER -t "hamster/$USER_ID/$CAGE_ID/sensor/$SENSOR_ID/distance" -m "2.0"

# Light sensor
mosquitto_pub -h $BROKER -t "hamster/$USER_ID/$CAGE_ID/sensor/$SENSOR_ID/light" -m "150.0"
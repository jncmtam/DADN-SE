#!/bin/bash

# Configuration for MQTT Broker
BROKER=${MQTT_BROKER:-"localhost"}
PORT=${MQTT_PORT:-1883}

# User and cage IDs (configurable via environment variables)
USER_ID=${USER_ID:-"user1"}
CAGE_ID=${CAGE_ID:-"cage1"}

# Function to get current timestamp
get_timestamp() {
  echo $(date "+%Y-%m-%dT%H:%M:%SZ")
}

# Function to publish sensor data
publish_sensor_data() {
  SENSOR_ID=$1
  SENSOR_TYPE=$2
  VALUE=$3

  TIMESTAMP=$(get_timestamp)
  TOPIC="hamster/$USER_ID/$CAGE_ID/sensor/$SENSOR_ID"
  PAYLOAD="{\"sensor_id\": \"$SENSOR_ID\", \"sensor_type\": \"$SENSOR_TYPE\", \"value\": $VALUE, \"timestamp\": \"$TIMESTAMP\"}"

  echo ">> Publishing to $TOPIC: $PAYLOAD"
  mosquitto_pub -h "$BROKER" -p "$PORT" -t "$TOPIC" -m "$PAYLOAD"
}

# Function to publish device data
publish_device_data() {
  DEVICE_ID=$1
  DEVICE_TYPE=$2
  VALUE=$3

  TIMESTAMP=$(get_timestamp)
  TOPIC="hamster/$USER_ID/$CAGE_ID/device/$DEVICE_ID"
  PAYLOAD="{\"device_id\": \"$DEVICE_ID\", \"device_type\": \"$DEVICE_TYPE\", \"value\": \"$VALUE\", \"timestamp\": \"$TIMESTAMP\"}"

  echo ">> Publishing to $TOPIC: $PAYLOAD"
  mosquitto_pub -h "$BROKER" -p "$PORT" -t "$TOPIC" -m "$PAYLOAD"
}

# Test script
# Test humidity (low, then high to trigger rule)
publish_sensor_data "sensor2" "humidity" 45.0
sleep 2
publish_sensor_data "sensor2" "humidity" 75.5
sleep 2

# Test temperature
publish_sensor_data "sensor1" "temperature" 37.2
sleep 2

# Test light
publish_sensor_data "sensor3" "light" 95.0
sleep 2

# Test distance (water level)
publish_sensor_data "sensor5" "distance" 15.3
sleep 2


# Test device
publish_device_data "device1" "fan" "on"
sleep 2
publish_device_data "device2" "pump" "refill"

# export USER_ID="user1" CAGE_ID="cage1" 
# ./scripts/sensor_data.sh
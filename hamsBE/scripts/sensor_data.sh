#!/bin/bash

# Configuration for MQTT Broker
BROKER=${MQTT_BROKER:-"localhost"}
PORT=${MQTT_PORT:-1883}

# User and cage IDs (configurable via environment variables)
USER_ID=${USER_ID:-"11111111-1111-1111-1111-111111111111"}
CAGE_ID=${CAGE_ID:-"33333333-3333-3333-3333-333333333333"}

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
publish_sensor_data "bbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb" "humidity" 35.0  # Should trigger rule (< 40%)
sleep 2
publish_sensor_data "bbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb" "humidity" 75.5
sleep 2

# Test temperature
publish_sensor_data "aaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" "temperature" 37.2  # Should trigger rule (> 30°C)
sleep 2

# Test light
publish_sensor_data "ddddddd-dddd-dddd-dddd-dddddddddddd" "light" 95.0
sleep 2

# Test distance (water level)
publish_sensor_data "eeeeeee-eeee-eeee-eeee-eeeeeeeeeeee" "distance" 15.3  # No sensor with this ID in DB
sleep 2

# Test device
publish_device_data "66666666-6666-6666-6666-666666666666" "fan" "on"
sleep 2
publish_device_data "77777777-7777-7777-7777-777777777777" "pump" "refill"
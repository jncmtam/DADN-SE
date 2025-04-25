#!/bin/bash

# Configuration for MQTT Broker
BROKER=${MQTT_BROKER:-"localhost"}
PORT=${MQTT_PORT:-1883}

# User and Cage (matching sample data)
USERNAME=${USERNAME:-"user1"}
CAGENAME=${CAGENAME:-"cage1"}

# Function to get Unix timestamp (int64)
get_timestamp() {
  date "+%s"
}

# Function to publish IoT device data (JSON)
publish_iot_data() {
  local TYPE=$1 # sensor or device
  local ID=$2
  local DATANAME=$3
  local VALUE=$4
  local TIMESTAMP=$(get_timestamp)
  local TOPIC="hamster/$USERNAME/$CAGENAME/$TYPE/$ID"

  local PAYLOAD=$(cat <<EOF
{
  "username": "$USERNAME",
  "cagename": "$CAGENAME",
  "type": "$TYPE",
  "id": $ID,
  "dataname": "$DATANAME",
  "value": "$VALUE",
  "time": $TIMESTAMP
}
EOF
)

  echo "📡 Sending $TYPE: $TOPIC"
  echo "$PAYLOAD"
  mosquitto_pub -h "$BROKER" -p "$PORT" -t "$TOPIC" -m "$PAYLOAD"
}

# 🧪 Test cases — aligned with IoT device format and sample data
echo "▶️ Starting test data push..."

# Sensors
publish_iot_data "sensor" 1 "temperature" 35.0 # Triggers high temperature warning
sleep 2
publish_iot_data "sensor" 2 "humidity" 85.0   # Triggers high humidity warning
sleep 2
publish_iot_data "sensor" 3 "light" 100.0     # Normal value
sleep 2
publish_iot_data "sensor" 4 "distance" 19.0   # Triggers low water level warning
sleep 2

# Devices
publish_iot_data "device" 5 "fan" "off"  # Represents "on" (adjust value based on IoT device)
sleep 2
publish_iot_data "device" 6 "led" "off" # Represents "on"
sleep 2
publish_iot_data "devvice" 7  "pump" "off" 
sleep 2

echo "✅ All test messages published!"
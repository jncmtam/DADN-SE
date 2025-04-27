#!/bin/bash

# MQTT cấu hình
BROKER=${MQTT_BROKER:-"localhost"}
PORT=${MQTT_PORT:-1883}
USERNAME=${USERNAME:-"user1"}
CAGENAME=${CAGENAME:-"cage1"}

# Hàm lấy timestamp
get_timestamp() {
  date "+%s"
}

# Hàm tạo số ngẫu nhiên float (đơn giản)
random_float() {
  awk -v min=$1 -v max=$2 'BEGIN {srand(); print min + rand() * (max - min)}'
}

# Hàm gửi dữ liệu
publish_iot_data() {
  local TYPE=$1
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

# 🔁 Vòng lặp gửi liên tục mỗi 5 giây
while true; do
  TEMP=$(random_float 28.0 40.0)
  HUM=$(random_float 50.0 90.0)
  LIGHT=$(random_float 80.0 150.0)
  DIST=$(random_float 5.0 25.0)

  # Gửi sensor
  publish_iot_data "sensor" 1 "temperature" "$TEMP"
  sleep 2
  publish_iot_data "sensor" 2 "humidity" "$HUM"
  sleep 2
  publish_iot_data "sensor" 3 "light" "$LIGHT"
  sleep 2
  publish_iot_data "sensor" 4 "distance" "$DIST"
  sleep 2

  echo "⏱️ Đợi 5 giây trước vòng tiếp theo..."
  sleep 5
done

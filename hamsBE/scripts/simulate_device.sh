#!/bin/bash

# Simulate device commands for a specific user and cage
USER_ID="user1"
CAGE_ID="cage1"
DEVICE_ID="device1"
BROKER="localhost:1883"

# Subscribe to device commands
mosquitto_sub -h $BROKER -t "hamster/$USER_ID/$CAGE_ID/device/$DEVICE_ID/command"
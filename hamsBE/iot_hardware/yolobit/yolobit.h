#include <Wire.h>
#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT20.h>
#include <LiquidCrystal_I2C.h>
#include <Ultrasonic.h>
#include <Adafruit_NeoPixel.h>
#include <IRremote.hpp>

#include "../../secrets.h"


#define Ultrasonic_trigger    2
#define Ultrasonic_echo       12
#define Light_sensor_pin      32
#define Infrared_sensor_pin   33
#define Fan_pin               27
#define PIN_NEO_PIXEL         19  
#define NUM_PIXELS            4  
#define IR_pin                26
#define PUMP_Pin              5

#define Button1               0xF30CFF00
#define Button2               0xE718FF00
#define Button3               0xA15EFF00

float temp = 0;
float hum = 0;
int distance = 0;
int light = 0;
int infrared = 0;
bool led_enable = false;
bool fan_enable = false;
bool pump_enable = false;   
#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <ArduinoJson.h>

// WiFi configuration
const char* SSID = "Cá mú";
const char* PASSWORD = "12345678";

// MQTT configuration
const char* MQTT_SERVER = "172.20.10.7";
const int MQTT_PORT = 1883;
const char* MQTT_USER = "";
const char* MQTT_KEY = "";

// Topics
const char* CONFIG_TOPIC = "hamster/config";

// Default IDs - will be updated from config
String userID = "default_user";
String cageID = "default_cage";
String sensorID = "dht11";      
String deviceID = "default_device";

// Dynamic topic strings
char temp_topic[100];
char humid_topic[100];
char command_topic[100];
char status_topic[100];

// Threshold values for automation
float tempThreshold = 30.0;
float humThreshold = 80.0;

// Pin definitions
#define DHTPIN 4
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1  
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

#define LED_PIN 12

// Global variables for sensor data
float temp = 0.0;
float hum = 0.0;
bool ledState = false;

// MQTT client
WiFiClient espClient;
PubSubClient client(espClient);

// Update topic strings based on current IDs
void update_topics() {
  sprintf(temp_topic, "hamster/%s/%s/sensor/%s/temperature", userID.c_str(), cageID.c_str(), sensorID.c_str());
  sprintf(humid_topic, "hamster/%s/%s/sensor/%s/humidity", userID.c_str(), cageID.c_str(), sensorID.c_str());
  sprintf(command_topic, "hamster/%s/%s/device/%s/command", userID.c_str(), cageID.c_str(), deviceID.c_str());
  sprintf(status_topic, "hamster/%s/%s/device/%s/status", userID.c_str(), cageID.c_str(), deviceID.c_str());
  
  Serial.println("[DEBUG] Topics updated:");
  Serial.println(temp_topic);
  Serial.println(humid_topic);
  Serial.println(command_topic);
  Serial.println(status_topic);
}

// Connect to WiFi network
void wifi_connect() {
  Serial.println("[DEBUG] Starting WiFi connection...");
  WiFi.begin(SSID, PASSWORD);
  Serial.println("[DEBUG] Waiting for WiFi to connect...");
  
  int retryCount = 0;
  const int maxRetries = 20;
  
  while (WiFi.status() != WL_CONNECTED && retryCount < maxRetries) {
    delay(500);
    Serial.print(".");
    retryCount++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[DEBUG] WiFi connected!");
    Serial.print("[DEBUG] IP address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n[DEBUG] WiFi connection failed after maximum retries!");
  }
}

// MQTT callback for received messages
void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("[DEBUG] Received from topic: ");
  Serial.println(topic);
  
  // Convert payload to string
  char message[length + 1];
  memcpy(message, payload, length);
  message[length] = '\0';
  
  Serial.print("[DEBUG] Message: ");
  Serial.println(message);

  // Handle configuration messages
  if (String(topic) == CONFIG_TOPIC) {
    // Parse config message format: userID:cageID:deviceID:tempThreshold:humThreshold
    String messageStr = String(message);
    int firstColon = messageStr.indexOf(':');
    int secondColon = messageStr.indexOf(':', firstColon + 1);
    int thirdColon = messageStr.indexOf(':', secondColon + 1);
    int fourthColon = messageStr.indexOf(':', thirdColon + 1);
    
    if (firstColon != -1 && secondColon != -1 && thirdColon != -1 && fourthColon != -1) {
      userID = messageStr.substring(0, firstColon);
      cageID = messageStr.substring(firstColon + 1, secondColon);
      deviceID = messageStr.substring(secondColon + 1, thirdColon);
      tempThreshold = messageStr.substring(thirdColon + 1, fourthColon).toFloat();
      humThreshold = messageStr.substring(fourthColon + 1).toFloat();
      
      Serial.println("[DEBUG] Config updated from backend:");
      Serial.println("userID: " + userID);
      Serial.println("cageID: " + cageID);
      Serial.println("deviceID: " + deviceID);
      Serial.println("tempThreshold: " + String(tempThreshold));
      Serial.println("humThreshold: " + String(humThreshold));
      
      // Update topics with new IDs
      update_topics(); 
      
      // Resubscribe to command topic with new ID
      client.unsubscribe(command_topic); 
      client.subscribe(command_topic);   
      Serial.print("[DEBUG] Subscribed to new command topic: ");
      Serial.println(command_topic);
      
      // Publish device status after config update
      publish_device_status();
    }
  }
  // Handle device commands
  else if (String(topic) == command_topic) {
    if (String(message) == "ON") {
      digitalWrite(LED_PIN, HIGH);
      ledState = true;
      Serial.println("[DEBUG] LED turned ON");
      publish_device_status();
    } else if (String(message) == "OFF") {
      digitalWrite(LED_PIN, LOW);
      ledState = false;
      Serial.println("[DEBUG] LED turned OFF");
      publish_device_status();
    }
  }
}

// Reconnect to MQTT broker
void mqtt_reconnect() {
  int retryCount = 0;
  const int maxRetries = 5;
  
  while (!client.connected() && retryCount < maxRetries) {
    Serial.println("[DEBUG] Attempting MQTT reconnection...");
    
    // Create a random client ID
    String clientID = "ESP32S3Client-";
    clientID += String(random(0xffff), HEX);
    
    Serial.print("[DEBUG] Using client ID: ");
    Serial.println(clientID);
    
    // Attempt to connect
    if (client.connect(clientID.c_str(), MQTT_USER, MQTT_KEY)) {
      Serial.println("[DEBUG] Connected to MQTT broker!");
      
      // Subscribe to topics
      client.subscribe(CONFIG_TOPIC, 1); // QoS 1 for config
      client.subscribe(command_topic, 1); // QoS 1 for commands
      
      Serial.println("[DEBUG] Subscribed to topics:");
      Serial.println(CONFIG_TOPIC);
      Serial.println(command_topic);
      
      // Publish initial status after reconnection
      publish_device_status();
    } else {
      Serial.print("[DEBUG] Failed to connect, rc=");
      Serial.print(client.state());
      Serial.println(" Retrying in 2 seconds...");
      delay(2000);
      retryCount++;
    }
  }
}

// Setup MQTT connection
void mqtt_setup() {
  Serial.println("[DEBUG] Setting up MQTT...");
  
  // Configure MQTT client
  client.setServer(MQTT_SERVER, MQTT_PORT);
  client.setCallback(callback);
  client.setKeepAlive(60);
  client.setSocketTimeout(30);
  
  Serial.println("[DEBUG] MQTT client configured, connecting...");
  mqtt_reconnect();
}

// Read sensor data
void read_DHT11() {
  Serial.println("[DEBUG] Reading DHT11 sensor...");
  temp = dht.readTemperature();
  hum = dht.readHumidity();
  
  if (isnan(temp) || isnan(hum)) {
    Serial.println("[DEBUG] Failed to read from DHT11!");
    temp = 0.0;
    hum = 0.0;
    return;
  }
  
  Serial.printf("[DEBUG] Temp: %.2f°C, Hum: %.2f%%\n", temp, hum);
  
  // Check thresholds for automation
  check_thresholds();
}

// Check temperature and humidity thresholds for automation
void check_thresholds() {
  if (temp > tempThreshold && !ledState) {
    // Automatic cooling on
    digitalWrite(LED_PIN, HIGH);
    ledState = true;
    Serial.println("[DEBUG] Auto: LED turned ON due to high temperature");
    publish_device_status();
  } else if (temp < (tempThreshold - 2) && ledState) {
    // Automatic cooling off (with 2°C hysteresis)
    digitalWrite(LED_PIN, LOW);
    ledState = false;
    Serial.println("[DEBUG] Auto: LED turned OFF due to normal temperature");
    publish_device_status();
  }
  
  // You can add more automation rules for humidity if needed
}

// Publish sensor data to MQTT
void publish_sensor_data(const char* topic, float value, const char* type) {
  // Create JSON document
  StaticJsonDocument<128> doc;
  doc["value"] = value;
  doc["timestamp"] = millis();
  doc["type"] = type;
  
  // Serialize JSON
  char buffer[128];
  serializeJson(doc, buffer);
  
  Serial.print("[DEBUG] Publishing to ");
  Serial.print(topic);
  Serial.print(": ");
  Serial.println(buffer);
  
  // Publish with QoS 0, not retained
  if (client.connected()) {
    if (client.publish(topic, buffer)) {
      Serial.println("[DEBUG] Publish successful");
    } else {
      Serial.println("[DEBUG] Publish failed");
    }
  } else {
    Serial.println("[DEBUG] Skipping publish, MQTT not connected");
  }
}

// Publish device status
void publish_device_status() {
  StaticJsonDocument<128> doc;
  doc["status"] = ledState ? "ON" : "OFF";
  doc["timestamp"] = millis();
  
  char buffer[128];
  serializeJson(doc, buffer);
  
  Serial.print("[DEBUG] Publishing status to ");
  Serial.print(status_topic);
  Serial.print(": ");
  Serial.println(buffer);
  
  // Publish with QoS 1 and retained flag
  if (client.connected()) {
    if (client.publish(status_topic, buffer, true)) {
      Serial.println("[DEBUG] Status publish successful");
    } else {
      Serial.println("[DEBUG] Status publish failed");
    }
  } else {
    Serial.println("[DEBUG] Skipping status publish, MQTT not connected");
  }
}

// Update OLED display with sensor data
void display_data() {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(WHITE);
  
  // User and cage info
  display.setCursor(0, 0);
  display.print("User: ");
  display.println(userID);
  display.print("Cage: ");
  display.println(cageID);
  
  // Temperature and humidity
  display.setCursor(0, 20);
  display.print("Temp: ");
  display.print(temp);
  display.print(" C");
  display.setCursor(0, 30);
  display.print("Hum: ");
  display.print(hum);
  display.print(" %");
  
  // Device status
  display.setCursor(0, 45);
  display.print("Device: ");
  display.print(ledState ? "ON" : "OFF");
  
  // Thresholds
  display.setCursor(0, 55);
  display.print("T_Limit: ");
  display.print(tempThreshold);
  display.print("C");
  
  display.display();
}

// FreeRTOS task for sensor reading and publishing
void Task_read_sensor(void* pvParameters) {
  Serial.println("[DEBUG] Sensor task started...");
  const TickType_t xDelay = 5000 / portTICK_PERIOD_MS;  // 5 seconds delay
  
  while (1) {
    // Check if WiFi is connected, if not, reconnect
    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("[DEBUG] WiFi disconnected, reconnecting...");
      wifi_connect();
    }
    
    // Check if MQTT is connected, if not, reconnect
    if (!client.connected()) {
      Serial.println("[DEBUG] MQTT disconnected, reconnecting...");
      mqtt_reconnect();
    }
    
    // Read sensor data
    read_DHT11();
    
    // Publish data to MQTT
    publish_sensor_data(temp_topic, temp, "temperature");    
    publish_sensor_data(humid_topic, hum, "humidity");    
    
    // Update display
    display_data();
    
    Serial.println("[DEBUG] Task sleeping for 5 seconds...");
    vTaskDelay(xDelay);
  }
}

void setup() {
  // Initialize serial communication
  Serial.begin(115200);
  Serial.println("\n\n[DEBUG] Starting system...");
  
  // Setup GPIO
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  ledState = false;
  
  // Initialize WiFi
  wifi_connect();
  
  // Initialize MQTT
  mqtt_setup();
  
  // Initialize DHT sensor
  Serial.println("[DEBUG] Initializing DHT11...");
  dht.begin();
  Serial.println("[DEBUG] DHT11 initialized");

  // Initialize OLED display
  Serial.println("[DEBUG] Initializing OLED display...");
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println(F("[DEBUG] SSD1306 allocation failed"));
    for (;;);  // Don't proceed, loop forever
  }
  
  // Show initial message on display
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(WHITE);
  display.setCursor(0, 0);
  display.println("Hamster Monitor");
  display.println("Initializing...");
  display.display();
  delay(2000);
  
  // Set initial topics
  update_topics();
  
  // Create sensor reading task on core 0
  Serial.println("[DEBUG] Creating sensor task...");
  xTaskCreatePinnedToCore(
    Task_read_sensor,    // Task function
    "Task_read_sensor",  // Name
    8192,                // Stack size (increased for JSON handling)
    NULL,                // Parameters
    1,                   // Priority
    NULL,                // Task handle
    0);                  // Core (0)
  
  Serial.println("[DEBUG] Setup completed!");
}

void loop() {
  // Main loop on core 1
  client.loop();  // Process MQTT messages
  
  // Keep WDT happy
  delay(10);
}
#include <yolobit.h>

WiFiClient espClient;
PubSubClient client(espClient);
DHT20 dht20;
LiquidCrystal_I2C lcd(0x21, 16, 2);
Ultrasonic ultrasonic(Ultrasonic_trigger, Ultrasonic_echo);
Adafruit_NeoPixel NeoPixel(NUM_PIXELS, PIN_NEO_PIXEL, NEO_GRB + NEO_KHZ800);

void wifi_connect() {
  Serial.print("Connected to WiFi.");
  delay(10);
  WiFi.begin(SSID, PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("WiFi connected!");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

void mqtt_setup() {
  client.setServer(MQTT_SERVER, MQTT_PORT);
  client.setCallback(callback_mqtt);

  Serial.println("Connected to MQTT server...");
  while (!client.connected()) {
    String clientID = "YolobitClient-";
    clientID += String(random(0xffff), HEX);
    if (client.connect(clientID.c_str(), MQTT_USER, MQTT_KEY)) {
      Serial.println("connected");
    } else {
      Serial.print("Failed with state ");
      Serial.println(client.state());
      delay(2000);
    }
  }

  for (int i = 0; i < 8; i++) {
    client.subscribe(MQTT_TOPIC[i]);
  }
}

void callback_mqtt(char *topic, byte *payload, unsigned int length) {
  StaticJsonDocument<192> doc;
  DeserializationError error = deserializeJson(doc, payload, length);

  if (error) {
    Serial.print("Lỗi khi parse JSON: ");
    Serial.println(error.c_str());
    return;
  }

  const char *dataname = doc["dataname"];
  float value = doc["value"];

  // Serial.println(MQTT_TOPIC[5]);
  // Serial.println(topic);
  // Kiểm tra nếu topic không phải là fan, led, hoặc pump thì bỏ qua
  if (strcmp(topic, MQTT_TOPIC[5]) != 0 &&
      strcmp(topic, MQTT_TOPIC[6]) != 0 &&
      strcmp(topic, MQTT_TOPIC[7]) != 0) {
    return;
  }

  Serial.print("Nhận dữ liệu từ topic: ");
  Serial.println(topic);
  Serial.print("Dataname: ");
  Serial.println(dataname);
  Serial.print("Value: ");
  Serial.println(value);

  if (strcmp(dataname, "fan") == 0) {
    //Serial.println(value);
    if (value == 0) {
      digitalWrite(Fan_pin, LOW);
      fan_enable = false;
    } else if (value == 1) {
      //Serial.println("here");
      digitalWrite(Fan_pin, HIGH);
      fan_enable = true;
    }
  }

  else if (strcmp(dataname, "led") == 0) {
    if (value == 0) {
      NeoPixel.clear();
      NeoPixel.show();
      led_enable = false;
    } else if (value == 1) {
      for (int pixel = 0; pixel < NUM_PIXELS; pixel++) {
        NeoPixel.setPixelColor(pixel, NeoPixel.Color(0, 0, 255));
      }
      NeoPixel.show();
      led_enable = true;
    }
  }

  else if (strcmp(dataname, "pump") == 0) {
    if (value == 0) {
      digitalWrite(PUMP_Pin, LOW);
      pump_enable = false;
    } else if (value == 1) {
      digitalWrite(PUMP_Pin, HIGH);
      pump_enable = true;
    }
  }
}


void read_DHT20() {
  dht20.read();
  float t = dht20.getTemperature();
  float h = dht20.getHumidity();

  //Serial.printf("Temp: %.2f°C, Hum: %.2f%%\n", temp, hum);
  temp = t;
  hum = h;
}

void read_Ultrasonic() {
  distance = ultrasonic.read();
}

void read_LightSensor() {
  light = analogRead(Light_sensor_pin);
}

void read_InfraredSensor() {
  infrared = digitalRead(Infrared_sensor_pin);
}

void write_LCD() {
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print(temp);
  lcd.setCursor(10, 0);
  lcd.print(hum);
  lcd.setCursor(0, 1);
  lcd.print(light);
  lcd.setCursor(10, 1);
  lcd.print(distance);
}

void Task_read_sensor(void *pvParameters) {
  while (1) {
    read_DHT20();
    read_Ultrasonic();
    read_LightSensor();
    read_InfraredSensor();

    //Serial.printf("Temp: %.2f°C, Hum: %.2f%%\n", temp, hum);
    send_mqtt(MQTT_TOPIC[0], temp, "sensor", 1, "temperature");
    send_mqtt(MQTT_TOPIC[1], hum, "sensor", 2, "huminity");
    send_mqtt(MQTT_TOPIC[2], (float)light, "sensor", 3, "light");
    send_mqtt(MQTT_TOPIC[3], (float)distance, "sensor", 4, "waterlevel");
    send_mqtt(MQTT_TOPIC[4], (float)infrared, "sensor", 5, "infrared");

    write_LCD();
    vTaskDelay(30000 / portTICK_PERIOD_MS);
  }
}

void send_mqtt(const char *topic, float value, const char *type, int id, const char *dataname) {
  StaticJsonDocument<192> doc;

  doc["username"] = "user1";
  doc["cagename"] = "cage1";
  doc["type"] = type;
  doc["id"] = id;
  doc["dataname"] = dataname;
  doc["value"] = value;
  doc["time"] = millis();

  char buffer[192];
  serializeJson(doc, buffer);
  client.publish(topic, buffer);
}

void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  Wire.begin();
  wifi_connect();
  mqtt_setup();

  lcd.init();
  dht20.begin();
  NeoPixel.begin();
  IrReceiver.begin(IR_pin, ENABLE_LED_FEEDBACK);

  pinMode(Fan_pin, OUTPUT);
  pinMode(PUMP_Pin, OUTPUT);


  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("0");
  lcd.setCursor(5, 0);
  lcd.print("C");
  lcd.setCursor(10, 0);
  lcd.print("0");
  lcd.setCursor(14, 0);
  lcd.print("%");
  lcd.setCursor(0, 1);
  lcd.print("0");
  lcd.setCursor(4, 1);
  lcd.print("lx");
  lcd.setCursor(10, 1);
  lcd.print("0");
  lcd.setCursor(14, 1);
  lcd.print("cm");

  xTaskCreatePinnedToCore(Task_read_sensor, "Task_read_sensor", 4096, NULL, 1, NULL, 0);
}



void loop() {
  // put your main code here, to run repeatedly:

  client.loop();
  if (IrReceiver.decode()) {
    
    Serial.print("Raw data: ");
    Serial.println(IrReceiver.decodedIRData.decodedRawData, HEX); 
    if (IrReceiver.decodedIRData.decodedRawData == Button1) {
      Serial.println("fuck");
      if (fan_enable) {
        digitalWrite(Fan_pin, LOW);
      } else {
        digitalWrite(Fan_pin, HIGH);
      }
      fan_enable = !fan_enable;
      send_mqtt(MQTT_TOPIC[5], fan_enable, "device", 1, "fan");
    } else if (IrReceiver.decodedIRData.decodedRawData == Button2) {
      if (led_enable) {
        NeoPixel.clear();
        NeoPixel.show();
      } else {
        for (int pixel = 0; pixel < NUM_PIXELS; pixel++) {
          NeoPixel.setPixelColor(pixel, NeoPixel.Color(0, 255, 0));
        }
        NeoPixel.show();
      }

      led_enable = !led_enable;
      send_mqtt(MQTT_TOPIC[6], led_enable, "device", 2, "led");
    } else if (IrReceiver.decodedIRData.decodedRawData == Button3) {
      if (pump_enable) {
        digitalWrite(PUMP_Pin, LOW);
      } else {
        digitalWrite(PUMP_Pin, HIGH);
      }

      pump_enable = !pump_enable;
      send_mqtt(MQTT_TOPIC[7], pump_enable, "device", 3, "pump");
    }
    IrReceiver.resume();
  }
}

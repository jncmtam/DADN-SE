#ifndef CONFIG_H
#define CONFIG_H

// WiFi credentials
const char *SSID =  "K4li";
const char *PASSWORD = "hackerdethuong";

// MQTT server configuration
const char *MQTT_SERVER = "172.20.10.8";
const int MQTT_PORT = 1883;
const char *MQTT_USER = "";
const char *MQTT_KEY = "";

const char* MQTT_TOPIC[] = {
    "hamster/user1/cage1/sensor/00000000-0000-0000-0000-000000000001/temperature",
    "hamster/user1/cage1/sensor/00000000-0000-0000-0000-000000000002/humidity",
    "hamster/user1/cage1/sensor/00000000-0000-0000-0000-000000000003/light",
    "hamster/user1/cage1/sensor/00000000-0000-0000-0000-000000000004/water-level",
    "hamster/user1/cage1/device/00000000-0000-0000-0000-000000000005/fan",
    "hamster/user1/cage1/device/00000000-0000-0000-0000-000000000006/led",
    "hamster/user1/cage1/device/00000000-0000-0000-0000-000000000007/pump",
};

#endif // SECRETS_H
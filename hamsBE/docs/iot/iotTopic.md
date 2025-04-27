# Topic name

## Description

    Format of topic: `hamster/{user_id}/{cage_id}/{type}/{id}/{type of data}`

    - `user_id`: ID of the user
    - `cage_id`: ID of the cage
    - `type`: device or sensor
    - `id`: ID of the device or sensor
    - `type of data`: data type of the device or sensor (temperature, humidity, light, etc.)

    ## Topic list

    **Example: User_id = 1, cage_id = 1,**

    - `hamster/1/1/sensor/1/temperature`: Temperature of sensor 1
    - `hamster/1/1/sensor/2/humidity`: Humidity of sensor 2
    - `hamster/1/1/sensor/3/light`: Light of sensor 3
    - `hamster/1/1/sensor/4/infrared`: Infrared of sensor 4
    - `hamster/1/1/sensor/5/distance`: Distance of sensor 5

    - `hamster/1/1/device/1/led`: LED of device 1
    - `hamster/1/1/device/2/fan`: Fan of device 2
    - `hamster/1/1/device/3/pump`: Pump of device 3

    ## Format of data

    **Sensor** : float

    - temperature: `float` (°C)
    - humidity: `float` (%)
    - light: `float` (lux)
    - infrared: `boolean` (`1`: detected hamster, `0`: not detected hamster)
    - distance: `float` (cm)

**Device** : boolean

- `1`: on
- `0`: off

### Instruction

- The data of the sensor will be sent to the topic `hamster/{user_id}/{cage_id}/sensor/{sensor_id}/{type of data}`.

- The data of the device will be sent to the topic `    .

- Use method `StartMQTTClientSub` to subscribe to the topic.

- Use method `StartMQTTClientPub` to publish data to the topic.

**Note**: The data of sensor will only be sent from the device to the server. The data of the device can be sent both from the server to the device and from the device to the server. So the app must subscribe to the topic of the device to receive the data from the device and publish the data to the topic of the device to send the data to the device. The application must synchronize with the device by subscribing to the device topic and publishing data to the device topic.

Pub commnad line

```sh
mosquitto_pub -h localhost -t "hamster/1/1/sensor/1/temperature" -m "25.5"
```

Sub command line

````sh
mosquitto_sub -h localhost -t "hamster/1/1/sensor/1/temperature"```
````

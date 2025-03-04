# MULTI-DISCIPLINARY PROJECT
### TOPIC : HAMSTER CARE MOBILE APP
### GROUP NAME : 6 hours sleep
## GROUP INFORMATION

| No. | Name                  | Role     |
|-----|-----------------------|----------|
| 1   | Đoàn Ngọc Hoàng Sơn  | Frontend |
| 2   | Thịnh Trần Khánh Linh | Frontend |
| 3   | Chu Minh Tâm         | Backend - PO|
| 4   | Trần Quang Tác       | Backend  |
| 5   | Mai Hải Sơn          | Backend  |

### Project Introduction
The demand for pet ownership has been steadily increasing, encompassing not only traditional pets
like dogs and cats but also a variety of newer, unconventional choices. Among these, hamsters have gained
popularity due to their small size and adorable appearance. As a result, they are now widely available
in pet stores, with some shops even specializing exclusively in hamsters.
</br>
However, raising hamsters comes with significant challenges. These small animals are highly sus-
ceptible to illness and require strict environmental conditions to thrive. Pet shop owners and breeders
often invest heavily in specialized equipment to maintain optimal living conditions. Despite these efforts,
much of the monitoring and care still rely on human intervention. Given the delicate nature of hamsters,
even a minor oversight can lead to severe consequences, placing immense pressure on caretakers.
</br>
To address this issue, we propose the development of a smart system that automates the monitoring
and regulation of key environmental factors such as temperature, humidity, and lighting. Additionally,
this system will provide real-time data on habitat conditions and enable remote control of various aspects
of hamster care, ensuring a healthier and more sustainable environment for these pets.
### Feature 
#### Environmental Monitoring and Adjustment
The system must utilize sensors to measure temperature, humidity, light levels, and water levels, then transmit the data to the backend.

- When data exceeds predefined thresholds, the system must automatically activate the appropriate devices:
  - If the temperature exceeds 30°C, the system must turn on a mini fan for cooling.
  - If the light level is insufficient, the system must turn on an LED light to ensure adequate illumination.
- The data collected must be stored for trend analysis and environmental assessment.

#### Food and Water Supply System
- The system must dispense food according to a predefined schedule.
- When the sensor detects a low water level, the system must automatically replenish the water supply.
- Users must be able to remotely dispense food or add water via the Web/Mobile application.

#### Alerts & Remote Control
- When an issue arises (e.g., high temperature, insufficient light, low water level), the system must send alerts to the Web/Mobile application and display them on an LCD screen.
- Users must be able to remotely control devices, including turning on/off the fan, LED light, water pump, or food dispenser via the application.
- The system must support two control modes:
  - **Automatic Mode**: Devices operate based on sensor data.
  - **Manual Mode**: Users can manually control devices when needed.
### Tech Stack

- `Gin Framwork (Golang)` <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/go/go-original.svg" width="40" />
- `Postgres` <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/postgresql/postgresql-original.svg" width="40" />
- `Docker`<img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/docker/docker-original.svg" width="40" />
- `GitAction` <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/github/github-original.svg" width="40" />
- `MQTT broker` <img src="https://upload.wikimedia.org/wikipedia/commons/3/3b/MQTT_logo.svg" width="40" />

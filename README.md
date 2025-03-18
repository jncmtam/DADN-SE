# MULTI-DISCIPLINARY PROJECT

## <span style="color:#007bff;">TOPIC: HAMSTER CARE MOBILE APP</span>

### <span style="color:#007bff;">GROUP NAME: `NUMBER ONE`</span>

## <span style="color:#007bff;">GROUP INFORMATION</span>

| No. | Name                  | Role         |
| --- | --------------------- | ------------ |
| 1   | Đoàn Ngọc Hoàng Sơn   | Frontend     |
| 2   | Thịnh Trần Khánh Linh | Frontend     |
| 3   | Chu Minh Tâm          | Backend - PO |
| 4   | Trần Quang Tác        | Backend      |
| 5   | Mai Hải Sơn           | Backend      |

---

## <span style="color:#007bff;">Project Introduction</span>

The demand for pet ownership has been steadily increasing, encompassing not only traditional pets like dogs and cats but also a variety of unconventional choices. Among these, hamsters have gained popularity due to their small size and adorable appearance. They are now widely available in pet stores, with some shops specializing exclusively in hamsters.

However, raising hamsters comes with significant challenges. These small animals are highly susceptible to illness and require strict environmental conditions to thrive. Pet shop owners and breeders often invest heavily in specialized equipment to maintain optimal living conditions. Despite these efforts, much of the monitoring and care still rely on human intervention. Even a minor oversight can lead to severe consequences, placing immense pressure on caretakers.

To address this issue, we propose the development of a **smart system** that automates the monitoring and regulation of key environmental factors such as **temperature**, **humidity**, and **lighting**. Additionally, this system will provide **real-time data** on habitat conditions and enable **remote control** of various aspects of hamster care, ensuring a healthier and more sustainable environment for these pets.

---

## <span style="color:#007bff;">Features</span>

### 1. Environmental Monitoring and Adjustment

The system will utilize sensors to measure:

- Temperature
- Humidity
- Light levels
- Water levels

The data will be transmitted to the backend, and when thresholds are exceeded:

- Temperature > 30°C → **Mini fan activates**
- Low Light Levels → **LED light activates**

Collected data will be stored for **trend analysis** and **environmental assessment**.

### 2. Food and Water Supply System

- Automatic food dispensing according to schedule.
- Automatic water replenishment when **low water level** is detected.
- Remote control to dispense food and refill water via the **Web/Mobile application**.

### 3. Alerts & Remote Control

- System sends **alerts** for:
  - High temperature
  - Low light
  - Low water level
- Alerts will be displayed on:
  - Web/Mobile application
  - LCD Screen
- Control Modes:
  - **Automatic Mode**: Operates based on sensor data.
  - **Manual Mode**: Users manually control devices.

---

## <span style="color:#007bff;">Tech Stack</span>

| Technology             | Icon                                                                                                           |
| ---------------------- | -------------------------------------------------------------------------------------------------------------- |
| Gin Framework          | <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/go/go-original.svg" width="40" />                 |
| Postgres               | <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/postgresql/postgresql-original.svg" width="40" /> |
| Docker                 | <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/docker/docker-original.svg" width="40" />         |
| GitHub Actions         | <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/github/github-original.svg" width="40" />         |
| MQTT Broker (Adafruit) |                                                                                                                |

---

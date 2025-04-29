# HamsterCare - Installation Guide

This guide explains how to set up and run **HamsterCare** (both **Frontend** and **Backend**) on your local machine.

## Prerequisites
Before you begin, make sure you have the following installed:

- **Go (Golang)**: Version 1.23.0 or later
- **PostgreSQL**: Needed to store hamster data

---

## Step 1: Clone the Repository

Clone both the **Frontend** and **Backend** repositories to your local machine:

```bash
git clone https://github.com/jncmtam/DADN-SE.git
```

---

## Frontend Installation

### Step 1: Install Flutter

Ensure you have Flutter (version 3.5.3 or later) installed on your system. If not, follow the official Flutter installation guide for your operating system at https://flutter.dev/docs/get-started/install

Verify your installation:
```bash
flutter --version
```

### Step 2: Navigate to Frontend Directory

```bash
cd hamsFE
```

### Step 3: Install Dependencies

Install all required packages:
```bash
flutter pub get
```

Key dependencies include:
- google_fonts
- flutter_svg
- http
- flutter_secure_storage
- web_socket_channel
- fl_chart
- flutter_local_notifications
- image_picker

### Step 4: Configure Environment

The app is configured to connect to the backend at `localhost:8080`. If you need to modify this:
1. Open `lib/views/constants.dart`
2. Update the `apiUrl` constant with your backend URL

### Step 5: Run the Application

For development:
```bash
flutter run
```

This will launch the app on your connected device or emulator.

Supported platforms:
- Android
- iOS
- Web
- macOS
- Linux
- Windows

Note: For iOS and macOS development, ensure you have Xcode installed and CocoaPods dependencies are up to date:
```bash
cd ios/ # or macos/
pod install
```

---

## Backend Installation

### Step 1: Install Go Dependencies

```bash
cd hamsBE
go mod tidy
```

### Step 2: Configure DB and Environment Variables

Create or modify the `.env` file with your configuration details. Example of `.env` configuration:

```bash
# Go
PORT=8080

# Postgre config
DB_HOST=localhost
DB_PORT=5432
DB_USER=hamster
DB_PASSWORD=hamster
DB_NAME=hamster

JWT_SECRET_KEY=<your_jwt_secret_key>

# Địa chỉ MQTT Broker server (ví dụ: 10.28.129.171:1883 hoặc mqtt.example.com:1883)
MQTT_BROKER=<your_mqtt_broker_address>

# Email dùng để gửi email notification và OTP
EMAIL=<your_email_address>

# API Key của SendGrid để gửi email
SENDGRID_API_KEY=<your_sendgrid_api_key>


```

### Step 3: Run the Server

Using Go:

```bash
go run main.go
```

For hot-reload with **air**:

```bash
air
```

(Optional) Using Docker:

```bash
docker-compose up --build
```

---

This will start the backend server, which will be accessible at `http://localhost:8080`.


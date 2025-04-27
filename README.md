# .env 

```bash
# Go
PORT=8080

# Postgre config
DB_HOST=localhost
DB_PORT=5432
DB_USER=hamster
DB_PASSWORD=hamster
DB_NAME=hamster

# Adafruit config
```
# Cách chạy server 
- Thay vì dùng `go run main.go`
- Dùng lệnh `air` để hot Reload
- Dùng `docker compose`



---

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
cd hamstercare
```

---

## Frontend Installation

*(Frontend setup instructions)*

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

# Adafruit config
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


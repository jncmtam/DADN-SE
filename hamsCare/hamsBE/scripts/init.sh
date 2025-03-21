#!/bin/bash

# Đường dẫn tới file .env (từ internal/database lên 2 cấp tới thư mục gốc)
ENV_FILE="../../.env"

# Kiểm tra và đọc file .env
if [ -f "$ENV_FILE" ]; then
    echo "Loading environment variables from $ENV_FILE..."
    # Loại bỏ comment và xuất các biến môi trường
    set -a # Tự động export tất cả biến được định nghĩa
    source "$ENV_FILE"
    set +a
else
    echo "Warning: $ENV_FILE not found. Using default values or existing environment variables."
fi

# Thông tin kết nối database (lấy từ biến môi trường hoặc giá trị mặc định)
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_USER=${DB_USER:-hamster}
DB_PASSWORD=${DB_PASSWORD:-hamster}
DB_NAME=${DB_NAME:-hamster}

# Đường dẫn tới thư mục migrations và seed (tương đối từ internal/database)
MIGRATIONS_DIR="./migrations"
SEED_DIR="./seed"

# Hàm kiểm tra kết nối PostgreSQL
wait_for_postgres() {
    echo "Waiting for PostgreSQL to be ready at $DB_HOST:$DB_PORT..."
    until PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "postgres" -c '\q' 2>/dev/null; do
        echo "PostgreSQL is unavailable - sleeping..."
        sleep 1
    done
    echo "PostgreSQL is ready!"
}

# Tạo database nếu chưa tồn tại
create_database() {
    echo "Checking if database $DB_NAME exists..."
    DB_EXISTS=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "postgres" -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'")
    if [ "$DB_EXISTS" != "1" ]; then
        echo "Creating database $DB_NAME..."
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "postgres" -c "CREATE DATABASE $DB_NAME;"
    else
        echo "Database $DB_NAME already exists."
    fi
}

# Chạy các file migration
run_migrations() {
    echo "Running migrations from $MIGRATIONS_DIR..."
    for file in "$MIGRATIONS_DIR"/*up.sql; do
        if [ -f "$file" ]; then
            echo "Applying $file..."
            PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$file"
        fi
    done
    echo "Migrations completed!"
}

# Chạy seed dữ liệu (tùy chọn)
run_seed() {
    echo "Running seed data from $SEED_DIR..."
    for file in "$SEED_DIR"/*.sql; do
        if [ -f "$file" ]; then
            echo "Applying $file..."
            PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$file"
        fi
    done
    echo "Seed data completed!"
}

# Thực thi các bước
wait_for_postgres
create_database
run_migrations
run_seed

echo "Database initialization completed!"
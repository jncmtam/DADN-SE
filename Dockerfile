# Stage 1: Build ứng dụng Golang
FROM --platform=$BUILDPLATFORM golang:1.23-alpine AS builder

# Thiết lập thư mục làm việc
WORKDIR /app

# Copy go.mod và go.sum để tải dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy toàn bộ mã nguồn
COPY . .

# Build ứng dụng, tự động nhận diện kiến trúc mục tiêu
ARG TARGETPLATFORM
RUN GOARCH=$(echo ${TARGETPLATFORM} | cut -d '/' -f2) \
    CGO_ENABLED=0 GOOS=linux go build -o /app/main ./main.go

# Stage 2: Tạo image nhỏ gọn để chạy
FROM --platform=$TARGETPLATFORM alpine:latest

# Cài đặt các công cụ cần thiết (psql cho init.sh)
RUN apk add --no-cache postgresql-client bash

# Thiết lập thư mục làm việc
WORKDIR /app

# Copy file binary từ stage builder
COPY --from=builder /app/main .
RUN chmod +x /app/main

# Copy các file cần thiết để chạy migration và seed
COPY internal/database/migrations /app/internal/database/migrations
COPY internal/database/queries /app/internal/database/queries
COPY .env /app/.env

# Command để chạy ứng dụng
CMD ["/app/main"]


# Build 
# docker buildx build --platform linux/amd64,linux/arm64 -t hamster:latest .
# docker buildx build --platform linux/amd64 -t hamster:latest .
# docker buildx build --platform linux/arm64 -t hamster:latest .

# docker run -d --name hamsbe -p 8080:8080 hamster

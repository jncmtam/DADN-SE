# Stage 1: Build the Go application
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Copy go.mod and go.sum to leverage Docker cache
COPY go.mod go.sum ./
RUN go mod download

# Copy the source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o hamsBE ./main.go

# Stage 2: Create a minimal runtime image
FROM alpine:latest

WORKDIR /app

# Copy the binary from the builder stage
COPY --from=builder /app/hamsBE .
# Copy public assets (avatars)
COPY public ./public

# Expose port for API and WebSocket (adjust if different)
EXPOSE 8080

# Command to run the application
CMD ["./hamsBE"]
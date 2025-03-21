# Cấu trúc thư mục dự án HamsBE

## Thư mục gốc

| Tên file/thư mục     | Công dụng                                                                   |
| -------------------- | --------------------------------------------------------------------------- |
| `api/`               | Chứa logic định tuyến và handler API (Controller trong MVC).                |
| `cmd/`               | Chứa entry point của ứng dụng (điểm khởi chạy chính).                       |
| `database/`          | Quản lý cơ sở dữ liệu (migrations, seed data, kết nối DB).                  |
| `docs/`              | Chứa tài liệu dự án (API docs, biểu đồ ER).                                 |
| `internal/`          | Chứa logic nội bộ của ứng dụng (cache, model, mqtt, repository, ...).       |
| `middleware/`        | Chứa các middleware (xác thực, logging, ...).                               |
| `scripts/`           | (Hiện trống) Chứa các script hỗ trợ (deploy, test, ...).                    |
| `.env`               | File cấu hình môi trường (DB, Redis, MQTT, ...).                            |
| `.gitignore`         | Danh sách các file/thư mục bỏ qua khi commit Git.                           |
| `Makefile`           | Script tự động hóa build, test, hoặc chạy ứng dụng.                         |
| `README.md`          | Tài liệu giới thiệu và hướng dẫn dự án.                                     |
| `docker-compose.yml` | Cấu hình Docker Compose để chạy ứng dụng và các dịch vụ (DB, Redis, ...).   |
| `dockerfile`         | Cấu hình build Docker image cho ứng dụng.                                   |
| `go.mod`             | File quản lý dependency của Go modules.                                     |
| `go.sum`             | File kiểm tra tính toàn vẹn của dependency.                                 |

## Thư mục `api/`

| Tên file/thư mục | Công dụng                                             |
| ---------------- | ----------------------------------------------------- |
| `admin/`         | Chứa handler API cho các chức năng quản trị (admin).  |
| `user/`          | Chứa handler API cho các chức năng người dùng (user). |
| `router.go`      | Định nghĩa các route API và gắn handler tương ứng.    |

## Thư mục `cmd/`

| Tên file/thư mục | Công dụng                                                               |
| ---------------- | ----------------------------------------------------------------------- |
| `main.go`        | Entry point của ứng dụng, khởi tạo các thành phần (DB, MQTT, API, ...). |

## Thư mục `database/`

| Tên file/thư mục                             | Công dụng                                                         |
| -------------------------------------------- | ----------------------------------------------------------------- |
| `migrations/`                                | Chứa các file SQL để thay đổi schema cơ sở dữ liệu theo thứ tự.   |
| `migrations/001_create_users.sql`            | Tạo bảng `users`.                                                 |
| `migrations/002_create_cages.sql`            | Tạo bảng `cages`.                                                 |
| `migrations/003_create_sensors.sql`          | Tạo bảng `sensors`.                                               |
| `migrations/004_create_devices.sql`          | Tạo bảng `devices`.                                               |
| `migrations/005_create_automation_rules.sql` | Tạo bảng `automation_rules`.                                      |
| `migrations/006_create_notifications.sql`    | Tạo bảng `notifications`.                                         |
| `seed/`                                      | Chứa các file SQL để tạo dữ liệu mẫu (seed data).                 |
| `seed/seed_cage.sql`                         | Chèn dữ liệu mẫu cho bảng `cages`.                                |
| `seed/seed_user.sql`                         | Chèn dữ liệu mẫu cho bảng `users`.                                |
| `connectDB.go`                               | Logic kết nối và cấu hình cơ sở dữ liệu (PostgreSQL, MySQL, ...). |
| `init.sh`                                    | Script khởi tạo cơ sở dữ liệu (chạy migrations, seed, ...).       |
| `schema.sql`                                 | (Có thể) Tổng hợp toàn bộ schema hiện tại hoặc khởi tạo ban đầu.  |

## Thư mục `docs/`

| Tên file/thư mục | Công dụng                                                           |
| ---------------- | ------------------------------------------------------------------- |
| `api.md`         | Tài liệu mô tả các endpoint API (cách dùng, request/response).      |
| `erd.puml`       | Biểu đồ ER (Entity-Relationship) của cơ sở dữ liệu (dùng PlantUML). |

## Thư mục `internal/`

| Tên file/thư mục  | Công dụng                                                        |
| ----------------- | ---------------------------------------------------------------- |
| `cache/`          | Quản lý logic cache (Redis).                                     |
| `cache/cache.go`  | Interface và method chung cho cache (Get, Set, Delete, ...).     |
| `cache/redis.go`  | Kết nối và cấu hình Redis client.                                |
| `config/`         | Chứa logic đọc cấu hình (từ `.env`, constants, ...).             |
| `model/`          | Định nghĩa các struct dữ liệu (User, Cage, Sensor, ...).         |
| `mqtt/`           | Quản lý logic kết nối và xử lý dữ liệu từ MQTT (Adafruit IO).    |
| `mqtt/client.go`  | Kết nối và cấu hình MQTT client với Adafruit IO.                 |
| `mqtt/handler.go` | Xử lý message từ các topic/feed MQTT (temperature, status, ...). |
| `mqtt/mqtt.go`    | Interface và khởi tạo MQTT client để tích hợp với các tầng khác. |
| `repository/`     | Chứa logic truy vấn cơ sở dữ liệu (Model trong MVC).             |
| `service/`        | Chứa logic nghiệp vụ (business logic) của ứng dụng.              |
| `util/`           | Chứa các hàm tiện ích chung (helper functions).                  |

## Thư mục `middleware/`

| Tên file/thư mục      | Công dụng                                                            |
| --------------------- | -------------------------------------------------------------------- |
| (Chưa có file cụ thể) | Chứa các middleware như xác thực (auth), logging, rate limiting, ... |

## Thư mục `scripts/`

| Tên file/thư mục | Công dụng                                                              |
| ---------------- | ---------------------------------------------------------------------- |
| (Hiện trống)     | Chứa các script hỗ trợ (deploy, test, backup, ...), hiện chưa sử dụng. |

---


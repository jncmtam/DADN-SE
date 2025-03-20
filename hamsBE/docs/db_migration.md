# 📌 Tổng hợp lệnh `migrate` (golang-migrate)

| STT | Lệnh                                                                                                                               | Mô tả                                              |
| --- | ---------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| 1️⃣  | `migrate create -ext sql -dir internal/database/migrations -seq create_users_table`                                                | Tạo file migration mới                             |
| 2️⃣  | `migrate -path internal/database/migrations -database "postgres://hamster:hamster@localhost:5432/hamster?sslmode=disable" up`      | Chạy migration                                     |
| 3️⃣  | `migrate -path internal/database/migrations -database "postgres://hamster:hamster@localhost:5432/hamster?sslmode=disable" down`    | Rollback migration mới nhất                        |
| 4️⃣  | `migrate -path internal/database/migrations -database "postgres://hamster:hamster@localhost:5432/hamster?sslmode=disable" down 2`  | Rollback 2 bước                                    |
| 5️⃣  | `migrate -path internal/database/migrations -database "postgres://hamster:hamster@localhost:5432/hamster?sslmode=disable" version` | Kiểm tra version hiện tại                          |
| 6️⃣  | `migrate -path internal/database/migrations -database "postgres://hamster:hamster@localhost:5432/hamster?sslmode=disable" goto 3`  | Chuyển database đến version 3                      |
| 7️⃣  | `migrate -path internal/database/migrations -database "postgres://hamster:hamster@localhost:5432/hamster?sslmode=disable" force 1` | Fix lỗi "Dirty database version" (ép về version 1) |
| 8️⃣  | `migrate -path internal/database/migrations -database "postgres://hamster:hamster@localhost:5432/hamster?sslmode=disable" drop`    | ** Xóa toàn bộ database**                          |

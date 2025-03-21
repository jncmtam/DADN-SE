
---

```markdown
# User API Documentation

## Base URL
```
http://localhost:8080/api
```

## Headers Chung
- `Content-Type: application/json` (cho tất cả các request gửi JSON)
- `Authorization: Bearer <token>` (cho các endpoint yêu cầu xác thực JWT)

---

## 1. [Admin] Đăng ký người dùng (Register)
- **Endpoint**: `/admin/auth/register`
- **Method**: `POST`
- **Mô tả**: Tạo một người dùng mới trong hệ thống (yêu cầu quyền admin).
- **Headers**:
  - `Authorization: Bearer <token>` (token của admin)
- **Request Body**:
  ```json
  {
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123",
    "role": "user"
  }

---

## 2. Đăng nhập (Login)
- **Endpoint**: `/auth/login`
- **Method**: `POST`
- **Mô tả**: Đăng nhập và nhận JWT token.
- **Request Body**:
  ```json
  {
    "email": "test@example.com",
    "password": "password123"
  }
  ```
- **Response**:
  - **Thành công (200 OK)**:
    ```json
    {
      "token": "jwt-token-string"
    }
    ```
  - **Lỗi (400 Bad Request)**:
    ```json
    {
      "error": "invalid request"
    }
    ```
  - **Lỗi (401 Unauthorized)**:
    ```json
    {
      "error": "Invalid credentials"
    }
    ```

---

## 3. Tạo OTP (Create OTP)
- **Endpoint**: `/otp/create`
- **Method**: `POST`
- **Mô tả**: Tạo mã OTP cho người dùng để xác minh email.
- **Request Body**:
  ```json
  {
    "user_id": "some-uuid"
  }
  ```
- **Response**:
  - **Thành công (200 OK)**:
    ```json
    {
      "otp_code": "123456",
      "expires_at": "2025-03-18T12:00:00Z"
    }
    ```
  - **Lỗi (400 Bad Request)**:
    ```json
    {
      "error": "Invalid request"
    }
    ```
  - **Lỗi (500 Internal Server Error)**:
    ```json
    {
      "error": "Failed to create OTP"
    }
    ```

---

## 4. Xác minh OTP (Verify OTP)
- **Endpoint**: `/otp/verify`
- **Method**: `POST`
- **Mô tả**: Xác minh mã OTP và đánh dấu email của người dùng là đã xác thực.
- **Request Body**:
  ```json
  {
    "user_id": "some-uuid",
    "otp_code": "123456"
  }
  ```
- **Response**:
  - **Thành công (200 OK)**:
    ```json
    {
      "message": "Email verified successfully"
    }
    ```
  - **Lỗi (400 Bad Request)**:
    ```json
    {
      "error": "Invalid request"
    }
    ```
  - **Lỗi (401 Unauthorized)**:
    ```json
    {
      "error": "Invalid or expired OTP"
    }
    ```

---

## 5. Lấy thông tin người dùng (User - Get User by ID)
- **Endpoint**: `/user/:id`
- **Method**: `GET`
- **Mô tả**: Lấy thông tin chi tiết của một người dùng (yêu cầu JWT).
- **Headers**:
  - `Authorization: Bearer <token>`
- **URL Example**: `/user/some-uuid`
- **Response**:
  - **Thành công (200 OK)**:
    ```json
    {
      "id": "some-uuid",
      "username": "testuser",
      "email": "test@example.com",
      "password_hash": "...",
      "role": "user",
      "is_email_verified": true,
      "created_at": "2025-03-18T10:00:00Z",
      "updated_at": "2025-03-18T10:00:00Z"
    }
    ```
  - **Lỗi (401 Unauthorized)**:
    ```json
    {
      "error": "Unauthorized"
    }
    ```
  - **Lỗi (404 Not Found)**:
    ```json
    {
      "error": "User not found"
    }
    ```

---

## 6. Lấy thông tin người dùng (Admin - Get User by ID)
- **Endpoint**: `/admin/users/:id`
- **Method**: `GET`
- **Mô tả**: Lấy thông tin chi tiết của một người dùng (yêu cầu JWT và role "admin").
- **Headers**:
  - `Authorization: Bearer <token>`
- **URL Example**: `/admin/users/some-uuid`
- **Response**:
  - **Thành công (200 OK)**:
    ```json
    {
      "id": "some-uuid",
      "username": "testuser",
      "email": "test@example.com",
      "password_hash": "...",
      "role": "user",
      "is_email_verified": true,
      "created_at": "2025-03-18T10:00:00Z",
      "updated_at": "2025-03-18T10:00:00Z"
    }
    ```
  - **Lỗi (401 Unauthorized)**:
    ```json
    {
      "error": "Unauthorized"
    }
    ```
  - **Lỗi (403 Forbidden)**:
    ```json
    {
      "error": "Permission denied"
    }
    ```
  - **Lỗi (404 Not Found)**:
    ```json
    {
      "error": "User not found"
    }
    ```

---

## Ghi chú
- **JWT Token**: Token nhận được từ `/auth/login` phải được thêm vào header `Authorization` cho các endpoint `/user/*` và `/admin/*`.
- **Role**: Chỉ user có `role: "admin"` mới truy cập được `/admin/users/:id`.
- **UUID**: Thay `some-uuid` bằng ID thực tế của user từ bước đăng ký.
- **OTP**: Mã OTP có thời hạn 5 phút, cần xác minh ngay sau khi tạo.

## Cách test bằng Postman
1. Mở Postman.
2. Tạo request mới với method, URL, headers, và body như trên.
3. Gửi request và kiểm tra response.

## Lưu ý lỗi thường gặp
- **401 Unauthorized**: Kiểm tra token trong header hoặc đảm bảo user đã đăng nhập.
- **403 Forbidden**: Đảm bảo user có role "admin" khi gọi endpoint `/admin/*`.
- **404 Not Found**: Kiểm tra `user_id` có tồn tại trong database không.
```

---

### Cách sử dụng file Markdown
1. **Lưu file**: Sao chép nội dung trên vào file `docs/api_user.md` trong thư mục `docs/` của dự án.
2. **Test bằng Postman**:
   - Tạo một collection trong Postman (ví dụ: "HamsterCare User APIs").
   - Thêm từng request dựa trên thông tin trong Markdown (URL, method, headers, body).
   - Gửi yêu cầu lần lượt từ `/auth/register` -> `/auth/login` -> `/otp/create` -> `/otp/verify` -> `/user/:id` hoặc `/admin/users/:id`.

Nếu bạn cần thêm endpoint nào khác (ví dụ: cập nhật user, xóa user) hoặc hỗ trợ tạo file Postman collection (JSON export), hãy cho tôi biết nhé!
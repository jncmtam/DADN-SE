Below is the complete API documentation in a single Markdown file, including all the existing endpoints from the original documentation and the new endpoints we’ve implemented (`/change-password`, `/change-password/verify`, `/forgot-password`, and `/reset-password`). The documentation includes detailed request, response, and token usage information, following the same format as your original file.

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
  ```
- **Response**:
  - **Thành công (200 OK)**:
    ```json
    {
      "message": "User registered successfully",
      "user_id": "some-uuid"
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
      "error": "Unauthorized"
    }
    ```
  - **Lỗi (403 Forbidden)**:
    ```json
    {
      "error": "Permission denied"
    }
    ```

---

## 2. Đăng nhập (Login)
- **Endpoint**: `/auth/login`
- **Method**: `POST`
- **Mô tả**: Đăng nhập và nhận access token và refresh token.
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
      "access_token": "jwt-access-token-string",
      "refresh_token": "jwt-refresh-token-string"
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
      "expires_at": "2025-03-21T02:02:45Z"
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
  - `Authorization: Bearer <access-token>`
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
      "created_at": "2025-03-21T01:44:34Z",
      "updated_at": "2025-03-21T01:44:34Z"
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
  - `Authorization: Bearer <access-token>`
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
      "created_at": "2025-03-21T01:44:34Z",
      "updated_at": "2025-03-21T01:44:34Z"
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

## 7. Yêu cầu thay đổi mật khẩu (Change Password - Request OTP)
- **Endpoint**: `/auth/change-password`
- **Method**: `POST`
- **Mô tả**: Yêu cầu mã OTP để thay đổi mật khẩu (yêu cầu JWT, dành cho người dùng đã đăng nhập).
- **Headers**:
  - `Authorization: Bearer <access-token>`
- **Request Body**: Không cần body (userID được lấy từ JWT token).
- **Response**:
  - **Thành công (200 OK)**:
    ```json
    {
      "message": "OTP sent to your email",
      "expires_at": "2025-03-21T02:02:45Z"
    }
    ```
  - **Lỗi (401 Unauthorized)**:
    ```json
    {
      "error": "Unauthorized"
    }
    ```
  - **Lỗi (500 Internal Server Error)**:
    ```json
    {
      "error": "Failed to initiate password change"
    }
    ```
  - **Lỗi (500 Internal Server Error - Email Sending Failed)**:
    ```json
    {
      "error": "Failed to send OTP email"
    }
    ```

---

## 8. Xác minh OTP và thay đổi mật khẩu (Change Password - Verify OTP)
- **Endpoint**: `/auth/change-password/verify`
- **Method**: `POST`
- **Mô tả**: Xác minh mã OTP và thay đổi mật khẩu (yêu cầu JWT, dành cho người dùng đã đăng nhập).
- **Headers**:
  - `Authorization: Bearer <access-token>`
- **Request Body**:
  ```json
  {
    "otp_code": "123456",
    "new_password": "newpassword123"
  }
  ```
- **Response**:
  - **Thành công (200 OK)**:
    ```json
    {
      "message": "Password changed successfully"
    }
    ```
  - **Lỗi (400 Bad Request)**:
    ```json
    {
      "error": "Invalid request body"
    }
    ```
  - **Lỗi (401 Unauthorized)**:
    ```json
    {
      "error": "Unauthorized"
    }
    ```
  - **Lỗi (400 Bad Request - Invalid OTP)**:
    ```json
    {
      "error": "Failed to change password: invalid or expired OTP"
    }
    ```
  - **Lỗi (500 Internal Server Error)**:
    ```json
    {
      "error": "Failed to fetch user"
    }
    ```

---

## 9. Quên mật khẩu - Yêu cầu OTP (Forgot Password - Request OTP)
- **Endpoint**: `/auth/forgot-password`
- **Method**: `POST`
- **Mô tả**: Yêu cầu mã OTP để đặt lại mật khẩu (không yêu cầu JWT, dành cho người dùng quên mật khẩu).
- **Request Body**:
  ```json
  {
    "email": "test@example.com"
  }
  ```
- **Response**:
  - **Thành công (200 OK)**:
    ```json
    {
      "message": "If the email exists, an OTP has been sent",
      "expires_at": "2025-03-21T02:02:45Z"
    }
    ```
  - **Lỗi (400 Bad Request)**:
    ```json
    {
      "error": "Invalid request body"
    }
    ```
  - **Lỗi (500 Internal Server Error)**:
    ```json
    {
      "error": "Failed to fetch user"
    }
    ```
  - **Lỗi (500 Internal Server Error - Email Sending Failed)**:
    ```json
    {
      "error": "Failed to send OTP email"
    }
    ```

---

## 10. Quên mật khẩu - Đặt lại mật khẩu (Forgot Password - Reset Password)
- **Endpoint**: `/auth/reset-password`
- **Method**: `POST`
- **Mô tả**: Xác minh mã OTP và đặt lại mật khẩu (không yêu cầu JWT, dành cho người dùng quên mật khẩu).
- **Request Body**:
  ```json
  {
    "email": "test@example.com",
    "otp_code": "123456",
    "new_password": "newpassword123"
  }
  ```
- **Response**:
  - **Thành công (200 OK)**:
    ```json
    {
      "message": "Password reset successfully"
    }
    ```
  - **Lỗi (400 Bad Request)**:
    ```json
    {
      "error": "Invalid request body"
    }
    ```
  - **Lỗi (400 Bad Request - Invalid OTP)**:
    ```json
    {
      "error": "Failed to reset password: invalid or expired OTP"
    }
    ```
  - **Lỗi (400 Bad Request - User Not Found)**:
    ```json
    {
      "error": "Failed to reset password: user not found"
    }
    ```

---

## Ghi chú
- **JWT Token**: 
  - Access token nhận được từ `/auth/login` phải được thêm vào header `Authorization` cho các endpoint `/user/*`, `/admin/*`, `/auth/change-password`, và `/auth/change-password/verify`.
  - Access token có thời hạn 24 giờ, refresh token có thời hạn 7 ngày.
- **Role**: Chỉ user có `role: "admin"` mới truy cập được `/admin/*` endpoints.
- **UUID**: Thay `some-uuid` bằng ID thực tế của user từ bước đăng ký hoặc từ database.
- **OTP**: Mã OTP có thời hạn 5 phút, cần xác minh ngay sau khi tạo.
- **Email Sending**: Các endpoint `/auth/change-password` và `/auth/forgot-password` gửi OTP qua email. Đảm bảo đã cấu hình SendGrid (hoặc email provider khác) và đặt biến môi trường `SENDGRID_API_KEY`.

## Cách test bằng Postman
1. Mở Postman.
2. Tạo request mới với method, URL, headers, và body như trên.
3. Gửi request theo thứ tự:
   - Đăng ký: `/admin/auth/register` (nếu cần tạo user mới, yêu cầu admin token).
   - Đăng nhập: `/auth/login` để lấy access token và refresh token.
   - Xác minh email (nếu cần): `/otp/create` -> `/otp/verify`.
   - Thay đổi mật khẩu (đã đăng nhập): `/auth/change-password` -> `/auth/change-password/verify`.
   - Quên mật khẩu: `/auth/forgot-password` -> `/auth/reset-password`.
   - Lấy thông tin user: `/user/:id` hoặc `/admin/users/:id`.

## Lưu ý lỗi thường gặp
- **401 Unauthorized**: Kiểm tra token trong header hoặc đảm bảo user đã đăng nhập. Nếu token hết hạn, đăng nhập lại để lấy token mới.
- **403 Forbidden**: Đảm bảo user có role "admin" khi gọi endpoint `/admin/*`.
- **404 Not Found**: Kiểm tra `user_id` có tồn tại trong database không.
- **500 Internal Server Error (Email Sending)**: Kiểm tra cấu hình SendGrid và biến môi trường `SENDGRID_API_KEY`.
- **400 Bad Request (Invalid OTP)**: Đảm bảo OTP chưa hết hạn (5 phút) và chưa được sử dụng.

## Cách sử dụng file Markdown
1. **Lưu file**: Sao chép nội dung trên vào file `docs/api_user.md` trong thư mục `docs/` của dự án.
2. **Test bằng Postman**:
   - Tạo một collection trong Postman (ví dụ: "HamsterCare User APIs").
   - Thêm từng request dựa trên thông tin trong Markdown (URL, method, headers, body).
   - Gửi yêu cầu lần lượt theo thứ tự được đề xuất.

Nếu bạn cần thêm endpoint nào khác (ví dụ: cập nhật user, xóa user) hoặc hỗ trợ tạo file Postman collection (JSON export), hãy cho tôi biết nhé!
```

---

### Notes for Usage
- You can copy the entire Markdown content above and save it as `docs/api_user.md` in your project.
- The documentation now includes all endpoints: the original ones (`/admin/auth/register`, `/auth/login`, `/otp/create`, `/otp/verify`, `/user/:id`, `/admin/users/:id`) and the new ones (`/auth/change-password`, `/auth/change-password/verify`, `/auth/forgot-password`, `/auth/reset-password`).
- The responses and error messages are based on the actual implementation in your code.
- The documentation includes guidance on token usage, OTP expiration, and email sending requirements.

Let me know if you need a Postman collection export or additional endpoints!
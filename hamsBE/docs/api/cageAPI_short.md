# 🛠 API Documentation: Hệ Thống Quản Lý Chuồng và Thiết Bị

## 🔐 1. API cho Admin

### 1.1. Lấy danh sách tất cả user
- **Method**: GET  
- **Route**: `/admin/get-all-user`  
- **Description**: Trả về danh sách toàn bộ người dùng đã đăng ký.  
- **Response**:
```json
[
  {
    "user_id": "string",
    "name": "string",
    "email": "string"
  }
]
```

### 1.2. Lấy danh sách tất cả chuồng
- **Method**: GET  
- **Route**: `/admin/get-all-cage`  
- **Description**: Trả về danh sách tất cả chuồng vật nuôi.

### 1.3. Lấy danh sách tất cả thiết bị
- **Method**: GET  
- **Route**: `/admin/get-all-device`  
- **Description**: Trả về danh sách tất cả các thiết bị trong hệ thống.

---

## 👤 2. API cho User

### 2.1. Đăng ký tài khoản
- **Method**: POST  
- **Route**: `/register`  
- **Description**: Cho phép người dùng tạo tài khoản mới.  
- **Request Body**:
```json
{
  "email": "string",
  "password": "string",
  "name": "string"
}
```

### 2.2. Đăng nhập
- **Method**: POST  
- **Route**: `/login`  
- **Description**: Đăng nhập vào hệ thống.  
- **Request Body**:
```json
{
  "email": "string",
  "password": "string"
}
```

### 2.3. Lấy thông tin người dùng
- **Method**: GET  
- **Route**: `/get-user`  
- **Description**: Lấy thông tin người dùng đang đăng nhập (dựa theo token).

### 2.4. Lấy danh sách chuồng của user
- **Method**: GET  
- **Route**: `/get-cage`  
- **Description**: Trả về danh sách các chuồng mà user sở hữu.

### 2.5. Tạo chuồng mới
- **Method**: POST  
- **Route**: `/create-cage`  
- **Description**: Tạo mới một chuồng cho người dùng.  
- **Request Body**:
```json
{
  "name": "string",
  "location": "string"
}
```

### 2.6. Xoá chuồng
- **Method**: DELETE  
- **Route**: `/delete-cage/:id`  
- **Description**: Xoá chuồng có ID cụ thể.

### 2.7. Lấy danh sách thiết bị trong chuồng
- **Method**: GET  
- **Route**: `/get-device/:cageId`  
- **Description**: Lấy toàn bộ thiết bị nằm trong một chuồng cụ thể.

### 2.8. Tạo thiết bị
- **Method**: POST  
- **Route**: `/create-device`  
- **Description**: Tạo một thiết bị mới gắn vào chuồng.  
- **Request Body**:
```json
{
  "cageId": "string",
  "type": "string",
  "name": "string"
}
```

### 2.9. Xoá thiết bị
- **Method**: DELETE  
- **Route**: `/delete-device/:id`  
- **Description**: Xoá thiết bị với ID cụ thể.

### 2.10. Bật/Tắt thiết bị
- **Method**: PATCH  
- **Route**: `/toggle-device/:id`  
- **Description**: Thay đổi trạng thái bật/tắt của thiết bị.  
- **Request Body**:
```json
{
  "status": true | false
}
```
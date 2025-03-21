
# API Documentation

## Admin Routes

### Get User by ID
- **Method**: `GET`
- **URL**: `/admin/users/:id`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Response**:
  - `200 OK`: User details
  - `404 Not Found`: User not found

### Get All Users
- **Method**: `GET`
- **URL**: `/admin/users`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Response**:
  - `200 OK`: List of users
  - `500 Internal Server Error`: Failed to fetch users

### Register New User (Admin Only)
- **Method**: `POST`
- **URL**: `/admin/auth/register`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Request Body**:
  ```json
  {
    "username": "string",
    "email": "string",
    "password": "string",
    "role": "string"
  }
  ```
- **Response**:
  - `201 Created`: User registered successfully
  - `400 Bad Request`: Invalid request body
  - `409 Conflict`: Email or username already exists
  - `500 Internal Server Error`: Failed to create user

### Delete User
- **Method**: `DELETE`
- **URL**: `/admin/users/:user_id`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Response**:
  - `200 OK`: User deleted successfully
  - `403 Forbidden`: Only admins can delete users
  - `404 Not Found`: User not found
  - `500 Internal Server Error`: Failed to delete user

## Auth Routes

### Login
- **Method**: `POST`
- **URL**: `/auth/login`
- **Request Body**:
  ```json
  {
    "email": "string",
    "password": "string"
  }
  ```
- **Response**:
  - `200 OK`: Authentication response
  - `400 Bad Request`: Invalid request body
  - `401 Unauthorized`: Email not found or invalid password
  - `500 Internal Server Error`: Login failed

### Logout
- **Method**: `POST`
- **URL**: `/auth/logout`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Response**:
  - `200 OK`: Successfully logged out
  - `400 Bad Request`: Invalid or missing Authorization header
  - `401 Unauthorized`: Unauthorized
  - `500 Internal Server Error`: Failed to logout

### Change Password (Request OTP)
- **Method**: `POST`
- **URL**: `/auth/change-password`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Response**:
  - `200 OK`: OTP sent to your email
  - `401 Unauthorized`: Unauthorized
  - `500 Internal Server Error`: Failed to initiate password change

### Change Password (Verify OTP)
- **Method**: `POST`
- **URL**: `/auth/change-password/verify`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Request Body**:
  ```json
  {
    "otp_code": "string",
    "new_password": "string"
  }
  ```
- **Response**:
  - `200 OK`: Password changed successfully
  - `400 Bad Request`: Invalid request body
  - `401 Unauthorized`: Unauthorized
  - `500 Internal Server Error`: Failed to change password

### Forgot Password (Request OTP)
- **Method**: `POST`
- **URL**: `/auth/forgot-password`
- **Request Body**:
  ```json
  {
    "email": "string"
  }
  ```
- **Response**:
  - `200 OK`: OTP sent to your email
  - `500 Internal Server Error`: Failed to initiate password reset

### Reset Password
- **Method**: `POST`
- **URL**: `/auth/reset-password`
- **Request Body**:
  ```json
  {
    "email": "string",
    "otp_code": "string",
    "new_password": "string"
  }
  ```
- **Response**:
  - `200 OK`: Password reset successfully
  - `400 Bad Request`: Invalid request body
  - `500 Internal Server Error`: Failed to reset password

### Refresh Access Token
- **Method**: `POST`
- **URL**: `/auth/refresh`
- **Request Body**:
  ```json
  {
    "refresh_token": "string"
  }
  ```
- **Response**:
  - `200 OK`: New access token
  - `400 Bad Request`: Invalid request
  - `401 Unauthorized`: Invalid or expired refresh token
  - `500 Internal Server Error`: Failed to generate token

## Profile Routes

### Get Profile
- **Method**: `GET`
- **URL**: `/profile`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Response**:
  - `200 OK`: Profile details
  - `401 Unauthorized`: Unauthorized
  - `500 Internal Server Error`: Failed to fetch user

### Change Avatar
- **Method**: `POST`
- **URL**: `/profile/avatar`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Request Body**:
  - `avatar`: File (JPG, JPEG, PNG, max 5MB)
- **Response**:
  - `200 OK`: Avatar updated successfully
  - `400 Bad Request`: Invalid file or size exceeds limit
  - `401 Unauthorized`: Unauthorized
  - `500 Internal Server Error`: Failed to update avatar

### Get Avatar
- **Method**: `GET`
- **URL**: `/profile/avatar`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Response**:
  - `200 OK`: Avatar image
  - `401 Unauthorized`: Unauthorized
  - `500 Internal Server Error`: Failed to fetch user

### Change Username
- **Method**: `POST`
- **URL**: `/profile/username`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Request Body**:
  ```json
  {
    "username": "string"
  }
  ```
- **Response**:
  - `200 OK`: Username updated successfully
  - `400 Bad Request`: Invalid request body
  - `401 Unauthorized`: Unauthorized
  - `409 Conflict`: Username already taken
  - `500 Internal Server Error`: Failed to update username

## User Routes

### Get User by ID
- **Method**: `GET`
- **URL**: `/user/:id`
- **Headers**: 
  - `Authorization: Bearer <token>`
- **Response**:
  - `200 OK`: User details
  - `404 Not Found`: User not found
```
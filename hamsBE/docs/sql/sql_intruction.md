# Phần I : Các câu lệnh SQL hữu dụng
## Truy cập vào database
```sql
psql -d <databaseName> -U <userName>
```
## Cấp quyền cho user khác
- Trong trường hợp user không phải là owner thì owner phải cấp quyền truy cập cho user `GRANT`
```sql
GRANT CONNECT ON DATABASE <databaseName> TO <userName>;
```
## Cấp quyền truy cập bảng
```sql 
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO hamster_user;
```
## Các câu lệnh đơn giản
- Xem toàn bộ người dùng
```sql
\du
```
- Xem toàn bộ bảng `table`
```sql
\dt
```
- Clear Screen
```sql
\! clear
```

## Cage
- cageID:
```sql
550e8400-e29b-41d4-a716-446655440100
```
- 
# User 
- Create new user
```sql
INSERT INTO users (
    username,
    email,
    password_hash,
    role,
    is_email_verified
) VALUES (
    'admin1',
    'admin1@example.com',
    '$2a$10$EDDWU0p.MXHBIc166fW.pOkNuccnqz8ahCopr/Sq1iOFhVkU6cmZy',
    'admin',
    true
);
```
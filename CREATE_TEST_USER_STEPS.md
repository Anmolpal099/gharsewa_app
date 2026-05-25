# 🔧 Create Test User - Step by Step Guide

## Step 1: Access MySQL Database

Open PowerShell and run:

```powershell
docker exec -it gharsewa-db mysql -u root -proot_password gharsewa
```

**You should see:**
```
mysql>
```

This means you're now inside the MySQL prompt.

## Step 2: Run SQL Commands

**Copy and paste these commands ONE BY ONE** into the MySQL prompt:

### Command 1: Delete existing test user (if exists)
```sql
DELETE FROM users WHERE email = 'test@example.com';
```

Press Enter. You should see:
```
Query OK, 0 rows affected (0.00 sec)
```
or
```
Query OK, 1 row affected (0.00 sec)
```

### Command 2: Create test user
```sql
INSERT INTO users (name, email, password, role, is_active, email_verified_at, created_at, updated_at) VALUES ('Test User', 'test@example.com', '$2y$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYfujPn7Twu', 'customer', 1, NOW(), NOW(), NOW());
```

Press Enter. You should see:
```
Query OK, 1 row affected (0.01 sec)
```

### Command 3: Verify user was created
```sql
SELECT id, name, email, role, email_verified_at FROM users WHERE email = 'test@example.com';
```

Press Enter. You should see:
```
+----+-----------+------------------+----------+---------------------+
| id | name      | email            | role     | email_verified_at   |
+----+-----------+------------------+----------+---------------------+
|  1 | Test User | test@example.com | customer | 2024-01-01 12:00:00 |
+----+-----------+------------------+----------+---------------------+
1 row in set (0.00 sec)
```

### Command 4: Exit MySQL
```sql
EXIT;
```

You should be back in PowerShell.

## Step 3: Test Login in Flutter App

Now open your Flutter app and login with:
- **Email:** `test@example.com`
- **Password:** `Password123`

## Alternative: Use SQL File

If you prefer, you can use the SQL file I created:

### Step 1: Access MySQL
```powershell
docker exec -it gharsewa-db mysql -u root -proot_password gharsewa
```

### Step 2: Run the SQL file
```sql
source /path/to/create_test_user.sql
```

Or copy the file into the container first:
```powershell
docker cp e:\gharsewa\create_test_user.sql gharsewa-db:/tmp/
docker exec -it gharsewa-db mysql -u root -proot_password gharsewa -e "source /tmp/create_test_user.sql"
```

## Troubleshooting

### Error: "Can't connect to MySQL server"
**Solution:** Make sure Docker containers are running:
```powershell
docker ps
```

If not running:
```powershell
cd e:\gharsewa\backend
docker-compose up -d
```

### Error: "Access denied"
**Solution:** Check the password. It should be `root_password` (from your `.env` file)

### Error: "Unknown database 'gharsewa'"
**Solution:** Run migrations:
```powershell
docker exec -it gharsewa-app php artisan migrate
```

## Quick Copy-Paste Version

**For PowerShell (Step 1 only):**
```powershell
docker exec -it gharsewa-db mysql -u root -proot_password gharsewa
```

**For MySQL prompt (Steps 2-4):**
```sql
DELETE FROM users WHERE email = 'test@example.com';

INSERT INTO users (name, email, password, role, is_active, email_verified_at, created_at, updated_at) VALUES ('Test User', 'test@example.com', '$2y$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYfujPn7Twu', 'customer', 1, NOW(), NOW(), NOW());

SELECT id, name, email, role, email_verified_at FROM users WHERE email = 'test@example.com';

EXIT;
```

## Test Credentials

- **Email:** `test@example.com`
- **Password:** `Password123`

---

**Important:** Make sure you're inside the MySQL prompt (you see `mysql>`) before running the SQL commands!


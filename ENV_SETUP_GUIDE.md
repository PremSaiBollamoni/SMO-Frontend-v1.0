# 🔐 Environment Variables Setup Guide

## Quick Reference

### CRITICAL Environment Variables (Required)

| Variable | Purpose | Example | How to Generate |
|----------|---------|---------|-----------------|
| `DB_URL` | MySQL connection | `jdbc:mysql://host:3306/PALMSV1?useSSL=true` | Set your MySQL host |
| `DB_USERNAME` | DB user | `palms_app` | Create in MySQL |
| `DB_PASSWORD` | DB password | `strong_16char_password` | `openssl rand -base64 16` |
| `JWT_SECRET` | JWT signing key | (Base64 string) | `openssl rand -base64 32` |
| `ENCRYPTION_KEY` | Data encryption | (Base64 string) | `java -cp smo.jar com.cutm.smo.util.EncryptionUtil` |
| `CORS_ALLOWED_ORIGINS` | Allowed domains | `https://yourdomain.com` | Your frontend domain |
| `SWAGGER_ENABLED` | Expose API docs | `false` | Set to false in production |

---

## Step-by-Step Setup

### Step 1: Generate Encryption Keys

**Generate JWT_SECRET:**
```bash
openssl rand -base64 32
```
Output example:
```
QpVjDxS9K2mL8nP1aB5cX7yZ3fG6hJ4kM9wR0sT2uV8=
```

**Generate ENCRYPTION_KEY:**
```bash
cd backend
mvn package -DskipTests
java -cp target/smo-V0.1.war com.cutm.smo.util.EncryptionUtil
```
Output example:
```
Generated Encryption Key (256-bit):
QpVjDxS9K2mL8nP1aB5cX7yZ3fG6hJ4kM9wR0sT2uV8=
```

**Generate DB_PASSWORD:**
```bash
openssl rand -base64 16
```
Output example:
```
aB3cD5eF7gH9iJ1kL3mN5o7pQ9rS1tU3=
```

---

### Step 2: Create Database User

**Login to MySQL:**
```bash
mysql -u root -p
```

**Create application user:**
```sql
CREATE USER 'palms_app'@'localhost' IDENTIFIED BY 'your_generated_password_here';

GRANT SELECT, INSERT, UPDATE, DELETE ON PALMSV1.* TO 'palms_app'@'localhost';

REVOKE ALL PRIVILEGES ON *.* FROM 'palms_app'@'localhost';

REVOKE GRANT OPTION ON PALMSV1.* FROM 'palms_app'@'localhost';

FLUSH PRIVILEGES;

EXIT;
```

---

### Step 3: Set Environment Variables

#### Option A: Linux/Mac (Bash)

Create a file `~/.smo-env`:
```bash
export DB_URL="jdbc:mysql://localhost:3306/PALMSV1?useSSL=true&serverTimezone=UTC"
export DB_USERNAME="palms_app"
export DB_PASSWORD="your_generated_password"
export JWT_SECRET="your_generated_jwt_secret"
export ENCRYPTION_KEY="your_generated_encryption_key"
export CORS_ALLOWED_ORIGINS="https://yourdomain.com"
export SWAGGER_ENABLED="false"
export ENABLE_HTTPS_ONLY="true"
```

Load before running:
```bash
source ~/.smo-env
java -jar target/smo-V0.1.war
```

#### Option B: Windows (PowerShell)

Create a file `env-setup.ps1`:
```powershell
$env:DB_URL = "jdbc:mysql://localhost:3306/PALMSV1?useSSL=true&serverTimezone=UTC"
$env:DB_USERNAME = "palms_app"
$env:DB_PASSWORD = "your_generated_password"
$env:JWT_SECRET = "your_generated_jwt_secret"
$env:ENCRYPTION_KEY = "your_generated_encryption_key"
$env:CORS_ALLOWED_ORIGINS = "https://yourdomain.com"
$env:SWAGGER_ENABLED = "false"
$env:ENABLE_HTTPS_ONLY = "true"

java -jar target/smo-V0.1.war
```

Run:
```powershell
.\env-setup.ps1
```

#### Option C: Docker/Kubernetes

Create `docker-compose.yml`:
```yaml
version: '3.8'
services:
  smo-backend:
    image: smo:latest
    ports:
      - "8080:8080"
    environment:
      DB_URL: "jdbc:mysql://mysql:3306/PALMSV1?useSSL=true"
      DB_USERNAME: "palms_app"
      DB_PASSWORD: "your_password"
      JWT_SECRET: "your_jwt_secret"
      ENCRYPTION_KEY: "your_encryption_key"
      CORS_ALLOWED_ORIGINS: "https://yourdomain.com"
      SWAGGER_ENABLED: "false"
    depends_on:
      - mysql
      
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: "root_password"
      MYSQL_DATABASE: "PALMSV1"
    volumes:
      - mysql_data:/var/lib/mysql

volumes:
  mysql_data:
```

Run:
```bash
docker-compose up
```

---

### Step 4: Verify Environment Variables

**Check if variables are set (Linux/Mac):**
```bash
echo $DB_URL
echo $JWT_SECRET
echo $ENCRYPTION_KEY
```

**Check if variables are set (Windows PowerShell):**
```powershell
$env:DB_URL
$env:JWT_SECRET
$env:ENCRYPTION_KEY
```

---

### Step 5: Run Application

**Build:**
```bash
cd backend
mvn clean package -DskipTests
```

**Run:**
```bash
java -jar target/smo-V0.1.war
```

**Verify startup:**
```bash
curl http://localhost:8080/api/health
# Should return: {"status":"UP"}
```

---

## Minimum Values Required

```
DB_URL:                 (required) - your MySQL connection string
DB_USERNAME:            (required) - database user
DB_PASSWORD:            (required) - database password (min 16 chars)
JWT_SECRET:             (required) - min 44 characters (Base64 encoded 256-bit)
ENCRYPTION_KEY:         (required) - min 44 characters (Base64 encoded 256-bit)
CORS_ALLOWED_ORIGINS:   (required) - your frontend domain (no wildcards)
SWAGGER_ENABLED:        false (production), true (dev)
ENABLE_HTTPS_ONLY:      true (production), false (dev)
```

---

## Security Checklist

- [ ] Generated strong random passwords (min 16 chars)
- [ ] Generated JWT_SECRET (openssl rand -base64 32)
- [ ] Generated ENCRYPTION_KEY (EncryptionUtil)
- [ ] Created database user with limited privileges
- [ ] Set SWAGGER_ENABLED=false in production
- [ ] Set ENABLE_HTTPS_ONLY=true in production
- [ ] CORS_ALLOWED_ORIGINS has no wildcards (*)
- [ ] Database connection uses SSL/TLS
- [ ] Never committed .env file to repository
- [ ] Using environment variables (not hardcoded values)
- [ ] Secrets stored in secure vault (AWS Secrets Manager, Vault, etc)

---

## Troubleshooting

### "Cannot connect to database"
- Check DB_URL syntax: `jdbc:mysql://host:3306/PALMSV1?useSSL=true&serverTimezone=UTC`
- Verify DB_USERNAME and DB_PASSWORD
- Verify MySQL is running on correct host/port
- Test: `mysql -h host -u palms_app -p`

### "JWT_SECRET not found"
- Environment variable not set
- Try: `echo $JWT_SECRET` (Linux/Mac) or `$env:JWT_SECRET` (Windows)
- Restart terminal/PowerShell after setting variables

### "Invalid encryption key"
- ENCRYPTION_KEY must be Base64 encoded
- Must be exactly 44 characters (256-bit)
- Generate with: `java -cp target/smo.jar com.cutm.smo.util.EncryptionUtil`

### "CORS rejection"
- Check CORS_ALLOWED_ORIGINS matches your frontend domain
- Remove any trailing slashes
- Format: `https://domain.com` (no `http://` unless dev)

---

## Production Deployment Checklist

1. **Database**
   - [ ] MySQL 8.0+ running with SSL/TLS
   - [ ] Database created: `PALMSV1`
   - [ ] Application user created with limited privileges
   - [ ] Backups configured and tested
   - [ ] Connection pool size: 20+ for production

2. **Secrets Management**
   - [ ] Secrets stored in AWS Secrets Manager / Vault
   - [ ] Rotation policy in place
   - [ ] Never hardcoded values in code
   - [ ] Environment variables only

3. **Security Settings**
   - [ ] SWAGGER_ENABLED=false
   - [ ] ENABLE_HTTPS_ONLY=true
   - [ ] JWT_SECRET strong (44+ chars)
   - [ ] ENCRYPTION_KEY strong (44+ chars)
   - [ ] CORS restricted (no wildcards)

4. **Network**
   - [ ] HTTPS/TLS enabled for frontend
   - [ ] Database SSL/TLS enabled
   - [ ] Firewall rules configured
   - [ ] Only application server can access database

5. **Monitoring**
   - [ ] Log aggregation configured
   - [ ] Health checks set up
   - [ ] Alerts for failed logins
   - [ ] Alerts for rate limit violations
   - [ ] Database backup monitoring

---

**Status: Ready for Production Deployment ✅**

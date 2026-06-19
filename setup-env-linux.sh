#!/bin/bash

# SMO Environment Setup Script for Linux/Mac
# This script sets up all environment variables and starts the backend

echo "========================================"
echo "SMO Backend - Environment Setup Script"
echo "========================================"
echo ""

# Step 1: Check if MySQL is running
echo "Step 1: Checking MySQL status..."
if mysql -u root -e "SELECT 1" 2>/dev/null; then
    echo "✅ MySQL is running"
    MYSQL_RUNNING=true
else
    echo "❌ MySQL is not running"
    echo ""
    echo "Please start MySQL first:"
    echo "1. macOS (Homebrew): brew services start mysql"
    echo "2. Linux (systemd): sudo systemctl start mysql"
    echo "3. Docker: docker run -d -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root mysql:8.0"
    echo ""
    read -p "Press Enter after starting MySQL, or Ctrl+C to exit: "
    MYSQL_RUNNING=false
fi

# Step 2: Generate Secrets
echo ""
echo "Step 2: Generating secrets..."

JWT_SECRET=$(openssl rand -base64 32)
echo "Generated JWT_SECRET: $JWT_SECRET"

ENCRYPTION_KEY=$(openssl rand -base64 32)
echo "Generated ENCRYPTION_KEY: $ENCRYPTION_KEY"

DB_PASSWORD=$(openssl rand -base64 16)
echo "Generated DB_PASSWORD: $DB_PASSWORD"

# Step 3: Set Environment Variables
echo ""
echo "Step 3: Setting environment variables..."

export DB_URL="jdbc:mysql://localhost:3306/PALMSV1?useSSL=true&serverTimezone=UTC"
export DB_USERNAME="palms_app"
export DB_PASSWORD="$DB_PASSWORD"
export JWT_SECRET="$JWT_SECRET"
export ENCRYPTION_KEY="$ENCRYPTION_KEY"
export CORS_ALLOWED_ORIGINS="https://yourdomain.com,http://localhost:4200"
export SWAGGER_ENABLED="false"
export ENABLE_HTTPS_ONLY="false"

echo "✅ Environment variables set"
echo ""

# Step 4: Create Database User
echo "Step 4: Setting up database user..."

# Create database
mysql -u root -e "CREATE DATABASE IF NOT EXISTS PALMSV1;"
echo "✅ Database PALMSV1 created"

# Drop existing user
mysql -u root -e "DROP USER IF EXISTS 'palms_app'@'localhost';" 2>/dev/null

# Create new user
mysql -u root -e "CREATE USER 'palms_app'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
echo "✅ Database user 'palms_app' created"

# Grant permissions
mysql -u root -e "GRANT SELECT, INSERT, UPDATE, DELETE ON PALMSV1.* TO 'palms_app'@'localhost';"
mysql -u root -e "FLUSH PRIVILEGES;"
echo "✅ Permissions granted"

# Step 5: Build Backend
echo ""
echo "Step 5: Building backend..."

cd /c/Users/HP/SMOBZAV2/backend || cd ~/SMO/backend

if [ -f "target/smo-V0.1.war" ]; then
    echo "Using existing build (delete target/ to rebuild)"
else
    echo "Running Maven build..."
    mvn clean package -DskipTests
    if [ $? -ne 0 ]; then
        echo "❌ Build failed"
        exit 1
    fi
fi

echo "✅ Backend built successfully"

# Step 6: Display Summary
echo ""
echo "========================================="
echo "✅ SETUP COMPLETE!"
echo "========================================="
echo ""
echo "Environment Variables:"
echo "  DB_URL: $DB_URL"
echo "  DB_USERNAME: $DB_USERNAME"
echo "  DB_PASSWORD: $DB_PASSWORD"
echo "  JWT_SECRET: $JWT_SECRET"
echo "  ENCRYPTION_KEY: $ENCRYPTION_KEY"
echo "  CORS_ALLOWED_ORIGINS: $CORS_ALLOWED_ORIGINS"
echo "  SWAGGER_ENABLED: $SWAGGER_ENABLED"
echo "  ENABLE_HTTPS_ONLY: $ENABLE_HTTPS_ONLY"
echo ""

# Step 7: Start Backend
echo "Step 6: Starting backend..."
echo "Press Ctrl+C to stop the server"
echo ""

java -jar target/smo-V0.1.war

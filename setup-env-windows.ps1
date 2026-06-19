# SMO Environment Setup Script for Windows PowerShell
# This script sets up all environment variables and starts the backend

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SMO Backend - Environment Setup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if MySQL is running
Write-Host "Step 1: Checking MySQL status..." -ForegroundColor Yellow
try {
    $mysqlTest = Invoke-Expression "mysql -u root -e 'SELECT 1'" 2>&1
    Write-Host "✅ MySQL is running" -ForegroundColor Green
    $mysqlRunning = $true
} catch {
    Write-Host "❌ MySQL is not running" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please start MySQL first:" -ForegroundColor Yellow
    Write-Host "1. If using MySQL installed locally, check Services (services.msc) and start MySQL80"
    Write-Host "2. If using Docker: docker run -d -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root mysql:8.0"
    Write-Host ""
    $mysqlRunning = $false
}

if (-not $mysqlRunning) {
    Read-Host "Press Enter after starting MySQL, or Ctrl+C to exit"
}

# Step 2: Generate Secrets
Write-Host ""
Write-Host "Step 2: Generating secrets..." -ForegroundColor Yellow

# Generate JWT_SECRET
$jwtSecret = (openssl rand -base64 32)
Write-Host "Generated JWT_SECRET: $jwtSecret" -ForegroundColor Green

# Generate ENCRYPTION_KEY
$encryptionKey = (openssl rand -base64 32)
Write-Host "Generated ENCRYPTION_KEY: $encryptionKey" -ForegroundColor Green

# Generate DB_PASSWORD
$dbPassword = (openssl rand -base64 16)
Write-Host "Generated DB_PASSWORD: $dbPassword" -ForegroundColor Green

# Step 3: Set Environment Variables
Write-Host ""
Write-Host "Step 3: Setting environment variables..." -ForegroundColor Yellow

$env:DB_URL = "jdbc:mysql://localhost:3306/PALMSV1?useSSL=true&serverTimezone=UTC"
$env:DB_USERNAME = "palms_app"
$env:DB_PASSWORD = $dbPassword
$env:JWT_SECRET = $jwtSecret
$env:ENCRYPTION_KEY = $encryptionKey
$env:CORS_ALLOWED_ORIGINS = "https://yourdomain.com,http://localhost:4200"
$env:SWAGGER_ENABLED = "false"
$env:ENABLE_HTTPS_ONLY = "false"

Write-Host "✅ Environment variables set" -ForegroundColor Green
Write-Host ""

# Step 4: Create Database User
Write-Host "Step 4: Setting up database user..." -ForegroundColor Yellow

try {
    # Create database
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS PALMSV1;"
    Write-Host "✅ Database PALMSV1 created" -ForegroundColor Green

    # Drop existing user
    mysql -u root -e "DROP USER IF EXISTS 'palms_app'@'localhost';" 2>$null

    # Create new user
    $createUserSQL = "CREATE USER 'palms_app'@'localhost' IDENTIFIED BY '$dbPassword';"
    mysql -u root -e $createUserSQL
    Write-Host "✅ Database user 'palms_app' created" -ForegroundColor Green

    # Grant permissions
    mysql -u root -e "GRANT SELECT, INSERT, UPDATE, DELETE ON PALMSV1.* TO 'palms_app'@'localhost';"
    mysql -u root -e "FLUSH PRIVILEGES;"
    Write-Host "✅ Permissions granted" -ForegroundColor Green

} catch {
    Write-Host "❌ Error setting up database user" -ForegroundColor Red
    Write-Host "Make sure MySQL is running and root password is correct" -ForegroundColor Yellow
    exit 1
}

# Step 5: Build Backend
Write-Host ""
Write-Host "Step 5: Building backend..." -ForegroundColor Yellow

Set-Location "C:\Users\HP\SMOBZAV2\backend"

if (Test-Path "target\smo-V0.1.war") {
    Write-Host "Using existing build (delete target/ to rebuild)" -ForegroundColor Cyan
} else {
    Write-Host "Running Maven build..." -ForegroundColor Cyan
    mvn clean package -DskipTests
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Build failed" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ Backend built successfully" -ForegroundColor Green

# Step 6: Display Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ SETUP COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Environment Variables:" -ForegroundColor Cyan
Write-Host "  DB_URL: $env:DB_URL"
Write-Host "  DB_USERNAME: $env:DB_USERNAME"
Write-Host "  DB_PASSWORD: $env:DB_PASSWORD"
Write-Host "  JWT_SECRET: $env:JWT_SECRET"
Write-Host "  ENCRYPTION_KEY: $env:ENCRYPTION_KEY"
Write-Host "  CORS_ALLOWED_ORIGINS: $env:CORS_ALLOWED_ORIGINS"
Write-Host "  SWAGGER_ENABLED: $env:SWAGGER_ENABLED"
Write-Host "  ENABLE_HTTPS_ONLY: $env:ENABLE_HTTPS_ONLY"
Write-Host ""

# Step 7: Start Backend
Write-Host "Step 6: Starting backend..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

java -jar "C:\Users\HP\SMOBZAV2\backend\target\smo-V0.1.war"

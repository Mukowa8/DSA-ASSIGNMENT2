@echo off
echo ========================================
echo  Starting Smart Ticketing System
echo ========================================
echo.

echo Checking Docker...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker not found! Please start Docker Desktop first.
    pause
    exit /b 1
)

echo Step 1: Building Docker images...
docker-compose build
if %errorlevel% neq 0 (
    echo ERROR: Docker build failed!
    echo Make sure Docker Desktop is running.
    pause
    exit /b 1
)
echo.

echo Step 2: Starting services...
docker-compose up -d
if %errorlevel% neq 0 (
    echo ERROR: Failed to start services!
    pause
    exit /b 1
)
echo.

echo ========================================
echo        System Starting Up...
echo ========================================
echo.
echo Waiting for services to initialize (40 seconds)...
echo This may take a while on first run...
timeout /t 40 /nobreak
echo.

echo Checking container status...
docker-compose ps
echo.

echo ========================================
echo    System started successfully!
echo ========================================
echo.
echo Services available on:
echo.
echo Passenger Service:  http://localhost:8080
echo Transport Service:  http://localhost:8081  
echo Ticketing Service:  http://localhost:8082
echo Payment Service:    http://localhost:8083
echo Notification Service: http://localhost:8084
echo Admin Service:      http://localhost:8085
echo MongoDB:            localhost:27017
echo Kafka:              localhost:9092
echo.
echo Test with: curl -X GET http://localhost:8080/passengers
echo.
pause
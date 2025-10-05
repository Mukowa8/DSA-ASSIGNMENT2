@echo off
echo ========================================
echo   Stopping Smart Ticketing System
echo ========================================
echo.

echo Stopping Docker containers...
docker-compose down

echo.
echo ========================================
echo      System stopped successfully!
echo ========================================
echo.
pause
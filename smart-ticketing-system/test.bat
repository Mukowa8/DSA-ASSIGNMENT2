@echo off
echo ========================================
echo   Testing Smart Ticketing System
echo ========================================
echo.

echo Testing Passenger Service...
curl -X GET http://localhost:8080/passengers
echo.

echo Testing Transport Service...
curl -X GET http://localhost:8081/routes
echo.

echo.
echo ========================================
echo        Test completed!
echo ========================================
echo.
pause
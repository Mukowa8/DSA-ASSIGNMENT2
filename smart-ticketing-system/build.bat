@echo off
echo ========================================
echo    Building Smart Ticketing System
echo ========================================
echo.

echo Building passenger service...
cd passenger-service
bal build --cloud=docker
if %errorlevel% neq 0 (
    echo Error building passenger service!
    exit /b 1
)
cd ..
echo.

echo Building transport service...
cd transport-service
bal build --cloud=docker
if %errorlevel% neq 0 (
    echo Error building transport service!
    exit /b 1
)
cd ..
echo.

echo Building ticketing service...
cd ticketing-service
bal build --cloud=docker
if %errorlevel% neq 0 (
    echo Error building ticketing service!
    exit /b 1
)
cd ..
echo.

echo Building payment service...
cd payment-service
bal build --cloud=docker
if %errorlevel% neq 0 (
    echo Error building payment service!
    exit /b 1
)
cd ..
echo.

echo Building notification service...
cd notification-service
bal build --cloud=docker
if %errorlevel% neq 0 (
    echo Error building notification service!
    exit /b 1
)
cd ..
echo.

echo Building admin service...
cd admin-service
bal build --cloud=docker
if %errorlevel% neq 0 (
    echo Error building admin service!
    exit /b 1
)
cd ..
echo.

echo ========================================
echo    All services built successfully!
echo ========================================
echo.
pause
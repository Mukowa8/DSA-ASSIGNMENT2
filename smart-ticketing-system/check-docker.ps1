Write-Host "=== Docker Environment Check ===" -ForegroundColor Green

# Check Docker version
try {
    $dockerVersion = docker --version
    Write-Host "✓ Docker: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker not found in PATH" -ForegroundColor Red
}

# Check Docker Compose version
try {
    $composeVersion = docker-compose --version
    Write-Host "✓ Docker Compose: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker Compose not found" -ForegroundColor Red
}

# Check if Docker daemon is running
Write-Host "`nChecking Docker daemon..." -ForegroundColor Yellow
try {
    $containers = docker ps 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Docker daemon is running" -ForegroundColor Green
    } else {
        Write-Host "✗ Docker daemon not running: $containers" -ForegroundColor Red
        Write-Host "Please start Docker Desktop first!" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Cannot connect to Docker daemon" -ForegroundColor Red
}

# Check docker-compose file
Write-Host "`nChecking docker-compose.yml..." -ForegroundColor Yellow
if (Test-Path "docker-compose.yml") {
    Write-Host "✓ docker-compose.yml found" -ForegroundColor Green
    
    # Check for version field
    $content = Get-Content "docker-compose.yml" -Raw
    if ($content -match "version:") {
        Write-Host "⚠ Warning: 'version' field found - this may cause issues" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ docker-compose.yml not found" -ForegroundColor Red
}

Write-Host "`n=== Instructions ===" -ForegroundColor Cyan
Write-Host "1. Make sure Docker Desktop is running" -ForegroundColor White
Write-Host "2. If issues persist, restart Docker Desktop" -ForegroundColor White
Write-Host "3. Run: .\start.bat" -ForegroundColor White
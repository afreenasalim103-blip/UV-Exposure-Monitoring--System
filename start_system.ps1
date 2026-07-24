param(
    [string]$AppToRun = "user_app"
)

Write-Host "=========================================="
Write-Host " UV-Sense System Startup Script"
Write-Host "=========================================="

# 1. Get the local IP Address
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi", "Ethernet" -ErrorAction SilentlyContinue | Sort-Object InterfaceMetric | Select-Object -First 1).IPAddress
if (-not $ipAddress) {
    # Fallback to any IPv4 address that isn't localhost
    $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne "127.0.0.1" } | Select-Object -First 1).IPAddress
}

Write-Host "Found Host IP Address: $ipAddress" -ForegroundColor Green

# 2. Update the .env file in the Flutter app to point to this IP
$envFilePath = ".\UV-Sense-main\$AppToRun\.env"
if (Test-Path $envFilePath) {
    # Read the existing content
    $envContent = Get-Content $envFilePath -Raw
    
    # Check if BACKEND_URL already exists and replace it, otherwise append
    $newBackendUrl = "BACKEND_URL=http://$($ipAddress):8000/api/predict/"
    if ($envContent -match "BACKEND_URL=.*") {
        $envContent = $envContent -replace "BACKEND_URL=.*", $newBackendUrl
    } else {
        $envContent += "`n$newBackendUrl"
    }
    Set-Content -Path $envFilePath -Value $envContent
    Write-Host "Updated .env file with BACKEND_URL: http://$($ipAddress):8000/api/predict/" -ForegroundColor Green
} else {
    Write-Host "Could not find .env file at $envFilePath. Ensure it exists if you need environment variables other than the backend URL." -ForegroundColor Yellow
    Set-Content -Path $envFilePath -Value "BACKEND_URL=http://$($ipAddress):8000/api/predict/"
    Write-Host "Created new .env file with BACKEND_URL." -ForegroundColor Green
}

# 3. Start Django Backend in a new terminal window
$djangoPath = ".\Skin_Type_Identifier"
Write-Host "Checking/Starting Django Backend..." -ForegroundColor Cyan

$backendCmd = @"
cd `"$djangoPath`"
if (!(Test-Path 'venv')) {
    Write-Host 'Virtual environment not found. Creating one...' -ForegroundColor Yellow
    python -m venv venv
}

Write-Host 'Checking backend requirements...' -ForegroundColor Cyan
if (Test-Path 'req.txt') {
    Write-Host 'Ensuring pip and setuptools are up-to-date...' -ForegroundColor Yellow
    .\venv\Scripts\python.exe -m pip install --upgrade pip setuptools wheel
    Write-Host 'Checking requirements from req.txt...' -ForegroundColor Yellow
    .\venv\Scripts\pip install -r req.txt
} elseif (Test-Path 'requirements.txt') {
    Write-Host 'Ensuring pip and setuptools are up-to-date...' -ForegroundColor Yellow
    .\venv\Scripts\python.exe -m pip install --upgrade pip setuptools wheel
    Write-Host 'Checking requirements from requirements.txt...' -ForegroundColor Yellow
    .\venv\Scripts\pip install -r requirements.txt
}

Write-Host 'Starting server...' -ForegroundColor Green
$env:TF_ENABLE_ONEDNN_OPTS = "0"
$env:TF_CPP_MIN_LOG_LEVEL = "2"
.\venv\Scripts\python manage.py runserver 0.0.0.0:8000
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCmd

# 4. Wait a few seconds for the backend to initialize
Start-Sleep -Seconds 3

# 5. Run Flutter App
$flutterPath = ".\UV-Sense-main\$AppToRun"
Write-Host "Starting Flutter App ($AppToRun)..." -ForegroundColor Cyan
Set-Location -Path $flutterPath
flutter run

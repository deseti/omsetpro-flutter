@echo off
REM Script untuk setup webhook testing dengan ngrok di Windows
REM Jalankan script ini untuk expose backend ke internet

echo 🚀 Setting up Midtrans webhook testing environment...

REM Check if ngrok is installed
where ngrok >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ ngrok not found. Please install ngrok first:
    echo    1. Download from https://ngrok.com/download
    echo    2. Extract and add to PATH
    echo    3. Run: ngrok authtoken YOUR_AUTH_TOKEN
    pause
    exit /b 1
)

REM Check if backend is running
echo 🔍 Checking if backend is running on port 3000...
curl -s http://localhost:3000 >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Backend not running on port 3000
    echo    Please start backend first: npm run start
    pause
    exit /b 1
)

echo ✅ Backend is running

REM Start ngrok
echo 🌐 Starting ngrok tunnel...
echo 📋 Your webhook URL will be: https://YOUR_NGROK_URL/midtrans/webhook
echo.
echo 🔧 Steps to configure webhook in Midtrans dashboard:
echo    1. Open https://dashboard.sandbox.midtrans.com/
echo    2. Go to Settings ^> Configuration
echo    3. Set Payment Notification URL to: https://YOUR_NGROK_URL/midtrans/webhook
echo    4. Save configuration
echo.
echo 🚀 Starting ngrok now...

.\ngrok.exe http 3000

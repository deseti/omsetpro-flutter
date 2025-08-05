#!/bin/bash

# Script untuk setup webhook testing dengan ngrok
# Jalankan script ini untuk expose backend ke internet

echo "🚀 Setting up Midtrans webhook testing environment..."

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo "❌ ngrok not found. Please install ngrok first:"
    echo "   1. Download from https://ngrok.com/download"
    echo "   2. Extract and add to PATH"
    echo "   3. Run: ngrok authtoken YOUR_AUTH_TOKEN"
    exit 1
fi

# Check if backend is running
echo "🔍 Checking if backend is running on port 3000..."
if ! curl -s http://localhost:3000 > /dev/null; then
    echo "❌ Backend not running on port 3000"
    echo "   Please start backend first: npm run start"
    exit 1
fi

echo "✅ Backend is running"

# Start ngrok
echo "🌐 Starting ngrok tunnel..."
echo "📋 Your webhook URL will be: https://YOUR_NGROK_URL/midtrans/webhook"
echo ""
echo "🔧 Steps to configure webhook in Midtrans dashboard:"
echo "   1. Open https://dashboard.sandbox.midtrans.com/"
echo "   2. Go to Settings > Configuration"
echo "   3. Set Payment Notification URL to: https://YOUR_NGROK_URL/midtrans/webhook"
echo "   4. Save configuration"
echo ""
echo "🚀 Starting ngrok now..."

ngrok http 3000

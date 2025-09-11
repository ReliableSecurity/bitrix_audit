#!/bin/bash

# 🚀 Стабильный запуск Bitrix24 Security Audit System
echo "🔥 Starting Bitrix24 Security Audit System..."

# Переход в директорию проекта
cd /home/akuma/Desktop/projects/bitrix_audit

# Активация виртуального окружения
source venv/bin/activate

# Убиваем старые процессы
echo "🧹 Killing old processes..."
pkill -f "python.*run.py" 2>/dev/null || true
sleep 2

# Очистка портов
echo "🔌 Checking port 5000..."
if lsof -i :5000 >/dev/null 2>&1; then
    echo "⚠️ Port 5000 is busy, killing processes..."
    lsof -ti :5000 | xargs kill -9 2>/dev/null || true
    sleep 2
fi

# Запуск сервера
echo "🚀 Starting server..."
echo "🌐 URL: http://localhost:5000"
echo "🔐 Login: admin / admin123"
echo ""
echo "📝 Press Ctrl+C to stop the server"
echo "=================================="

# Запуск без отправки в фон - чтобы работало стабильно
python run.py

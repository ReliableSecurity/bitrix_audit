#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
🛡️ Bitrix24 Security Audit System - Application Runner
Запуск веб-приложения для аудита безопасности
Author: AKUMA
"""

import os
import sys

# Добавляем текущую директорию в путь Python
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Импортируем приложение из файла app.py
import app as flask_app
app = flask_app.app

if __name__ == '__main__':
    print("""
╔══════════════════════════════════════════════════════════════════════════════╗
║                    🛡️  BITRIX24 SECURITY AUDIT SYSTEM                        ║
║                               Starting Server...                             ║
║                                 Author: AKUMA                                ║
╚══════════════════════════════════════════════════════════════════════════════╝

🔥 AKUMA Security System is starting up...
🌐 Server will be available at: http://localhost:5000
🔐 Default admin credentials: admin / admin123

💡 Tips:
   - Use Ctrl+C to stop the server
   - Check logs/ directory for application logs
   - Database will be created automatically on first run
   - Upload reports to reports/ directory
   
🚀 Ready to hack the planet? Let's go!
    """)
    
    try:
        # Создаём директории если их нет
        os.makedirs('app/database', exist_ok=True)
        os.makedirs('logs', exist_ok=True)
        os.makedirs('reports', exist_ok=True)
        os.makedirs('uploads', exist_ok=True)
        
        # Запускаем приложение
        app.run(
            host='0.0.0.0',
            port=5000,
            debug=True,
            use_reloader=True
        )
    except KeyboardInterrupt:
        print("\n\n🛑 Server stopped by user")
        print("Thanks for using AKUMA Security System!")
    except Exception as e:
        print(f"\n❌ Error starting server: {e}")
        sys.exit(1)

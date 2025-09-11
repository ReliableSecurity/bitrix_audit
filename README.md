# 🛡️ Bitrix24 Security Audit System

**Professional web platform for comprehensive security analysis of Bitrix24 corporate portals**

*Author: AKUMA*  
*Version: 1.1*  
*"In code we trust, in security we excel"*

---

## 🌍 Language / Язык

- [English](#english)
- [Русский](#русский)

---

## English

### 📋 Project Description

**Bitrix24 Security Audit System** is a professional web platform designed for conducting comprehensive security analysis of Bitrix24 corporate portals. The system combines automated vulnerability scanning, system auditing, and a user-friendly web interface for project and user management.

### ✨ Key Features

- 🔍 **Automated Vulnerability Scanning** - Real-time security issue detection
- 🖥️ **System Auditing** - Server and software configuration verification  
- 👥 **User Management** - Role-based access control system
- 📊 **Interactive Reporting** - Data visualization with charts and graphs
- 🌙 **Cyber Design** - Dark cybersecurity-themed interface
- 📁 **Project Management** - Organize audits by projects
- 🔐 **Secure Storage** - Encrypted data and report storage

### 🚀 Quick Start

#### Prerequisites
- Python 3.8+
- Linux/MacOS/Windows
- 4GB RAM (recommended)
- 1GB free disk space

#### Installation

1. **Clone the repository:**
```bash
git clone https://github.com/sweetpotatohack/Akuma_bitrix_audit.git
cd Akuma_bitrix_audit
```

2. **Create virtual environment:**
```bash
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate     # Windows
```

3. **Install dependencies:**
```bash
pip install -r requirements.txt
```

4. **Start the system:**
```bash
./start_server.sh
# or manually:
python run.py
```

5. **Open in browser:**
```
http://localhost:5000
```

#### 🔐 Default Login
- **Username:** `admin`
- **Password:** `admin123`

> ⚠️ **Important!** Change the admin password after first login!

### 🎯 How to Use

#### 1. 👨‍💼 User Management (Admin Only)
- Create users with different roles
- Assign project access permissions
- Monitor activity and sessions
- Export user data

**User Roles:**
- 👑 **Administrator** - Full system access
- 👤 **User** - Manage own projects
- 🔍 **Viewer** - View results only

#### 2. 📊 Project Management
1. **Create Project:**
   - Specify Bitrix24 portal URL
   - Add description and settings
   - Assign users

2. **Run Scanning:**
   - Automated vulnerability scanning
   - Upload system audit reports
   - Real-time monitoring

#### 3. 🔍 Vulnerability Scanning
**Automated checks:**
- SSL/TLS configuration
- Administrative panels
- Information leaks
- Security headers
- Bitrix-specific vulnerabilities

#### 4. 🖥️ System Auditing
**Components checked:**
- Operating system
- Web server (Apache/Nginx)
- PHP configuration
- MySQL/MariaDB
- File permissions
- System services

### 📁 Project Structure

```
Akuma_bitrix_audit/
├── 🗂️ app/                          # Main application
│   ├── 📂 models/                    # Database models
│   ├── 📂 templates/                 # HTML templates
│   ├── 📂 static/                    # Static files (CSS, JS)
│   └── 🗄️ database/                  # SQLite database
├── 📋 bitrix24_vulnerability_scanner.py  # Vulnerability scanner
├── 📋 bitrix24_system_check_json.sh      # System audit script
├── 🚀 start_server.sh               # Stable server launcher
├── 🏃 run.py                        # Entry point
└── 📊 reports/                      # Generated reports
```

### 🔧 Configuration

Create `.env` file:
```bash
# Flask Configuration
SECRET_KEY=your_super_secret_key_here
FLASK_ENV=development
FLASK_DEBUG=True

# Database
DATABASE_URL=sqlite:///app/database/bitrix_audit.db

# Security Settings  
SESSION_COOKIE_SECURE=True
SESSION_COOKIE_HTTPONLY=True
PERMANENT_SESSION_LIFETIME=3600
```

### 📊 API Endpoints

```bash
# Authentication
POST   /login                    # User login
GET    /logout                   # Logout

# User Management (Admin only)
GET    /users                    # List users
POST   /users/create             # Create user
DELETE /users/<id>               # Delete user

# Projects
GET    /projects                 # List projects
POST   /projects/create          # Create project
GET    /projects/<id>            # Project details
POST   /projects/<id>/scan       # Start scanning
POST   /projects/<id>/upload     # Upload report
DELETE /projects/<id>/delete     # Delete project (Admin only)

# API
GET    /api/stats                # System statistics
```

### 🛠️ Troubleshooting

**Server won't start:**
```bash
# Kill old processes
pkill -f python

# Check port
lsof -i :5000

# Restart
./start_server.sh
```

**Important Notes:**
- ❌ **Don't run in background** (`&`) - unstable
- ❌ **Don't close terminal** - server will stop
- ✅ Use **Ctrl+C** to stop server

### 🧪 Testing System Reports

1. Generate system audit report:
```bash
./bitrix24_system_check_json.sh
```

2. Upload the generated JSON file through web interface

3. View detailed system information on project page

---

## Русский

### 📋 Описание проекта

**Bitrix24 Security Audit System** — это профессиональная веб-платформа для проведения комплексного анализа безопасности корпоративных порталов Битрикс24. Система объединяет автоматизированное сканирование уязвимостей, системный аудит и удобный веб-интерфейс для управления проектами и пользователями.

### ✨ Ключевые возможности

- 🔍 **Автоматическое сканирование уязвимостей** — поиск проблем безопасности в реальном времени
- 🖥️ **Системный аудит** — проверка конфигурации сервера и программного обеспечения  
- 👥 **Управление пользователями** — система ролей и прав доступа
- 📊 **Интерактивная отчётность** — визуализация результатов с графиками и диаграммами
- 🌙 **Кибер-дизайн** — тёмная тема в стиле информационной безопасности
- 📁 **Управление проектами** — организация аудитов по проектам
- 🔐 **Безопасное хранение** — зашифрованное хранение данных и отчётов

### 🚀 Быстрый старт

#### Системные требования
- Python 3.8+
- Linux/MacOS/Windows
- 4GB RAM (рекомендуется)
- 1GB свободного места на диске

#### Установка

1. **Клонируйте репозиторий:**
```bash
git clone https://github.com/sweetpotatohack/Akuma_bitrix_audit.git
cd Akuma_bitrix_audit
```

2. **Создайте виртуальное окружение:**
```bash
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# или
venv\Scripts\activate     # Windows
```

3. **Установите зависимости:**
```bash
pip install -r requirements.txt
```

4. **Запустите систему:**
```bash
./start_server.sh
# или вручную:
python run.py
```

5. **Откройте в браузере:**
```
http://localhost:5000
```

#### 🔐 Данные для входа
- **Логин:** `admin`
- **Пароль:** `admin123`

> ⚠️ **Важно!** Смените пароль администратора после первого входа!

### 🎯 Использование системы

#### 1. 👨‍💼 Управление пользователями (только админ)
- Создание пользователей с различными ролями
- Назначение прав доступа к проектам  
- Контроль активности и сессий
- Экспорт данных пользователей

**Роли пользователей:**
- 👑 **Administrator** — полный доступ ко всем функциям
- 👤 **User** — управление собственными проектами
- 🔍 **Viewer** — только просмотр результатов

#### 2. 📊 Управление проектами
1. **Создание проекта:**
   - Указание URL портала Битрикс24
   - Описание и настройки проекта
   - Назначение пользователей

2. **Запуск сканирования:**
   - Автоматическое сканирование уязвимостей
   - Загрузка системных отчётов
   - Мониторинг процесса в реальном времени

#### 3. 🔍 Сканирование уязвимостей
**Автоматические проверки:**
- SSL/TLS конфигурация
- Административные панели
- Утечки информации
- Заголовки безопасности
- Специфичные уязвимости Битрикс

#### 4. 🖥️ Системный аудит
**Проверяемые компоненты:**
- Операционная система
- Веб-сервер (Apache/Nginx)
- PHP конфигурация
- MySQL/MariaDB
- Файловые разрешения
- Системные сервисы

### 🛠️ Устранение неполадок

**Сервер не запускается:**
```bash
# Убить старые процессы
pkill -f python

# Проверить порт
lsof -i :5000

# Перезапустить
./start_server.sh
```

**Важные заметки:**
- ❌ **НЕ запускайте в фоновом режиме** (`&`) — работает нестабильно
- ❌ **НЕ закрывайте терминал** — сервер остановится  
- ✅ Используйте **Ctrl+C** для остановки сервера

### 🧪 Тестирование системных отчётов

1. Сгенерируйте отчёт системного аудита:
```bash
./bitrix24_system_check_json.sh
```

2. Загрузите полученный JSON файл через веб-интерфейс

3. Просмотрите детальную информацию о системе на странице проекта

---

## 🔒 Security Features

- **Role-based Access Control (RBAC)**
- **Session Management**
- **Audit Logging**
- **Password Hashing (bcrypt)**
- **CSRF Protection**
- **SQL Injection Prevention**
- **XSS Protection**

## 📈 Future Development

- [ ] PDF Report Generation
- [ ] Email Notifications
- [ ] Scheduled Scans
- [ ] API Extensions
- [ ] Multi-language Support
- [ ] Integration with External Tools

## 🤝 Contributing

1. Fork the project
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**AKUMA**
- GitHub: [@sweetpotatohack](https://github.com/sweetpotatohack)
- Project: [Akuma_bitrix_audit](https://github.com/sweetpotatohack/Akuma_bitrix_audit)

---

⭐ **Star this repo if you find it useful!** ⭐

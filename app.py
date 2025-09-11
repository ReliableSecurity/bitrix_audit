#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
🛡️ Bitrix24 Security Audit System - Main Application
Веб-приложение для аудита безопасности Битрикс24
Author: AKUMA
"""

from flask import Flask, render_template, request, redirect, url_for, flash, jsonify, session
from flask_login import LoginManager, login_user, logout_user, login_required, current_user
from werkzeug.utils import secure_filename
from datetime import datetime
import os
import sys
import json
import subprocess
from dotenv import load_dotenv

# Загрузка переменных окружения
load_dotenv()

# Импорт моделей
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))
from models import init_db, User, Project, VulnerabilityScan, SystemReport, AuditLog, db

# Создание приложения
app = Flask(__name__, template_folder='app/templates', static_folder='app/static')
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'akuma_super_secret_key_2024')
# Создаём полный путь к базе данных
db_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'app', 'database', 'bitrix_audit.db')
app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{db_path}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['UPLOAD_FOLDER'] = 'uploads'
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

# Настройка Flask-Login
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'
login_manager.login_message = 'Для доступа к этой странице необходимо войти в систему.'
login_manager.login_message_category = 'warning'

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

# Инициализация базы данных
init_db(app)

def log_audit_action(action, resource, resource_id=None, details=None):
    """Логирование действий пользователей"""
    try:
        log = AuditLog(
            user_id=current_user.id if current_user.is_authenticated else None,
            action=action,
            resource=resource,
            resource_id=resource_id,
            details=details,
            ip_address=request.remote_addr,
            user_agent=request.headers.get('User-Agent', '')
        )
        db.session.add(log)
        db.session.commit()
    except Exception as e:
        print(f"Audit log error: {e}")

@app.route('/')
def index():
    """Главная страница"""
    if not current_user.is_authenticated:
        return redirect(url_for('login'))
    
    # Получение статистики
    stats = {
        'total_projects': Project.query.count(),
        'total_scans': VulnerabilityScan.query.count(),
        'total_reports': SystemReport.query.count(),
        'total_users': User.query.count()
    }
    
    # Последние проекты пользователя
    if current_user.is_admin():
        recent_projects = Project.query.order_by(Project.created_at.desc()).limit(5).all()
    else:
        recent_projects = [p for p in current_user.projects][:5]
    
    return render_template('dashboard.html', stats=stats, recent_projects=recent_projects)

@app.route('/login', methods=['GET', 'POST'])
def login():
    """Страница авторизации"""
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        
        user = User.query.filter_by(username=username).first()
        
        if user and user.check_password(password) and user.is_active:
            user.last_login = datetime.utcnow()
            db.session.commit()
            
            login_user(user, remember=True)
            log_audit_action('LOGIN', 'USER', user.id)
            
            next_page = request.args.get('next')
            if next_page:
                return redirect(next_page)
            return redirect(url_for('index'))
        else:
            flash('Неверные учетные данные', 'error')
            log_audit_action('LOGIN_FAILED', 'USER', details=f'Failed login attempt for user: {username}')
    
    return render_template('auth/login.html')

@app.route('/logout')
@login_required
def logout():
    """Выход из системы"""
    log_audit_action('LOGOUT', 'USER', current_user.id)
    logout_user()
    flash('Вы вышли из системы', 'info')
    return redirect(url_for('login'))

@app.route('/users')
@login_required
def users():
    """Страница управления пользователями (только для админов)"""
    if not current_user.is_admin():
        flash('Недостаточно прав доступа', 'error')
        return redirect(url_for('index'))
    
    users_list = User.query.all()
    return render_template('admin/users.html', users=users_list)

@app.route('/users/create', methods=['GET', 'POST'])
@login_required
def create_user():
    """Создание нового пользователя"""
    if not current_user.is_admin():
        flash('Недостаточно прав доступа', 'error')
        return redirect(url_for('index'))
    
    if request.method == 'POST':
        username = request.form['username']
        email = request.form['email']
        password = request.form['password']
        role = request.form['role']
        
        # Проверка на существующего пользователя
        existing_user = User.query.filter(
            (User.username == username) | (User.email == email)
        ).first()
        
        if existing_user:
            flash('Пользователь с таким именем или email уже существует', 'error')
        else:
            user = User(username=username, email=email, role=role)
            user.set_password(password)
            
            db.session.add(user)
            db.session.commit()
            
            log_audit_action('CREATE', 'USER', user.id, f'Created user: {username}')
            flash(f'Пользователь {username} создан успешно', 'success')
            return redirect(url_for('users'))
    
    return render_template('admin/create_user.html')

@app.route('/projects')
@login_required
def projects():
    """Страница проектов"""
    if current_user.is_admin():
        projects_list = Project.query.all()
    else:
        projects_list = current_user.projects
    
    return render_template('projects/list.html', projects=projects_list)

@app.route('/projects/create', methods=['GET', 'POST'])
@login_required
def create_project():
    """Создание нового проекта"""
    if request.method == 'POST':
        name = request.form['name']
        description = request.form['description']
        url = request.form['url']
        
        project = Project(
            name=name,
            description=description,
            url=url,
            created_by_id=current_user.id
        )
        
        db.session.add(project)
        db.session.flush()  # Получаем ID проекта
        
        # Добавляем создателя к проекту, если он не админ
        if not current_user.is_admin():
            project.users.append(current_user)
        
        db.session.commit()
        
        log_audit_action('CREATE', 'PROJECT', project.id, f'Created project: {name}')
        flash(f'Проект "{name}" создан успешно', 'success')
        return redirect(url_for('project_detail', project_id=project.id))
    
    return render_template('projects/create.html')

@app.route('/projects/<int:project_id>')
@login_required
def project_detail(project_id):
    """Детальная информация о проекте"""
    project = Project.query.get_or_404(project_id)
    
    # Проверка доступа
    if not current_user.can_access_project(project_id):
        flash('Недостаточно прав доступа к этому проекту', 'error')
        return redirect(url_for('projects'))
    
    # Получение последних сканирований
    latest_vuln_scan = project.get_latest_vulnerability_scan()
    latest_system_report = project.get_latest_system_report()
    
    return render_template('projects/detail.html', 
                         project=project,
                         latest_vuln_scan=latest_vuln_scan,
                         latest_system_report=latest_system_report)

@app.route('/projects/<int:project_id>/scan', methods=['POST'])
@login_required
def start_vulnerability_scan(project_id):
    """Запуск сканирования уязвимостей"""
    project = Project.query.get_or_404(project_id)
    
    if not current_user.can_access_project(project_id):
        return jsonify({'error': 'Access denied'}), 403
    
    try:
        # Запуск сканера в фоновом режиме
        scanner_path = os.path.join(os.getcwd(), 'bitrix24_vulnerability_scanner.py')
        result = subprocess.run([
            'python3', scanner_path, project.url
        ], capture_output=True, text=True, timeout=300)
        
        if result.returncode == 0:
            # Поиск сгенерированного файла отчёта
            report_files = [f for f in os.listdir('.') if f.startswith('bitrix24_scan_report_')]
            if report_files:
                latest_report = max(report_files, key=os.path.getctime)
                
                # Загрузка данных из отчёта
                with open(latest_report, 'r', encoding='utf-8') as f:
                    scan_data = json.load(f)
                
                # Сохранение в базу данных
                scan = VulnerabilityScan(
                    project_id=project_id,
                    scan_data=json.dumps(scan_data),
                    target_url=project.url,
                    status='completed'
                )
                
                db.session.add(scan)
                db.session.commit()
                
                # Перемещение отчёта в папку reports
                os.rename(latest_report, f'reports/{latest_report}')
                
                log_audit_action('SCAN', 'PROJECT', project_id, 'Vulnerability scan completed')
                return jsonify({'success': True, 'scan_id': scan.id})
        
        return jsonify({'error': 'Scan failed'}), 500
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/projects/<int:project_id>/upload_report', methods=['POST'])
@login_required
def upload_system_report(project_id):
    """Загрузка системного отчёта"""
    project = Project.query.get_or_404(project_id)
    
    if not current_user.can_access_project(project_id):
        flash('Недостаточно прав доступа к этому проекту', 'error')
        return redirect(url_for('projects'))
    
    if 'report_file' not in request.files:
        flash('Файл не выбран', 'error')
        return redirect(url_for('project_detail', project_id=project_id))
    
    file = request.files['report_file']
    report_date_str = request.form['report_date']
    
    if file.filename == '':
        flash('Файл не выбран', 'error')
        return redirect(url_for('project_detail', project_id=project_id))
    
    if file and file.filename.endswith('.json'):
        try:
            # Чтение и валидация JSON
            file_content = file.read().decode('utf-8')
            report_data = json.loads(file_content)
            
            # Парсинг даты
            report_date = datetime.strptime(report_date_str, '%Y-%m-%dT%H:%M')
            
            # Сохранение отчёта
            system_report = SystemReport(
                project_id=project_id,
                report_data=file_content,
                uploaded_by_id=current_user.id,
                report_date=report_date,
                filename=secure_filename(file.filename)
            )
            
            db.session.add(system_report)
            db.session.commit()
            
            log_audit_action('UPLOAD', 'SYSTEM_REPORT', system_report.id, f'Uploaded system report: {file.filename}')
            flash('Системный отчёт загружен успешно', 'success')
            
        except Exception as e:
            flash(f'Ошибка загрузки файла: {str(e)}', 'error')
    else:
        flash('Поддерживаются только JSON файлы', 'error')
    
    return redirect(url_for('project_detail', project_id=project_id))

@app.route('/projects/<int:project_id>/delete', methods=['POST'])
@login_required
def delete_project(project_id):
    """Удаление проекта (только для админа)"""
    if not current_user.is_admin():
        return jsonify({'error': 'Access denied'}), 403
    
    project = Project.query.get_or_404(project_id)
    
    try:
        # Удаляем связанные записи
        VulnerabilityScan.query.filter_by(project_id=project_id).delete()
        SystemReport.query.filter_by(project_id=project_id).delete()
        
        # Удаляем проект
        project_name = project.name
        db.session.delete(project)
        db.session.commit()
        
        log_audit_action('DELETE', 'PROJECT', project_id, f'Deleted project: {project_name}')
        return jsonify({'success': True, 'message': f'Проект "{project_name}" удален успешно'})
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@app.route('/api/stats')
@login_required
def api_stats():
    """API для получения статистики"""
    if current_user.is_admin():
        projects = Project.query.all()
    else:
        projects = current_user.projects
    
    stats = {
        'total_projects': len(projects),
        'active_projects': len([p for p in projects if p.status == 'active']),
        'total_vulnerabilities': 0,
        'critical_vulnerabilities': 0,
        'vulnerability_trends': []
    }
    
    for project in projects:
        vuln_stats = project.get_vulnerability_stats()
        stats['total_vulnerabilities'] += vuln_stats.get('total', 0)
        stats['critical_vulnerabilities'] += vuln_stats.get('critical', 0)
    
    return jsonify(stats)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)

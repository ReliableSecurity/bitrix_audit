#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
🛡️ Bitrix24 Security Audit System - Database Models
Модели данных для системы аудита безопасности
Author: AKUMA
"""

from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
import json

db = SQLAlchemy()

# Таблица связи пользователей и проектов (многие ко многим)
user_projects = db.Table('user_projects',
    db.Column('user_id', db.Integer, db.ForeignKey('users.id'), primary_key=True),
    db.Column('project_id', db.Integer, db.ForeignKey('projects.id'), primary_key=True)
)

class User(UserMixin, db.Model):
    """Модель пользователя системы"""
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(120), nullable=False)
    role = db.Column(db.String(20), nullable=False, default='user')  # admin, user, viewer
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login = db.Column(db.DateTime)
    
    # Связь с проектами
    projects = db.relationship('Project', secondary=user_projects, lazy='subquery',
                              backref=db.backref('users', lazy=True))
    
    def set_password(self, password):
        """Установка хэшированного пароля"""
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        """Проверка пароля"""
        return check_password_hash(self.password_hash, password)
    
    def is_admin(self):
        """Проверка, является ли пользователь админом"""
        return self.role == 'admin'
    
    def can_access_project(self, project_id):
        """Проверка доступа к проекту"""
        if self.is_admin():
            return True
        return any(p.id == project_id for p in self.projects)
    
    def to_dict(self):
        """Преобразование в словарь"""
        return {
            'id': self.id,
            'username': self.username,
            'email': self.email,
            'role': self.role,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'last_login': self.last_login.isoformat() if self.last_login else None
        }

class Project(db.Model):
    """Модель проекта аудита"""
    __tablename__ = 'projects'
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    description = db.Column(db.Text)
    url = db.Column(db.String(255), nullable=False)
    status = db.Column(db.String(20), nullable=False, default='active')  # active, inactive, archived
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    created_by_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    
    # Связи
    created_by = db.relationship('User', backref=db.backref('created_projects', lazy=True))
    vulnerability_scans = db.relationship('VulnerabilityScan', backref='project', lazy=True, cascade='all, delete-orphan')
    system_reports = db.relationship('SystemReport', backref='project', lazy=True, cascade='all, delete-orphan')
    
    def get_latest_vulnerability_scan(self):
        """Получение последнего сканирования уязвимостей"""
        return VulnerabilityScan.query.filter_by(project_id=self.id)\
                                     .order_by(VulnerabilityScan.created_at.desc())\
                                     .first()
    
    def get_latest_system_report(self):
        """Получение последнего системного отчёта"""
        return SystemReport.query.filter_by(project_id=self.id)\
                                 .order_by(SystemReport.created_at.desc())\
                                 .first()
    
    def get_vulnerability_stats(self):
        """Статистика уязвимостей"""
        latest_scan = self.get_latest_vulnerability_scan()
        if not latest_scan:
            return {'total': 0, 'critical': 0, 'high': 0, 'medium': 0, 'low': 0}
        
        return latest_scan.get_vulnerability_stats()
    
    def to_dict(self):
        """Преобразование в словарь"""
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'url': self.url,
            'status': self.status,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
            'created_by': self.created_by.username if self.created_by else None,
            'vulnerability_stats': self.get_vulnerability_stats()
        }

class VulnerabilityScan(db.Model):
    """Модель сканирования уязвимостей"""
    __tablename__ = 'vulnerability_scans'
    
    id = db.Column(db.Integer, primary_key=True)
    project_id = db.Column(db.Integer, db.ForeignKey('projects.id'), nullable=False)
    scan_data = db.Column(db.Text, nullable=False)  # JSON данные сканирования
    status = db.Column(db.String(20), nullable=False, default='completed')  # running, completed, failed
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    scan_duration = db.Column(db.Integer)  # Продолжительность в секундах
    target_url = db.Column(db.String(255), nullable=False)
    
    def get_scan_results(self):
        """Получение результатов сканирования"""
        try:
            return json.loads(self.scan_data)
        except:
            return {}
    
    def get_vulnerability_stats(self):
        """Получение статистики уязвимостей"""
        data = self.get_scan_results()
        return data.get('summary', {'total': 0, 'critical': 0, 'high': 0, 'medium': 0, 'low': 0})
    
    def get_vulnerabilities(self):
        """Получение списка уязвимостей"""
        data = self.get_scan_results()
        return data.get('vulnerabilities', [])
    
    def to_dict(self):
        """Преобразование в словарь"""
        return {
            'id': self.id,
            'project_id': self.project_id,
            'status': self.status,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'scan_duration': self.scan_duration,
            'target_url': self.target_url,
            'stats': self.get_vulnerability_stats(),
            'vulnerabilities': self.get_vulnerabilities()
        }

class SystemReport(db.Model):
    """Модель системного отчёта"""
    __tablename__ = 'system_reports'
    
    id = db.Column(db.Integer, primary_key=True)
    project_id = db.Column(db.Integer, db.ForeignKey('projects.id'), nullable=False)
    report_data = db.Column(db.Text, nullable=False)  # JSON данные отчёта
    uploaded_by_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    report_date = db.Column(db.DateTime, nullable=False)  # Дата когда был сгенерирован отчёт
    filename = db.Column(db.String(255))  # Оригинальное имя файла
    
    # Связи
    uploaded_by = db.relationship('User', backref=db.backref('uploaded_reports', lazy=True))
    
    def get_report_data(self):
        """Получение данных отчёта"""
        try:
            return json.loads(self.report_data)
        except:
            return {}
    
    def get_system_status(self):
        """Получение статуса системы"""
        data = self.get_report_data()
        # Логика анализа системного отчёта
        return {
            'os_info': data.get('os_info', {}),
            'hardware': data.get('hardware', {}),
            'software_versions': data.get('software_versions', {}),
            'security_status': data.get('security_status', {}),
            'services': data.get('services', {})
        }
    
    def to_dict(self):
        """Преобразование в словарь"""
        return {
            'id': self.id,
            'project_id': self.project_id,
            'uploaded_by': self.uploaded_by.username if self.uploaded_by else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'report_date': self.report_date.isoformat() if self.report_date else None,
            'filename': self.filename,
            'system_status': self.get_system_status()
        }

class AuditLog(db.Model):
    """Модель логов аудита"""
    __tablename__ = 'audit_logs'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    action = db.Column(db.String(50), nullable=False)
    resource = db.Column(db.String(50), nullable=False)
    resource_id = db.Column(db.Integer)
    details = db.Column(db.Text)
    ip_address = db.Column(db.String(45))
    user_agent = db.Column(db.String(255))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Связи
    user = db.relationship('User', backref=db.backref('audit_logs', lazy=True))
    
    def to_dict(self):
        """Преобразование в словарь"""
        return {
            'id': self.id,
            'user': self.user.username if self.user else 'System',
            'action': self.action,
            'resource': self.resource,
            'resource_id': self.resource_id,
            'details': self.details,
            'ip_address': self.ip_address,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

def init_db(app):
    """Инициализация базы данных"""
    db.init_app(app)
    
    with app.app_context():
        db.create_all()
        
        # Создание админа по умолчанию
        admin = User.query.filter_by(username='admin').first()
        if not admin:
            admin = User(
                username='admin',
                email='admin@localhost',
                role='admin'
            )
            admin.set_password('admin123')  # Потом поменяем через интерфейс
            db.session.add(admin)
            db.session.commit()
            print("🔥 Default admin created: admin/admin123")

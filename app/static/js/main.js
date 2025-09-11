/**
 * 🛡️ Bitrix24 Security Audit System - Main JavaScript
 * Interactive features and utilities for the cyber security interface
 * Author: AKUMA
 */

// Global variables
let currentTime;
let chartInstances = {};

// Initialize everything when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    initializeTime();
    initializeTooltips();
    initializeConfirmDialogs();
    initializeCharts();
    initializeNotifications();
});

/**
 * Time display functions
 */
function initializeTime() {
    updateTime();
    setInterval(updateTime, 1000);
}

function updateTime() {
    const now = new Date();
    const timeString = now.toLocaleString('ru-RU', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
    });
    
    const timeElement = document.getElementById('current-time');
    if(timeElement) {
        timeElement.textContent = timeString;
    }
}

/**
 * Bootstrap tooltips initialization
 */
function initializeTooltips() {
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function(tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });
}

/**
 * Confirmation dialogs for dangerous operations
 */
function initializeConfirmDialogs() {
    const dangerousButtons = document.querySelectorAll('.btn-danger[data-confirm]');
    
    dangerousButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            const message = this.getAttribute('data-confirm') || 'Вы уверены?';
            
            showConfirmDialog(message, () => {
                // If confirmed, proceed with the action
                if(this.getAttribute('href')) {
                    window.location.href = this.getAttribute('href');
                } else if(this.type === 'submit') {
                    this.closest('form').submit();
                }
            });
        });
    });
}

/**
 * Custom confirm dialog with cyber styling
 */
function showConfirmDialog(message, onConfirm) {
    const modal = document.createElement('div');
    modal.className = 'modal fade';
    modal.id = 'confirmModal';
    modal.innerHTML = `
        <div class="modal-dialog">
            <div class="modal-content bg-dark border-cyber">
                <div class="modal-header border-cyber">
                    <h5 class="modal-title text-cyber-primary">
                        <i class="fas fa-exclamation-triangle"></i> 
                        ПОДТВЕРЖДЕНИЕ ОПЕРАЦИИ
                    </h5>
                </div>
                <div class="modal-body">
                    <p class="text-light">${message}</p>
                    <div class="hacker-text">
                        <small>> OPERATION REQUIRES CONFIRMATION</small>
                    </div>
                </div>
                <div class="modal-footer border-cyber">
                    <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
                        <i class="fas fa-times"></i> ОТМЕНА
                    </button>
                    <button type="button" class="btn btn-danger" id="confirmBtn">
                        <i class="fas fa-check"></i> ПОДТВЕРДИТЬ
                    </button>
                </div>
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    
    const bootstrapModal = new bootstrap.Modal(modal);
    
    document.getElementById('confirmBtn').addEventListener('click', function() {
        onConfirm();
        bootstrapModal.hide();
    });
    
    modal.addEventListener('hidden.bs.modal', function() {
        document.body.removeChild(modal);
    });
    
    bootstrapModal.show();
}

/**
 * Charts initialization and utilities
 */
function initializeCharts() {
    // Configure Chart.js defaults for cyber theme
    Chart.defaults.color = '#f0f6fc';
    Chart.defaults.borderColor = '#30363d';
    Chart.defaults.backgroundColor = 'rgba(0, 255, 65, 0.1)';
}

/**
 * Create vulnerability severity chart
 */
function createVulnerabilityChart(canvasId, data) {
    const ctx = document.getElementById(canvasId);
    if(!ctx) return;
    
    // Destroy existing chart if it exists
    if(chartInstances[canvasId]) {
        chartInstances[canvasId].destroy();
    }
    
    chartInstances[canvasId] = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: ['Critical', 'High', 'Medium', 'Low'],
            datasets: [{
                data: [
                    data.critical || 0,
                    data.high || 0,
                    data.medium || 0,
                    data.low || 0
                ],
                backgroundColor: [
                    '#ff4444', // Critical - red
                    '#ffaa00', // High - orange
                    '#0099ff', // Medium - blue
                    '#00ff88'  // Low - green
                ],
                borderWidth: 2,
                borderColor: '#00ff41'
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: {
                        color: '#f0f6fc',
                        font: {
                            family: 'Courier New'
                        }
                    }
                },
                tooltip: {
                    backgroundColor: 'rgba(0, 0, 0, 0.8)',
                    titleColor: '#00ff41',
                    bodyColor: '#f0f6fc',
                    borderColor: '#00ff41',
                    borderWidth: 1
                }
            }
        }
    });
}

/**
 * Create trend line chart
 */
function createTrendChart(canvasId, data) {
    const ctx = document.getElementById(canvasId);
    if(!ctx) return;
    
    if(chartInstances[canvasId]) {
        chartInstances[canvasId].destroy();
    }
    
    chartInstances[canvasId] = new Chart(ctx, {
        type: 'line',
        data: {
            labels: data.labels,
            datasets: [{
                label: 'Уязвимости',
                data: data.values,
                borderColor: '#00ff41',
                backgroundColor: 'rgba(0, 255, 65, 0.1)',
                borderWidth: 2,
                fill: true,
                tension: 0.4
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true,
                    grid: {
                        color: '#30363d'
                    },
                    ticks: {
                        color: '#f0f6fc'
                    }
                },
                x: {
                    grid: {
                        color: '#30363d'
                    },
                    ticks: {
                        color: '#f0f6fc'
                    }
                }
            },
            plugins: {
                legend: {
                    labels: {
                        color: '#f0f6fc',
                        font: {
                            family: 'Courier New'
                        }
                    }
                }
            }
        }
    });
}

/**
 * Notification system
 */
function initializeNotifications() {
    // Auto-hide alerts after 5 seconds
    const alerts = document.querySelectorAll('.alert');
    alerts.forEach(alert => {
        setTimeout(() => {
            if(alert && alert.parentNode) {
                const bsAlert = new bootstrap.Alert(alert);
                bsAlert.close();
            }
        }, 5000);
    });
}

/**
 * Show custom notification
 */
function showNotification(message, type = 'info') {
    const notificationContainer = document.getElementById('notification-container') || createNotificationContainer();
    
    const notification = document.createElement('div');
    notification.className = `alert alert-${type} alert-dismissible fade show cyber-alert`;
    notification.innerHTML = `
        <i class="fas fa-${getIconByType(type)}"></i>
        ${message}
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="alert"></button>
    `;
    
    notificationContainer.appendChild(notification);
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
        if(notification && notification.parentNode) {
            const bsAlert = new bootstrap.Alert(notification);
            bsAlert.close();
        }
    }, 5000);
}

function createNotificationContainer() {
    const container = document.createElement('div');
    container.id = 'notification-container';
    container.style.position = 'fixed';
    container.style.top = '80px';
    container.style.right = '20px';
    container.style.zIndex = '9999';
    container.style.maxWidth = '400px';
    document.body.appendChild(container);
    return container;
}

function getIconByType(type) {
    const icons = {
        success: 'check-circle',
        danger: 'exclamation-triangle',
        warning: 'exclamation-circle',
        info: 'info-circle'
    };
    return icons[type] || 'info-circle';
}

/**
 * AJAX utilities
 */
function makeRequest(url, method = 'GET', data = null) {
    return new Promise((resolve, reject) => {
        const xhr = new XMLHttpRequest();
        xhr.open(method, url);
        xhr.setRequestHeader('Content-Type', 'application/json');
        
        // Add CSRF token if available
        const csrfToken = document.querySelector('meta[name="csrf-token"]');
        if(csrfToken) {
            xhr.setRequestHeader('X-CSRFToken', csrfToken.getAttribute('content'));
        }
        
        xhr.onload = function() {
            if(xhr.status >= 200 && xhr.status < 300) {
                try {
                    resolve(JSON.parse(xhr.responseText));
                } catch(e) {
                    resolve(xhr.responseText);
                }
            } else {
                reject(new Error(`HTTP ${xhr.status}: ${xhr.statusText}`));
            }
        };
        
        xhr.onerror = function() {
            reject(new Error('Network error'));
        };
        
        xhr.send(data ? JSON.stringify(data) : null);
    });
}

/**
 * Vulnerability scan functions
 */
function startVulnerabilityScan(projectId) {
    const button = document.getElementById('scan-button');
    const originalText = button.innerHTML;
    
    // Update button state
    button.disabled = true;
    button.innerHTML = '<i class="fas fa-spinner fa-spin"></i> СКАНИРОВАНИЕ...';
    
    makeRequest(`/projects/${projectId}/scan`, 'POST')
        .then(response => {
            if(response.success) {
                showNotification('Сканирование запущено успешно!', 'success');
                // Reload page after 3 seconds
                setTimeout(() => {
                    window.location.reload();
                }, 3000);
            } else {
                throw new Error(response.error || 'Scan failed');
            }
        })
        .catch(error => {
            showNotification(`Ошибка сканирования: ${error.message}`, 'danger');
            button.disabled = false;
            button.innerHTML = originalText;
        });
}

/**
 * File upload with progress
 */
function setupFileUpload() {
    const fileInputs = document.querySelectorAll('input[type="file"]');
    
    fileInputs.forEach(input => {
        input.addEventListener('change', function() {
            const file = this.files[0];
            if(file) {
                validateFile(file, this);
            }
        });
    });
}

function validateFile(file, input) {
    const maxSize = 16 * 1024 * 1024; // 16MB
    const allowedTypes = ['application/json'];
    
    if(file.size > maxSize) {
        showNotification('Файл слишком большой. Максимальный размер: 16MB', 'danger');
        input.value = '';
        return false;
    }
    
    if(!allowedTypes.includes(file.type)) {
        showNotification('Поддерживаются только JSON файлы', 'danger');
        input.value = '';
        return false;
    }
    
    // Show file info
    const fileInfo = document.createElement('div');
    fileInfo.className = 'mt-2 text-cyber-primary';
    fileInfo.innerHTML = `
        <small>
            <i class="fas fa-file-alt"></i> 
            ${file.name} (${(file.size / 1024).toFixed(1)} KB)
        </small>
    `;
    
    // Remove existing file info
    const existingInfo = input.parentNode.querySelector('.file-info');
    if(existingInfo) {
        existingInfo.remove();
    }
    
    fileInfo.className += ' file-info';
    input.parentNode.appendChild(fileInfo);
    
    return true;
}

/**
 * Data table enhancements
 */
function enhanceDataTables() {
    const tables = document.querySelectorAll('.table');
    
    tables.forEach(table => {
        // Add sorting capability
        const headers = table.querySelectorAll('th[data-sort]');
        headers.forEach(header => {
            header.style.cursor = 'pointer';
            header.addEventListener('click', function() {
                sortTable(table, this);
            });
        });
        
        // Add search if search box exists
        const searchBox = document.querySelector(`#search-${table.id}`);
        if(searchBox) {
            searchBox.addEventListener('input', function() {
                filterTable(table, this.value);
            });
        }
    });
}

function sortTable(table, header) {
    const column = Array.from(header.parentNode.children).indexOf(header);
    const tbody = table.querySelector('tbody');
    const rows = Array.from(tbody.querySelectorAll('tr'));
    
    const isAscending = header.classList.contains('sort-asc');
    
    // Remove all sort classes
    header.parentNode.querySelectorAll('th').forEach(th => {
        th.classList.remove('sort-asc', 'sort-desc');
    });
    
    // Add appropriate sort class
    header.classList.add(isAscending ? 'sort-desc' : 'sort-asc');
    
    rows.sort((a, b) => {
        const aText = a.cells[column].textContent.trim();
        const bText = b.cells[column].textContent.trim();
        
        const comparison = aText.localeCompare(bText, undefined, { numeric: true });
        return isAscending ? -comparison : comparison;
    });
    
    rows.forEach(row => tbody.appendChild(row));
}

function filterTable(table, searchTerm) {
    const tbody = table.querySelector('tbody');
    const rows = tbody.querySelectorAll('tr');
    
    rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        const matches = text.includes(searchTerm.toLowerCase());
        row.style.display = matches ? '' : 'none';
    });
}

/**
 * Keyboard shortcuts
 */
document.addEventListener('keydown', function(e) {
    // Ctrl+/ or Cmd+/ for help
    if((e.ctrlKey || e.metaKey) && e.key === '/') {
        e.preventDefault();
        showKeyboardShortcuts();
    }
    
    // Escape to close modals
    if(e.key === 'Escape') {
        const modals = document.querySelectorAll('.modal.show');
        modals.forEach(modal => {
            const bsModal = bootstrap.Modal.getInstance(modal);
            if(bsModal) bsModal.hide();
        });
    }
});

function showKeyboardShortcuts() {
    const modal = document.createElement('div');
    modal.className = 'modal fade';
    modal.innerHTML = `
        <div class="modal-dialog">
            <div class="modal-content bg-dark border-cyber">
                <div class="modal-header border-cyber">
                    <h5 class="modal-title text-cyber-primary">
                        <i class="fas fa-keyboard"></i> 
                        ГОРЯЧИЕ КЛАВИШИ
                    </h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <div class="row">
                        <div class="col-md-6">
                            <h6 class="text-cyber-accent">Общие</h6>
                            <ul class="list-unstyled">
                                <li><kbd>Ctrl</kbd> + <kbd>/</kbd> - Справка</li>
                                <li><kbd>Esc</kbd> - Закрыть модальное окно</li>
                            </ul>
                        </div>
                        <div class="col-md-6">
                            <h6 class="text-cyber-accent">Навигация</h6>
                            <ul class="list-unstyled">
                                <li><kbd>Alt</kbd> + <kbd>D</kbd> - Dashboard</li>
                                <li><kbd>Alt</kbd> + <kbd>P</kbd> - Проекты</li>
                                <li><kbd>Alt</kbd> + <kbd>U</kbd> - Пользователи (админ)</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    const bsModal = new bootstrap.Modal(modal);
    
    modal.addEventListener('hidden.bs.modal', function() {
        document.body.removeChild(modal);
    });
    
    bsModal.show();
}

/**
 * Auto-save functionality for forms
 */
function initializeAutoSave() {
    const forms = document.querySelectorAll('form[data-autosave]');
    
    forms.forEach(form => {
        const inputs = form.querySelectorAll('input, textarea, select');
        inputs.forEach(input => {
            input.addEventListener('input', function() {
                saveFormData(form);
            });
        });
        
        // Load saved data
        loadFormData(form);
    });
}

function saveFormData(form) {
    const formData = new FormData(form);
    const data = {};
    
    for(let [key, value] of formData.entries()) {
        data[key] = value;
    }
    
    localStorage.setItem(`form-${form.id}`, JSON.stringify(data));
}

function loadFormData(form) {
    const savedData = localStorage.getItem(`form-${form.id}`);
    if(savedData) {
        const data = JSON.parse(savedData);
        
        for(let [key, value] of Object.entries(data)) {
            const input = form.querySelector(`[name="${key}"]`);
            if(input && input.type !== 'password') {
                input.value = value;
            }
        }
    }
}

// Initialize additional features
document.addEventListener('DOMContentLoaded', function() {
    setupFileUpload();
    enhanceDataTables();
    initializeAutoSave();
});

// Export functions for global use
window.AKUMA = {
    startVulnerabilityScan,
    showNotification,
    showConfirmDialog,
    createVulnerabilityChart,
    createTrendChart,
    makeRequest
};

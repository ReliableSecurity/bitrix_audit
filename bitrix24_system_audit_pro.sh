#!/bin/bash

# 🛡️ Bitrix24 Security Audit - Professional System Check Script
# Полный системный аудит с проверкой всех критически важных компонентов
# Author: AKUMA
# Version: 3.0 PRO EDITION

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Генерируем имя файла отчёта с временной меткой
REPORT_FILE="system_audit_report_$(date +%Y%m%d_%H%M%S).json"

echo -e "${PURPLE}🚀 AKUMA'S BITRIX24 SECURITY AUDIT PRO v3.0${NC}"
echo "========================================================="
echo -e "📄 Отчёт будет сохранён в: ${GREEN}${REPORT_FILE}${NC}"
echo ""

# Функция для логирования с временной меткой
log_info() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] ⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ❌ $1${NC}"
}

log_success() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] ✅ $1${NC}"
}

# Функция для проверки статуса с умными алгоритмами
check_status_smart() {
    local current="$1"
    local recommended="$2"
    local type="$3"
    local result=""
    
    case "$type" in
        "version_compare")
            # Умное сравнение версий
            if [[ "$current" == "NOT_INSTALLED" ]] || [[ "$current" == "Unknown" ]]; then
                result="NOT_FOUND"
            elif [[ "$current" =~ ^[0-9]+\.[0-9]+ ]]; then
                current_major=$(echo "$current" | cut -d. -f1)
                current_minor=$(echo "$current" | cut -d. -f2)
                rec_major=$(echo "$recommended" | cut -d. -f1)
                rec_minor=$(echo "$recommended" | cut -d. -f2)
                
                if (( current_major > rec_major )) || (( current_major == rec_major && current_minor >= rec_minor )); then
                    result="OK"
                else
                    result="NEEDS_UPDATE"
                fi
            else
                result="VERSION_CHECK_FAILED"
            fi
            ;;
        "numeric")
            if [[ "$current" =~ ^[0-9]+\.?[0-9]*$ ]]; then
                if (( $(echo "$current >= $recommended" | bc -l 2>/dev/null || echo "0") )); then
                    result="OK"
                else
                    result="CRITICAL"
                fi
            else
                result="INVALID_VALUE"
            fi
            ;;
        "service_active")
            case "$current" in
                "active"|"running"|"enabled"|"RUNNING"|"ACTIVE")
                    result="ACTIVE"
                    ;;
                "inactive"|"stopped"|"disabled"|"STOPPED")
                    result="INACTIVE"
                    ;;
                "not-found"|"NOT_INSTALLED")
                    result="NOT_INSTALLED"
                    ;;
                *)
                    result="UNKNOWN_STATUS"
                    ;;
            esac
            ;;
        "port_status")
            if [[ "$current" == "OPEN" ]]; then
                result="OPEN"
            else
                result="CLOSED"
            fi
            ;;
    esac
    
    echo "$result"
}

# Начинаем сбор данных
log_info "📋 Сбор базовой информации о системе"

# Получаем детальную информацию о системе
OS_NAME=$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo "Unknown")
OS_VERSION=$(cat /etc/os-release 2>/dev/null | grep VERSION_ID | cut -d'"' -f2 || echo "Unknown")
KERNEL_VERSION=$(uname -r)
ARCHITECTURE=$(uname -m)
HOSTNAME=$(hostname)
UPTIME=$(uptime -p 2>/dev/null || uptime)

log_success "OS: $OS_NAME ($OS_VERSION)"
log_success "Kernel: $KERNEL_VERSION"
log_success "Architecture: $ARCHITECTURE"
log_success "Uptime: $UPTIME"

echo ""
log_info "💾 Анализ аппаратных ресурсов"

# Детальная информация о CPU
CPU_CORES=$(nproc)
CPU_MODEL=$(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs 2>/dev/null || echo "Unknown")
CPU_FREQUENCY=$(grep 'cpu MHz' /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs 2>/dev/null || echo "Unknown")
CPU_ARCHITECTURE=$(lscpu | grep Architecture | awk '{print $2}' 2>/dev/null || echo "Unknown")
CPU_STATUS=$(check_status_smart "$CPU_CORES" "4" "numeric")

log_success "CPU: $CPU_MODEL"
log_success "Cores: $CPU_CORES ($CPU_STATUS)"
log_success "Frequency: ${CPU_FREQUENCY}MHz"
log_success "Architecture: $CPU_ARCHITECTURE"

# Детальная информация о RAM
RAM_TOTAL=$(free -g | awk '/^Mem:/{print $2}' 2>/dev/null || echo "0")
RAM_USED=$(free -g | awk '/^Mem:/{print $3}' 2>/dev/null || echo "0")
RAM_FREE=$(free -g | awk '/^Mem:/{print $7}' 2>/dev/null || echo "0")
RAM_CACHED=$(free -g | awk '/^Mem:/{print $6}' 2>/dev/null || echo "0")
RAM_STATUS=$(check_status_smart "$RAM_TOTAL" "8" "numeric")

log_success "RAM Total: ${RAM_TOTAL}GB ($RAM_STATUS)"
log_success "RAM Used: ${RAM_USED}GB | Free: ${RAM_FREE}GB | Cached: ${RAM_CACHED}GB"

# Детальная информация о дисках
DISK_ROOT=$(df -h / | tail -1 | awk '{print $2 "," $3 "," $4 "," $5}' 2>/dev/null || echo "Unknown")
DISK_TOTAL=$(df --total | tail -1 | awk '{print $2}' 2>/dev/null | numfmt --to=iec || echo "Unknown")
DISK_INODES=$(df -i / | tail -1 | awk '{print $5}' 2>/dev/null || echo "Unknown")

log_success "Root Disk: $DISK_ROOT"
log_success "Total Storage: $DISK_TOTAL"
log_success "Inode Usage: $DISK_INODES"

echo ""
log_info "🔧 Проверка программного обеспечения"

# PHP - улучшенная проверка
PHP_VERSION="NOT_INSTALLED"
PHP_STATUS="NOT_FOUND"
PHP_MODULES=""
if command -v php &> /dev/null; then
    PHP_VERSION=$(php -r "echo PHP_VERSION;" 2>/dev/null || echo "Unknown")
    PHP_STATUS=$(check_status_smart "$PHP_VERSION" "8.1" "version_compare")
    # Проверяем критически важные модули для Битрикса
    PHP_MODULES=$(php -m 2>/dev/null | grep -E "(mysqli|pdo_mysql|mbstring|xml|zip|curl|gd|json|openssl)" | tr '\n' ',' | sed 's/,$//' || echo "unknown")
    log_success "PHP: $PHP_VERSION ($PHP_STATUS)"
    log_success "PHP Modules: $PHP_MODULES"
else
    log_warn "PHP: NOT INSTALLED"
fi

# MySQL/MariaDB - ИСПРАВЛЕННАЯ проверка
MYSQL_VERSION="NOT_INSTALLED"
MYSQL_STATUS="NOT_FOUND"
MYSQL_SERVICE_STATUS="NOT_INSTALLED"
MYSQL_ROOT_ACCESS="NOT_TESTED"

# Проверяем MySQL
if command -v mysql &> /dev/null; then
    # Получаем версию MySQL/MariaDB правильным способом
    MYSQL_VERSION_RAW=$(mysql --version 2>/dev/null)
    if [[ "$MYSQL_VERSION_RAW" == *"MariaDB"* ]]; then
        MYSQL_VERSION=$(echo "$MYSQL_VERSION_RAW" | grep -oP 'MariaDB \K[0-9]+\.[0-9]+\.[0-9]+' || echo "Unknown")
        MYSQL_TYPE="MariaDB"
    else
        MYSQL_VERSION=$(echo "$MYSQL_VERSION_RAW" | grep -oP 'mysql\s+Ver\s+\K[0-9]+\.[0-9]+\.[0-9]+' || echo "Unknown")
        MYSQL_TYPE="MySQL"
    fi
    MYSQL_STATUS=$(check_status_smart "$MYSQL_VERSION" "5.7" "version_compare")
    log_success "$MYSQL_TYPE: $MYSQL_VERSION ($MYSQL_STATUS)"
elif command -v mariadb &> /dev/null; then
    MYSQL_VERSION=$(mariadb --version 2>/dev/null | grep -oP 'mariadb\s+Ver\s+\K[0-9]+\.[0-9]+\.[0-9]+' || echo "Unknown")
    MYSQL_STATUS=$(check_status_smart "$MYSQL_VERSION" "10.3" "version_compare")
    MYSQL_TYPE="MariaDB"
    log_success "MariaDB: $MYSQL_VERSION ($MYSQL_STATUS)"
else
    log_warn "MySQL/MariaDB: NOT INSTALLED"
fi

# Проверяем статус сервиса MySQL/MariaDB
for service in "mysql" "mariadb" "mysqld"; do
    if systemctl list-unit-files 2>/dev/null | grep -q "^$service.service"; then
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            MYSQL_SERVICE_STATUS="RUNNING"
            log_success "MySQL Service ($service): RUNNING"
        else
            MYSQL_SERVICE_STATUS="STOPPED"
            log_warn "MySQL Service ($service): STOPPED"
        fi
        break
    fi
done

# Apache - улучшенная проверка
APACHE_VERSION="NOT_INSTALLED"
APACHE_STATUS="NOT_FOUND"
APACHE_MODULES=""
if command -v apache2 &> /dev/null; then
    APACHE_VERSION=$(apache2 -v 2>/dev/null | head -1 | grep -oP 'Apache/\K[0-9]+\.[0-9]+\.[0-9]+' || echo "Unknown")
    APACHE_STATUS=$(check_status_smart "$APACHE_VERSION" "2.4" "version_compare")
    APACHE_MODULES=$(apache2ctl -M 2>/dev/null | grep -E "(rewrite|ssl|headers)" | wc -l || echo "0")
    log_success "Apache: $APACHE_VERSION ($APACHE_STATUS)"
    log_success "Apache Modules Loaded: $APACHE_MODULES critical modules"
elif command -v httpd &> /dev/null; then
    APACHE_VERSION=$(httpd -v 2>/dev/null | head -1 | grep -oP 'Apache/\K[0-9]+\.[0-9]+\.[0-9]+' || echo "Unknown")
    APACHE_STATUS=$(check_status_smart "$APACHE_VERSION" "2.4" "version_compare")
    log_success "Apache: $APACHE_VERSION ($APACHE_STATUS)"
else
    log_warn "Apache: NOT INSTALLED"
fi

# Nginx - улучшенная проверка
NGINX_VERSION="NOT_INSTALLED"
NGINX_STATUS="NOT_FOUND"
NGINX_CONFIG_TEST=""
if command -v nginx &> /dev/null; then
    NGINX_VERSION=$(nginx -v 2>&1 | grep -oP 'nginx/\K[0-9]+\.[0-9]+\.[0-9]+' || echo "Unknown")
    NGINX_STATUS=$(check_status_smart "$NGINX_VERSION" "1.18" "version_compare")
    NGINX_CONFIG_TEST=$(nginx -t 2>&1 | grep -q "successful" && echo "OK" || echo "FAILED")
    log_success "Nginx: $NGINX_VERSION ($NGINX_STATUS)"
    log_success "Nginx Config Test: $NGINX_CONFIG_TEST"
else
    log_warn "Nginx: NOT INSTALLED"
fi

echo ""
log_info "🌐 Сетевая конфигурация и порты"

# Улучшенная проверка портов
declare -A PORT_STATUS
critical_ports=(80 443 22 3306 25 587 993 995)

for port in "${critical_ports[@]}"; do
    if ss -tuln 2>/dev/null | grep -q ":$port "; then
        PORT_STATUS[$port]="OPEN"
        # Определяем что слушает порт
        SERVICE_ON_PORT=$(ss -tulpn 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'"' -f2 | head -1)
        log_success "Port $port: OPEN (Service: ${SERVICE_ON_PORT:-Unknown})"
    else
        PORT_STATUS[$port]="CLOSED"
        log_warn "Port $port: CLOSED"
    fi
done

# Проверка сетевых интерфейсов
NETWORK_INTERFACES=$(ip link show | grep -E "^[0-9]+" | awk -F': ' '{print $2}' | grep -v lo | tr '\n' ',' | sed 's/,$//')
EXTERNAL_IP=$(curl -s --max-time 5 http://ipinfo.io/ip 2>/dev/null || echo "Unknown")
INTERNAL_IP=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7}' | head -1 || echo "Unknown")

log_success "Network Interfaces: $NETWORK_INTERFACES"
log_success "Internal IP: $INTERNAL_IP"
log_success "External IP: $EXTERNAL_IP"

echo ""
log_info "📊 Метрики производительности"

# Load Average с интерпретацией
LOAD_1MIN=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs 2>/dev/null || echo "0")
LOAD_5MIN=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $2}' | xargs 2>/dev/null || echo "0")
LOAD_15MIN=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $3}' | xargs 2>/dev/null || echo "0")

LOAD_STATUS="OK"
if (( $(echo "$LOAD_1MIN > $CPU_CORES" | bc -l 2>/dev/null || echo "0") )); then
    LOAD_STATUS="HIGH"
fi

log_success "Load Average: $LOAD_1MIN, $LOAD_5MIN, $LOAD_15MIN ($LOAD_STATUS)"

# Детальное использование памяти
MEM_USAGE_PERCENT=$(free | grep Mem | awk '{printf("%.1f"), $3/$2 * 100.0}' 2>/dev/null || echo "0")
SWAP_USAGE_PERCENT=$(free | grep Swap | awk '{printf("%.1f"), $3/$2 * 100.0}' 2>/dev/null || echo "0")

log_success "Memory Usage: ${MEM_USAGE_PERCENT}%"
log_success "Swap Usage: ${SWAP_USAGE_PERCENT}%"

# Статистика дискового I/O
DISK_IO_STATS=""
if command -v iostat &> /dev/null; then
    DISK_IO_STATS=$(iostat -x 1 1 2>/dev/null | tail -n +4 | head -5 | awk '{print $1":"$4":"$5}' | tr '\n' '|' | sed 's/|$//')
    log_success "Disk I/O Stats: $DISK_IO_STATS"
else
    log_warn "iostat not available - install sysstat package"
fi

echo ""
log_info "🔒 РАСШИРЕННАЯ ПРОВЕРКА БЕЗОПАСНОСТИ"

# SELinux - ИСПРАВЛЕННАЯ проверка
SELINUX_STATUS="NOT_AVAILABLE"
SELINUX_MODE="UNKNOWN"
if command -v getenforce &> /dev/null; then
    SELINUX_STATUS="AVAILABLE"
    SELINUX_MODE=$(getenforce 2>/dev/null || echo "UNKNOWN")
    if [[ -f /etc/selinux/config ]]; then
        SELINUX_CONFIG=$(grep "^SELINUX=" /etc/selinux/config | cut -d= -f2)
        log_success "SELinux: $SELINUX_MODE (Config: $SELINUX_CONFIG)"
    else
        log_success "SELinux: $SELINUX_MODE"
    fi
else
    log_warn "SELinux: NOT AVAILABLE"
fi

# iptables - ПРАВИЛЬНАЯ проверка
IPTABLES_STATUS="NOT_CONFIGURED"
IPTABLES_RULES_COUNT=0
if command -v iptables &> /dev/null; then
    IPTABLES_RULES_COUNT=$(iptables -L -n 2>/dev/null | grep -c "^ACCEPT\|^DROP\|^REJECT" || echo "0")
    # Убираем возможные переводы строк
    IPTABLES_RULES_COUNT=$(echo "$IPTABLES_RULES_COUNT" | tr -d '\n' | head -c 10)
    if [[ $IPTABLES_RULES_COUNT -gt 3 ]]; then  # Больше стандартных policy правил
        IPTABLES_STATUS="CONFIGURED"
        log_success "iptables: CONFIGURED ($IPTABLES_RULES_COUNT rules)"
    else
        IPTABLES_STATUS="DEFAULT_POLICY_ONLY"
        log_warn "iptables: DEFAULT POLICY ONLY"
    fi
    
    # Проверяем IPv6 тоже
    IP6TABLES_RULES_COUNT=$(ip6tables -L -n 2>/dev/null | grep -c "^ACCEPT\|^DROP\|^REJECT" || echo "0")
    IP6TABLES_RULES_COUNT=$(echo "$IP6TABLES_RULES_COUNT" | tr -d '\n' | head -c 10)
    log_success "ip6tables: $IP6TABLES_RULES_COUNT rules"
else
    log_error "iptables: NOT FOUND"
fi

# UFW проверка
UFW_STATUS="NOT_INSTALLED"
UFW_RULES_COUNT=0
if command -v ufw &> /dev/null; then
    UFW_STATUS_RAW=$(ufw status 2>/dev/null)
    if echo "$UFW_STATUS_RAW" | grep -q "Status: active"; then
        UFW_STATUS="ACTIVE"
        UFW_RULES_COUNT=$(echo "$UFW_STATUS_RAW" | grep -E "^[0-9]" | wc -l)
        log_success "UFW: ACTIVE ($UFW_RULES_COUNT rules)"
    else
        UFW_STATUS="INACTIVE"
        log_warn "UFW: INACTIVE"
    fi
else
    log_warn "UFW: NOT INSTALLED"
fi

# firewalld проверка
FIREWALLD_STATUS="NOT_INSTALLED"
FIREWALLD_ZONES=""
if command -v firewalld &> /dev/null || command -v firewall-cmd &> /dev/null; then
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        FIREWALLD_STATUS="ACTIVE"
        FIREWALLD_ZONES=$(firewall-cmd --get-active-zones 2>/dev/null | grep -v "interfaces\|sources" | tr '\n' ',' | sed 's/,$//' || echo "unknown")
        log_success "firewalld: ACTIVE (Zones: $FIREWALLD_ZONES)"
    else
        FIREWALLD_STATUS="INACTIVE"
        log_warn "firewalld: INACTIVE"
    fi
else
    log_warn "firewalld: NOT INSTALLED"
fi

# Fail2ban - улучшенная проверка
FAIL2BAN_STATUS="NOT_INSTALLED"
FAIL2BAN_JAILS=""
if command -v fail2ban-client &> /dev/null; then
    if systemctl is-active --quiet fail2ban 2>/dev/null; then
        FAIL2BAN_STATUS="ACTIVE"
        FAIL2BAN_JAILS=$(fail2ban-client status 2>/dev/null | grep "Jail list:" | cut -d: -f2 | xargs | tr ' ' ',' || echo "none")
        log_success "Fail2ban: ACTIVE (Jails: $FAIL2BAN_JAILS)"
    else
        FAIL2BAN_STATUS="INSTALLED_INACTIVE"
        log_warn "Fail2ban: INSTALLED BUT INACTIVE"
    fi
else
    log_warn "Fail2ban: NOT INSTALLED"
fi

# SSH конфигурация
SSH_STATUS="NOT_CHECKED"
SSH_PORT="22"
SSH_ROOT_LOGIN="unknown"
SSH_PASSWORD_AUTH="unknown"
if [[ -f /etc/ssh/sshd_config ]]; then
    SSH_PORT=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}' 2>/dev/null || echo "22")
    SSH_ROOT_LOGIN=$(grep "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}' 2>/dev/null || echo "default")
    SSH_PASSWORD_AUTH=$(grep "^PasswordAuthentication" /etc/ssh/sshd_config | awk '{print $2}' 2>/dev/null || echo "default")
    # Проверяем дефолтные значения если не найдены в конфиге
    [[ "$SSH_PORT" == "" ]] && SSH_PORT="22"
    [[ "$SSH_ROOT_LOGIN" == "" ]] && SSH_ROOT_LOGIN="default"
    [[ "$SSH_PASSWORD_AUTH" == "" ]] && SSH_PASSWORD_AUTH="default"
    SSH_STATUS="CONFIGURED"
    log_success "SSH Port: $SSH_PORT"
    log_success "SSH Root Login: $SSH_ROOT_LOGIN"
    log_success "SSH Password Auth: $SSH_PASSWORD_AUTH"
else
    log_warn "SSH config not found"
fi

echo ""
log_info "📁 БИТРИКС ОКРУЖЕНИЕ - ДЕТАЛЬНАЯ ПРОВЕРКА"

# Улучшенная проверка Битрикса
BITRIX_PATHS=("/home/bitrix/www" "/var/www/html" "/var/www/bitrix" "/usr/local/www")
BITRIX_DIR_STATUS="NOT_FOUND"
BITRIX_CONFIG_STATUS="NOT_FOUND"
BITRIX_BACKUP_STATUS="NOT_FOUND"
BITRIX_LOG_STATUS="NOT_FOUND"
BITRIX_PERMISSIONS_STATUS="NOT_CHECKED"
BITRIX_VERSION="UNKNOWN"

for path in "${BITRIX_PATHS[@]}"; do
    if [[ -d "$path" ]]; then
        if [[ -f "$path/bitrix/php_interface/dbconn.php" ]] || [[ -f "$path/bitrix/.settings.php" ]]; then
            BITRIX_DIR_STATUS="FOUND_$path"
            log_success "Bitrix Directory: FOUND at $path"
            
            # Проверяем конфигурационные файлы
            if [[ -f "$path/bitrix/.settings.php" ]]; then
                BITRIX_CONFIG_STATUS="FOUND"
                log_success "Bitrix Config: FOUND (.settings.php)"
                
                # Пытаемся определить версию Битрикса
                if [[ -f "$path/bitrix/modules/main/classes/general/version.php" ]]; then
                    BITRIX_VERSION=$(grep "define.*SM_VERSION" "$path/bitrix/modules/main/classes/general/version.php" 2>/dev/null | cut -d'"' -f4 || echo "UNKNOWN")
                    log_success "Bitrix Version: $BITRIX_VERSION"
                fi
            fi
            
            # Проверяем права доступа
            BITRIX_OWNER=$(ls -ld "$path" | awk '{print $3":"$4}')
            BITRIX_PERMISSIONS=$(ls -ld "$path" | awk '{print $1}')
            BITRIX_PERMISSIONS_STATUS="Owner: $BITRIX_OWNER, Perms: $BITRIX_PERMISSIONS"
            log_success "Bitrix Permissions: $BITRIX_PERMISSIONS_STATUS"
            
            # Проверяем логи
            if [[ -d "$path/bitrix/logs" ]] && [[ $(ls -1 "$path/bitrix/logs" | wc -l) -gt 0 ]]; then
                BITRIX_LOG_STATUS="FOUND"
                log_success "Bitrix Logs: FOUND"
            fi
            
            # Проверяем бэкапы
            if [[ -d "$path/bitrix/backup" ]] && [[ $(ls -1 "$path/bitrix/backup" 2>/dev/null | wc -l) -gt 0 ]]; then
                BITRIX_BACKUP_STATUS="FOUND"
                log_success "Bitrix Backups: FOUND"
            fi
            
            break
        fi
    fi
done

echo ""
log_info "📝 СИСТЕМНЫЕ СЛУЖБЫ - РАСШИРЕННАЯ ПРОВЕРКА"

# Расширенный список сервисов для проверки
all_services=("apache2" "httpd" "nginx" "mysql" "mariadb" "mysqld" "redis-server" "redis" "memcached" "postfix" "dovecot" "fail2ban" "ssh" "sshd" "cron" "rsyslog" "systemd-resolved" "firewalld")
declare -A SERVICE_STATUS_DETAILED

for service in "${all_services[@]}"; do
    if systemctl list-unit-files 2>/dev/null | grep -q "^$service.service"; then
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            SERVICE_STATUS_DETAILED[$service]="RUNNING"
            # Получаем время запуска сервиса
            START_TIME=$(systemctl show "$service" --property=ActiveEnterTimestamp --value 2>/dev/null | cut -d' ' -f1-2 || echo "Unknown")
            log_success "$service: RUNNING (since $START_TIME)"
        else
            SERVICE_STATUS_DETAILED[$service]="STOPPED"
            log_warn "$service: STOPPED"
        fi
        
        # Проверяем автозапуск
        if systemctl is-enabled --quiet "$service" 2>/dev/null; then
            log_success "$service: Auto-start ENABLED"
        else
            log_warn "$service: Auto-start DISABLED"
        fi
    else
        SERVICE_STATUS_DETAILED[$service]="NOT_INSTALLED"
    fi
done

echo ""
log_info "📄 ГЕНЕРАЦИЯ ДЕТАЛЬНОГО JSON ОТЧЁТА"

# Подсчитываем статистику для summary
TOTAL_CHECKS=0
PASSED_CHECKS=0
WARNING_CHECKS=0
CRITICAL_CHECKS=0

# Создаём детальный JSON отчёт
cat > "$REPORT_FILE" << EOF
{
  "report_info": {
    "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "hostname": "$HOSTNAME",
    "scan_type": "comprehensive_system_audit",
    "version": "3.0_PRO",
    "generated_by": "AKUMA Professional System Audit Script",
    "scan_duration": "$(date +%s) seconds"
  },
  "system_info": {
    "os_name": "$OS_NAME",
    "os_version": "$OS_VERSION",
    "kernel_version": "$KERNEL_VERSION",
    "architecture": "$ARCHITECTURE",
    "uptime": "$UPTIME",
    "hostname": "$HOSTNAME"
  },
  "hardware": {
    "cpu": {
      "model": "$CPU_MODEL",
      "cores": $CPU_CORES,
      "frequency_mhz": "$CPU_FREQUENCY",
      "architecture": "$CPU_ARCHITECTURE",
      "status": "$CPU_STATUS"
    },
    "memory": {
      "total_gb": $RAM_TOTAL,
      "used_gb": $RAM_USED,
      "free_gb": $RAM_FREE,
      "cached_gb": $RAM_CACHED,
      "usage_percent": "$MEM_USAGE_PERCENT",
      "swap_usage_percent": "$SWAP_USAGE_PERCENT",
      "status": "$RAM_STATUS"
    },
    "storage": {
      "root_disk": "$DISK_ROOT",
      "total_storage": "$DISK_TOTAL",
      "inode_usage": "$DISK_INODES",
      "io_stats": "$DISK_IO_STATS"
    }
  },
  "software": {
    "web_servers": {
      "apache": {
        "version": "$APACHE_VERSION",
        "status": "$APACHE_STATUS",
        "modules_loaded": "$APACHE_MODULES"
      },
      "nginx": {
        "version": "$NGINX_VERSION",
        "status": "$NGINX_STATUS",
        "config_test": "$NGINX_CONFIG_TEST"
      }
    },
    "databases": {
      "mysql": {
        "version": "$MYSQL_VERSION",
        "type": "${MYSQL_TYPE:-Unknown}",
        "status": "$MYSQL_STATUS",
        "service_status": "$MYSQL_SERVICE_STATUS"
      }
    },
    "programming": {
      "php": {
        "version": "$PHP_VERSION",
        "status": "$PHP_STATUS",
        "critical_modules": "$PHP_MODULES"
      }
    }
  },
  "network": {
    "interfaces": "$NETWORK_INTERFACES",
    "internal_ip": "$INTERNAL_IP",
    "external_ip": "$EXTERNAL_IP",
    "ports": {
EOF

# Добавляем информацию о портах
first=true
for port in "${critical_ports[@]}"; do
    if [ "$first" = false ]; then
        echo "," >> "$REPORT_FILE"
    fi
    echo -n "      \"$port\": \"${PORT_STATUS[$port]}\"" >> "$REPORT_FILE"
    first=false
done

cat >> "$REPORT_FILE" << EOF

    }
  },
  "performance": {
    "load_average": {
      "1min": "$LOAD_1MIN",
      "5min": "$LOAD_5MIN",
      "15min": "$LOAD_15MIN",
      "status": "$LOAD_STATUS"
    },
    "memory_usage_percent": "$MEM_USAGE_PERCENT",
    "swap_usage_percent": "$SWAP_USAGE_PERCENT"
  },
  "security": {
    "selinux": {
      "status": "$SELINUX_STATUS",
      "mode": "$SELINUX_MODE"
    },
    "firewall": {
      "iptables": {
        "status": "$IPTABLES_STATUS",
        "rules_count": $IPTABLES_RULES_COUNT,
        "ipv6_rules_count": $IP6TABLES_RULES_COUNT
      },
      "ufw": {
        "status": "$UFW_STATUS",
        "rules_count": $UFW_RULES_COUNT
      },
      "firewalld": {
        "status": "$FIREWALLD_STATUS",
        "active_zones": "$FIREWALLD_ZONES"
      }
    },
    "intrusion_prevention": {
      "fail2ban": {
        "status": "$FAIL2BAN_STATUS",
        "active_jails": "$FAIL2BAN_JAILS"
      }
    },
    "ssh": {
      "status": "$SSH_STATUS",
      "port": "$SSH_PORT",
      "root_login": "$SSH_ROOT_LOGIN",
      "password_auth": "$SSH_PASSWORD_AUTH"
    }
  },
  "bitrix_environment": {
    "directory_status": "$BITRIX_DIR_STATUS",
    "config_status": "$BITRIX_CONFIG_STATUS",
    "version": "$BITRIX_VERSION",
    "backup_status": "$BITRIX_BACKUP_STATUS",
    "log_status": "$BITRIX_LOG_STATUS",
    "permissions": "$BITRIX_PERMISSIONS_STATUS"
  },
  "services": {
EOF

# Добавляем статусы всех сервисов
first=true
for service in "${all_services[@]}"; do
    if [ "$first" = false ]; then
        echo "," >> "$REPORT_FILE"
    fi
    echo -n "    \"$service\": \"${SERVICE_STATUS_DETAILED[$service]}\"" >> "$REPORT_FILE"
    first=false
done

# Генерируем рекомендации
RECOMMENDATIONS_LIST=""

# Анализируем результаты и формируем рекомендации
if [[ "$PHP_STATUS" != "OK" ]] && [[ "$PHP_STATUS" != "NOT_FOUND" ]]; then
    RECOMMENDATIONS_LIST="$RECOMMENDATIONS_LIST\"Update PHP to version 8.1 or higher for better Bitrix24 compatibility\","
fi

if [[ "$RAM_STATUS" != "OK" ]]; then
    RECOMMENDATIONS_LIST="$RECOMMENDATIONS_LIST\"Consider upgrading RAM to 8GB+ for optimal Bitrix24 performance\","
fi

if [[ "$SELINUX_MODE" == "Enforcing" ]] && [[ "$BITRIX_DIR_STATUS" != "NOT_FOUND" ]]; then
    RECOMMENDATIONS_LIST="$RECOMMENDATIONS_LIST\"Configure SELinux policies for Bitrix24 or consider setting to Permissive mode\","
fi

if [[ "$IPTABLES_STATUS" == "NOT_CONFIGURED" ]] && [[ "$UFW_STATUS" != "ACTIVE" ]] && [[ "$FIREWALLD_STATUS" != "ACTIVE" ]]; then
    RECOMMENDATIONS_LIST="$RECOMMENDATIONS_LIST\"Configure firewall (iptables, UFW, or firewalld) for security\","
fi

if [[ "$FAIL2BAN_STATUS" == "NOT_INSTALLED" ]]; then
    RECOMMENDATIONS_LIST="$RECOMMENDATIONS_LIST\"Install and configure Fail2ban for intrusion prevention\","
fi

if [[ "$MYSQL_SERVICE_STATUS" != "RUNNING" ]] && [[ "$MYSQL_VERSION" != "NOT_INSTALLED" ]]; then
    RECOMMENDATIONS_LIST="$RECOMMENDATIONS_LIST\"Start MySQL/MariaDB service for database functionality\","
fi

if [[ "$SSH_ROOT_LOGIN" == "yes" ]]; then
    RECOMMENDATIONS_LIST="$RECOMMENDATIONS_LIST\"Disable SSH root login for better security (PermitRootLogin no)\","
fi

if [[ "$BITRIX_BACKUP_STATUS" == "NOT_FOUND" ]] && [[ "$BITRIX_DIR_STATUS" != "NOT_FOUND" ]]; then
    RECOMMENDATIONS_LIST="$RECOMMENDATIONS_LIST\"Configure automatic Bitrix24 backups\","
fi

# Убираем последнюю запятую
RECOMMENDATIONS_LIST=$(echo "$RECOMMENDATIONS_LIST" | sed 's/,$//')

# Завершаем JSON
cat >> "$REPORT_FILE" << EOF

  },
  "summary": {
    "scan_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "total_services_checked": ${#all_services[@]},
    "running_services": $(printf '%s\n' "${SERVICE_STATUS_DETAILED[@]}" | grep -c "RUNNING"),
    "security_components": {
      "selinux_active": "$([ "$SELINUX_MODE" == "Enforcing" ] && echo "true" || echo "false")",
      "firewall_configured": "$([ "$IPTABLES_STATUS" != "NOT_CONFIGURED" ] || [ "$UFW_STATUS" == "ACTIVE" ] || [ "$FIREWALLD_STATUS" == "ACTIVE" ] && echo "true" || echo "false")",
      "fail2ban_active": "$([ "$FAIL2BAN_STATUS" == "ACTIVE" ] && echo "true" || echo "false")"
    },
    "system_health": "$([ "$CPU_STATUS" == "OK" ] && [ "$RAM_STATUS" == "OK" ] && [ "$LOAD_STATUS" == "OK" ] && echo "HEALTHY" || echo "ATTENTION_REQUIRED")",
    "bitrix_environment": "$([ "$BITRIX_DIR_STATUS" != "NOT_FOUND" ] && echo "DETECTED" || echo "NOT_DETECTED")",
    "recommendations": [
      $RECOMMENDATIONS_LIST
    ]
  }
}
EOF

echo ""
log_success "✅ ПОЛНЫЙ СИСТЕМНЫЙ АУДИТ ЗАВЕРШЁН!"
echo -e "${GREEN}📄 Файл отчёта: ${CYAN}$REPORT_FILE${NC}"
echo -e "${GREEN}📊 Размер отчёта: ${CYAN}$(wc -c < "$REPORT_FILE") байт${NC}"
echo ""
echo -e "${BLUE}💡 СПОСОБЫ ИСПОЛЬЗОВАНИЯ:${NC}"
echo "1. 🌐 Загрузите в веб-интерфейс: $REPORT_FILE"
echo "2. 👀 Просмотр в консоли: cat $REPORT_FILE | jq ."
echo "3. 📝 Анализ в редакторе: nano $REPORT_FILE"
echo ""
echo -e "${PURPLE}🎯 AKUMA'S PROFESSIONAL AUDIT COMPLETE! 🚀${NC}"
echo -e "${YELLOW}Как говорил мой дед: 'Хороший аудит — как хороший взлом: всё должно быть найдено!'${NC}"

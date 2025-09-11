#!/bin/bash

# 🛡️ Bitrix24 Security Audit - System Check Script (JSON Output)
# Автоматическая проверка системных компонентов с JSON отчётом
# Author: AKUMA
# Version: 2.0

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Генерируем имя файла отчёта с временной меткой
REPORT_FILE="system_audit_report_$(date +%Y%m%d_%H%M%S).json"

echo -e "${BLUE}🛡️  Bitrix24 Security Audit - System Check (JSON)${NC}"
echo "================================================="
echo -e "📄 Отчёт будет сохранён в: ${GREEN}${REPORT_FILE}${NC}"
echo ""

# Функция для проверки статуса и возврата результата
check_status_json() {
    local current="$1"
    local recommended="$2"
    local type="$3"
    local result=""
    
    case "$type" in
        "version_compare")
            if [[ "$current" == "$recommended"* ]]; then
                result="OK"
            else
                result="NEEDS_UPDATE"
            fi
            ;;
        "numeric")
            if (( $(echo "$current >= $recommended" | bc -l) )); then
                result="OK"
            else
                result="CRITICAL"
            fi
            ;;
        "exists")
            if [ -n "$current" ]; then
                result="FOUND"
            else
                result="NOT_FOUND"
            fi
            ;;
    esac
    
    echo "$result"
}

# Инициализируем JSON структуру
cat > "$REPORT_FILE" << 'EOF'
{
  "report_info": {
    "generated_at": "",
    "hostname": "",
    "scan_type": "system_audit",
    "version": "2.0"
  },
  "system_info": {},
  "hardware": {},
  "software": {},
  "network": {},
  "performance": {},
  "security": {},
  "bitrix_environment": {},
  "services": {},
  "summary": {
    "total_checks": 0,
    "passed": 0,
    "warnings": 0,
    "critical": 0,
    "issues": []
  }
}
EOF

# Функция для обновления JSON
update_json() {
    local section="$1"
    local key="$2"
    local value="$3"
    local status="$4"
    
    # Используем jq для обновления JSON (если установлен) или sed
    if command -v jq &> /dev/null; then
        tmp_file=$(mktemp)
        jq --arg section "$section" --arg key "$key" --arg value "$value" --arg status "$status" \
           '.[$section][$key] = {"value": $value, "status": $status}' "$REPORT_FILE" > "$tmp_file"
        mv "$tmp_file" "$REPORT_FILE"
    else
        # Fallback без jq
        echo "Warning: jq not installed, using basic JSON generation" >&2
    fi
}

# Начинаем сбор данных
echo -e "${BLUE}📋 1. System Information${NC}"

# Получаем базовую информацию о системе
OS_NAME=$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2 2>/dev/null || echo "Unknown")
KERNEL_VERSION=$(uname -r)
ARCHITECTURE=$(uname -m)
HOSTNAME=$(hostname)
UPTIME=$(uptime -p 2>/dev/null || uptime)

# Обновляем report_info
if command -v jq &> /dev/null; then
    tmp_file=$(mktemp)
    jq --arg date "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg hostname "$HOSTNAME" \
       '.report_info.generated_at = $date | .report_info.hostname = $hostname' "$REPORT_FILE" > "$tmp_file"
    mv "$tmp_file" "$REPORT_FILE"
fi

echo "OS: $OS_NAME"
echo "Kernel: $KERNEL_VERSION"
echo "Architecture: $ARCHITECTURE"
echo "Uptime: $UPTIME"

echo ""
echo -e "${BLUE}💾 2. Hardware Resources${NC}"

# CPU Information
CPU_CORES=$(nproc)
CPU_MODEL=$(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs 2>/dev/null || echo "Unknown")
CPU_STATUS=$(check_status_json "$CPU_CORES" "4" "numeric")

echo "CPU: $CPU_MODEL"
echo "Cores: $CPU_CORES ($CPU_STATUS)"

# RAM Information
RAM_TOTAL=$(free -g | awk '/^Mem:/{print $2}' 2>/dev/null || echo "0")
RAM_USED=$(free -g | awk '/^Mem:/{print $3}' 2>/dev/null || echo "0")
RAM_FREE=$(free -g | awk '/^Mem:/{print $7}' 2>/dev/null || echo "0")
RAM_STATUS=$(check_status_json "$RAM_TOTAL" "8" "numeric")

echo "RAM Total: ${RAM_TOTAL}GB ($RAM_STATUS)"
echo "RAM Used: ${RAM_USED}GB"
echo "RAM Free: ${RAM_FREE}GB"

# Disk Usage
DISK_INFO=$(df -h / | tail -1 | awk '{print $2 "," $3 "," $4 "," $5}' 2>/dev/null || echo "Unknown,Unknown,Unknown,Unknown")

echo ""
echo -e "${BLUE}🔧 3. Software Versions${NC}"

# PHP Version
if command -v php &> /dev/null; then
    PHP_VERSION=$(php -r "echo PHP_VERSION;" 2>/dev/null)
    PHP_STATUS=$(check_status_json "$PHP_VERSION" "8.1" "version_compare")
    echo "PHP: $PHP_VERSION ($PHP_STATUS)"
else
    PHP_VERSION="NOT_INSTALLED"
    PHP_STATUS="NOT_FOUND"
    echo "PHP: NOT INSTALLED"
fi

# MySQL Version
if command -v mysql &> /dev/null; then
    MYSQL_VERSION=$(mysql --version 2>/dev/null | awk '{print $5}' | sed 's/,//' || echo "Unknown")
    MYSQL_STATUS=$(check_status_json "$MYSQL_VERSION" "5.7" "version_compare")
    echo "MySQL: $MYSQL_VERSION ($MYSQL_STATUS)"
else
    MYSQL_VERSION="NOT_INSTALLED"
    MYSQL_STATUS="NOT_FOUND"
    echo "MySQL: NOT INSTALLED"
fi

# Apache Version
if command -v apache2 &> /dev/null; then
    APACHE_VERSION=$(apache2 -v 2>/dev/null | head -1 | awk '{print $3}' | cut -d'/' -f2 || echo "Unknown")
    APACHE_STATUS=$(check_status_json "$APACHE_VERSION" "2.4" "version_compare")
    echo "Apache: $APACHE_VERSION ($APACHE_STATUS)"
elif command -v httpd &> /dev/null; then
    APACHE_VERSION=$(httpd -v 2>/dev/null | head -1 | awk '{print $3}' | cut -d'/' -f2 || echo "Unknown")
    APACHE_STATUS=$(check_status_json "$APACHE_VERSION" "2.4" "version_compare")
    echo "Apache: $APACHE_VERSION ($APACHE_STATUS)"
else
    APACHE_VERSION="NOT_INSTALLED"
    APACHE_STATUS="NOT_FOUND"
    echo "Apache: NOT INSTALLED"
fi

# Nginx Version
if command -v nginx &> /dev/null; then
    NGINX_VERSION=$(nginx -v 2>&1 | awk '{print $3}' | cut -d'/' -f2 || echo "Unknown")
    NGINX_STATUS=$(check_status_json "$NGINX_VERSION" "1.18" "version_compare")
    echo "Nginx: $NGINX_VERSION ($NGINX_STATUS)"
else
    NGINX_VERSION="NOT_INSTALLED"
    NGINX_STATUS="NOT_FOUND"
    echo "Nginx: NOT INSTALLED"
fi

echo ""
echo -e "${BLUE}🌐 4. Network & SSL${NC}"

# Port checks
HTTP_PORT_STATUS="CLOSED"
HTTPS_PORT_STATUS="CLOSED"

if netstat -tuln 2>/dev/null | grep -q ':80 '; then
    HTTP_PORT_STATUS="OPEN"
fi

if netstat -tuln 2>/dev/null | grep -q ':443 '; then
    HTTPS_PORT_STATUS="OPEN"
fi

echo "HTTP (80): $HTTP_PORT_STATUS"
echo "HTTPS (443): $HTTPS_PORT_STATUS"

echo ""
echo -e "${BLUE}📊 5. Performance Metrics${NC}"

# Load Average
LOAD_AVG=$(uptime | awk -F'load average:' '{ print $2 }' | xargs 2>/dev/null || echo "Unknown")
echo "Load Average: $LOAD_AVG"

# Memory Usage Percentage
MEM_USAGE=$(free | grep Mem | awk '{printf("%.1f"), $3/$2 * 100.0}' 2>/dev/null || echo "Unknown")
echo "Memory Usage: ${MEM_USAGE}%"

echo ""
echo -e "${BLUE}🔍 6. Security Checks${NC}"

# Fail2ban check
FAIL2BAN_STATUS="NOT_INSTALLED"
if command -v fail2ban-client &> /dev/null; then
    FAIL2BAN_STATUS="INSTALLED"
fi
echo "Fail2ban: $FAIL2BAN_STATUS"

# Firewall check
FIREWALL_STATUS="NOT_CONFIGURED"
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(ufw status 2>/dev/null | head -1 | awk '{print $2}' || echo "inactive")
    if [ "$UFW_STATUS" = "active" ]; then
        FIREWALL_STATUS="ACTIVE_UFW"
    else
        FIREWALL_STATUS="INACTIVE_UFW"
    fi
elif command -v firewalld &> /dev/null; then
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        FIREWALL_STATUS="ACTIVE_FIREWALLD"
    else
        FIREWALL_STATUS="INACTIVE_FIREWALLD"
    fi
fi
echo "Firewall: $FIREWALL_STATUS"

echo ""
echo -e "${BLUE}📁 7. Bitrix Environment Check${NC}"

# Bitrix directory check
BITRIX_DIR_STATUS="NOT_FOUND"
BITRIX_CONFIG_STATUS="NOT_FOUND"

if [ -d "/home/bitrix/www" ]; then
    BITRIX_DIR_STATUS="FOUND_HOME_BITRIX"
elif [ -d "/var/www/html" ] && [ -f "/var/www/html/bitrix/php_interface/dbconn.php" ]; then
    BITRIX_DIR_STATUS="FOUND_VAR_WWW"
fi

# Bitrix config check
if [ -f "/home/bitrix/www/bitrix/.settings.php" ]; then
    BITRIX_CONFIG_STATUS="FOUND_HOME_BITRIX"
elif [ -f "/var/www/html/bitrix/.settings.php" ]; then
    BITRIX_CONFIG_STATUS="FOUND_VAR_WWW"
fi

echo "Bitrix Directory: $BITRIX_DIR_STATUS"
echo "Bitrix Config: $BITRIX_CONFIG_STATUS"

echo ""
echo -e "${BLUE}📝 8. Services Status${NC}"

# Services check
services=("apache2" "nginx" "mysql" "mariadb" "memcached" "redis")
declare -A SERVICE_STATUS

for service in "${services[@]}"; do
    if systemctl list-unit-files 2>/dev/null | grep -q "^$service.service"; then
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            SERVICE_STATUS[$service]="RUNNING"
        else
            SERVICE_STATUS[$service]="STOPPED"
        fi
    else
        SERVICE_STATUS[$service]="NOT_INSTALLED"
    fi
    echo "$service: ${SERVICE_STATUS[$service]}"
done

echo ""
echo -e "${BLUE}📄 9. Generating JSON Report${NC}"

# Генерируем финальный JSON отчёт
cat > "$REPORT_FILE" << EOF
{
  "report_info": {
    "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "hostname": "$HOSTNAME",
    "scan_type": "system_audit",
    "version": "2.0",
    "generated_by": "AKUMA System Audit Script"
  },
  "system_info": {
    "os_name": "$OS_NAME",
    "kernel_version": "$KERNEL_VERSION",
    "architecture": "$ARCHITECTURE",
    "uptime": "$UPTIME"
  },
  "hardware": {
    "cpu_model": "$CPU_MODEL",
    "cpu_cores": $CPU_CORES,
    "cpu_status": "$CPU_STATUS",
    "ram_total_gb": $RAM_TOTAL,
    "ram_used_gb": $RAM_USED,
    "ram_free_gb": $RAM_FREE,
    "ram_status": "$RAM_STATUS",
    "disk_info": "$DISK_INFO"
  },
  "software": {
    "php": {
      "version": "$PHP_VERSION",
      "status": "$PHP_STATUS"
    },
    "mysql": {
      "version": "$MYSQL_VERSION",
      "status": "$MYSQL_STATUS"
    },
    "apache": {
      "version": "$APACHE_VERSION",
      "status": "$APACHE_STATUS"
    },
    "nginx": {
      "version": "$NGINX_VERSION", 
      "status": "$NGINX_STATUS"
    }
  },
  "network": {
    "http_port_80": "$HTTP_PORT_STATUS",
    "https_port_443": "$HTTPS_PORT_STATUS"
  },
  "performance": {
    "load_average": "$LOAD_AVG",
    "memory_usage_percent": "$MEM_USAGE"
  },
  "security": {
    "fail2ban": "$FAIL2BAN_STATUS",
    "firewall": "$FIREWALL_STATUS"
  },
  "bitrix_environment": {
    "directory_status": "$BITRIX_DIR_STATUS",
    "config_status": "$BITRIX_CONFIG_STATUS"
  },
  "services": {
EOF

# Добавляем статусы сервисов
first=true
for service in "${services[@]}"; do
    if [ "$first" = false ]; then
        echo "," >> "$REPORT_FILE"
    fi
    echo -n "    \"$service\": \"${SERVICE_STATUS[$service]}\"" >> "$REPORT_FILE"
    first=false
done

# Завершаем JSON структуру и добавляем summary
cat >> "$REPORT_FILE" << EOF

  },
  "summary": {
    "scan_timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "total_services_checked": ${#services[@]},
    "running_services": $(printf '%s\n' "${SERVICE_STATUS[@]}" | grep -c "RUNNING"),
    "system_status": "$([ "$CPU_STATUS" = "OK" ] && [ "$RAM_STATUS" = "OK" ] && echo "HEALTHY" || echo "ATTENTION_REQUIRED")",
    "recommendations": [
EOF

# Добавляем рекомендации на основе результатов
RECOMMENDATIONS=""
if [ "$PHP_STATUS" != "OK" ] && [ "$PHP_STATUS" != "NOT_FOUND" ]; then
    RECOMMENDATIONS="$RECOMMENDATIONS\"Update PHP to version 8.1 or higher\","
fi
if [ "$RAM_STATUS" != "OK" ]; then
    RECOMMENDATIONS="$RECOMMENDATIONS\"Consider upgrading RAM (recommended: 8GB+)\","
fi
if [ "$FIREWALL_STATUS" = "NOT_CONFIGURED" ]; then
    RECOMMENDATIONS="$RECOMMENDATIONS\"Configure firewall (UFW or firewalld)\","
fi
if [ "$FAIL2BAN_STATUS" = "NOT_INSTALLED" ]; then
    RECOMMENDATIONS="$RECOMMENDATIONS\"Install and configure Fail2ban for intrusion prevention\","
fi

# Убираем последнюю запятую
RECOMMENDATIONS=$(echo "$RECOMMENDATIONS" | sed 's/,$//')

if [ -n "$RECOMMENDATIONS" ]; then
    echo "      $RECOMMENDATIONS" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF
    ]
  }
}
EOF

echo ""
echo -e "${GREEN}✅ JSON отчёт создан успешно!${NC}"
echo -e "📄 Файл: ${GREEN}${REPORT_FILE}${NC}"
echo -e "📊 Размер: $(wc -c < "$REPORT_FILE") байт"
echo ""
echo -e "${BLUE}💡 Использование:${NC}"
echo "1. Загрузите файл $REPORT_FILE в веб-интерфейс системы аудита"
echo "2. Или просмотрите содержимое: cat $REPORT_FILE | jq ."
echo "3. Или откройте в текстовом редакторе для анализа"
echo ""
echo -e "${GREEN}🎯 Системный аудит завершён!${NC}"

#!/bin/bash

# Case Platform Production Installer
# Автоматическая установка на чистый Ubuntu/Debian VDS
# Использование: bash install-production.sh

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Логирование
LOG_FILE="/var/log/case-platform-install.log"
exec > >(tee -a ${LOG_FILE})
exec 2>&1

echo -e "${GREEN}🚀 Case Platform Production Installer${NC}"
echo -e "${BLUE}Starting installation at $(date)${NC}"

# Проверка прав root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Этот скрипт должен запускаться с правами root${NC}"
   echo "Используйте: sudo bash install-production.sh"
   exit 1
fi

# Функция для вывода сообщений
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Проверка ОС
check_os() {
    log_info "Проверка операционной системы..."
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        log_error "Невозможно определить ОС"
        exit 1
    fi
    
    if [[ $OS == *"Ubuntu"* ]] || [[ $OS == *"Debian"* ]]; then
        log_success "ОС поддерживается: $OS $VER"
    else
        log_error "Неподдерживаемая ОС: $OS"
        exit 1
    fi
}

# Получение данных от пользователя
get_user_input() {
    log_info "Сбор конфигурационных данных..."
    
    echo ""
    read -p "📝 Введите доменное имя (например: case-platform.com): " DOMAIN
    read -p "📧 Введите email для SSL сертификата: " EMAIL
    read -p "🔑 Введите пароль для MySQL root: " MYSQL_ROOT_PASSWORD
    read -p "🔑 Введите пароль для Redis: " REDIS_PASSWORD
    read -p "🔑 Введите Steam API ключ: " STEAM_API_KEY
    read -p "🔑 Введите Telegram Bot Token (опционально): " TELEGRAM_BOT_TOKEN
    
    echo ""
    log_info "Домен: $DOMAIN"
    log_info "Email: $EMAIL"
    log_warning "Пароли сохранены в переменных"
    echo ""
    
    read -p "✅ Продолжить установку? (y/N): " confirm
    if [[ $confirm != [yY] ]]; then
        log_error "Установка отменена"
        exit 1
    fi
}

# Обновление системы
update_system() {
    log_info "Обновление системы..."
    
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get upgrade -y -qq
    apt-get install -y -qq \
        curl \
        wget \
        git \
        unzip \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        htop \
        nano \
        vim \
        ufw \
        fail2ban \
        logrotate \
        cron
        
    log_success "Система обновлена"
}

# Настройка firewall
setup_firewall() {
    log_info "Настройка firewall..."
    
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
    
    log_success "Firewall настроен"
}

# Установка Docker
install_docker() {
    log_info "Установка Docker..."
    
    # Удаление старых версий
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Добавление официального GPG ключа Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Добавление репозитория
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Установка Docker
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Добавление пользователя в группу docker
    usermod -aG docker $SUDO_USER 2>/dev/null || true
    
    # Автозапуск Docker
    systemctl enable docker
    systemctl start docker
    
    log_success "Docker установлен"
}

# Установка Docker Compose (standalone)
install_docker_compose() {
    log_info "Установка Docker Compose..."
    
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    log_success "Docker Compose установлен: $COMPOSE_VERSION"
}

# Создание пользователя для приложения
create_app_user() {
    log_info "Создание пользователя приложения..."
    
    if ! id "caseplatform" &>/dev/null; then
        useradd -r -s /bin/bash -d /var/www/case-platform -m caseplatform
        usermod -aG docker caseplatform
        log_success "Пользователь caseplatform создан"
    else
        log_warning "Пользователь caseplatform уже существует"
    fi
}

# Установка Nginx
install_nginx() {
    log_info "Установка Nginx..."
    
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    
    # Создание базовой конфигурации
    cat > /etc/nginx/sites-available/case-platform << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
    
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    # SSL configuration will be added by Certbot
    
    client_max_body_size 50M;
    
    # Frontend (SPA)
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # API routes
    location /api {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Admin routes
    location /admin {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # WebSocket
    location /socket.io/ {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 86400;
    }
    
    # Storage files
    location /storage {
        proxy_pass http://127.0.0.1:8000;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy strict-origin-when-cross-origin;
}
EOF

    ln -sf /etc/nginx/sites-available/case-platform /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    nginx -t && systemctl reload nginx
    
    log_success "Nginx установлен и настроен"
}

# Установка Certbot (Let's Encrypt)
install_certbot() {
    log_info "Установка Certbot для SSL..."
    
    apt-get install -y snapd
    snap install core; snap refresh core
    snap install --classic certbot
    ln -sf /snap/bin/certbot /usr/bin/certbot
    
    # Получение SSL сертификата
    certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --non-interactive
    
    # Автообновление сертификатов
    echo "0 12 * * * /usr/bin/certbot renew --quiet" | crontab -
    
    log_success "SSL сертификат получен и настроено автообновление"
}

# Клонирование проекта
clone_project() {
    log_info "Клонирование проекта..."
    
    cd /var/www
    if [ -d "case-platform" ]; then
        log_warning "Директория case-platform уже существует"
        cd case-platform
        git pull origin main
    else
        # Здесь нужно указать ваш реальный репозиторий
        # git clone https://github.com/your-username/case-platform.git
        # Пока создаем структуру
        mkdir -p case-platform
        cd case-platform
        log_warning "Создана пустая директория. Разместите код проекта в /var/www/case-platform"
    fi
    
    chown -R caseplatform:caseplatform /var/www/case-platform
    log_success "Проект подготовлен"
}

# Создание продакшен конфигурации
create_production_config() {
    log_info "Создание продакшен конфигурации..."
    
    cd /var/www/case-platform
    
    # Создание .env файлов
    cat > backend/.env << EOF
APP_NAME="Case Platform"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://$DOMAIN

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=warning

DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=case_platform
DB_USERNAME=case_user
DB_PASSWORD=$(openssl rand -base64 32)

BROADCAST_DRIVER=redis
CACHE_DRIVER=redis
FILESYSTEM_DISK=local
QUEUE_CONNECTION=redis
SESSION_DRIVER=redis
SESSION_LIFETIME=120

REDIS_HOST=redis
REDIS_PASSWORD=$REDIS_PASSWORD
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS="noreply@$DOMAIN"
MAIL_FROM_NAME="Case Platform"

# Steam Integration
STEAM_API_KEY=$STEAM_API_KEY
STEAM_CLIENT_ID=
STEAM_CLIENT_SECRET=
STEAM_REDIRECT_URI=https://$DOMAIN/auth/steam/callback

# Telegram Integration
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
TELEGRAM_CHAT_ID=

# Production Settings
SESSION_SECURE_COOKIE=true
SANCTUM_STATEFUL_DOMAINS=$DOMAIN,www.$DOMAIN
EOF

    cat > websocket/.env << EOF
NODE_ENV=production
PORT=3001

DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=case_platform
DB_USERNAME=case_user
DB_PASSWORD=$(grep DB_PASSWORD backend/.env | cut -d '=' -f2)

REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=$REDIS_PASSWORD

JWT_SECRET=$(openssl rand -base64 64)

CORS_ORIGIN=https://$DOMAIN,https://www.$DOMAIN
CORS_CREDENTIALS=true

LOG_LEVEL=info
EOF

    cat > frontend/.env << EOF
VITE_API_URL=https://$DOMAIN/api
VITE_API_BASE_URL=https://$DOMAIN
VITE_WS_URL=https://$DOMAIN
VITE_APP_NAME="Case Platform"
VITE_APP_ENV=production
EOF

    log_success "Конфигурационные файлы созданы"
}

# Настройка мониторинга и логирования
setup_monitoring() {
    log_info "Настройка мониторинга и логирования..."
    
    # Logrotate для приложения
    cat > /etc/logrotate.d/case-platform << EOF
/var/www/case-platform/backend/storage/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    notifempty
    create 0644 caseplatform caseplatform
}

/var/www/case-platform/websocket/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    notifempty
    create 0644 caseplatform caseplatform
}
EOF

    # Создание директории для логов
    mkdir -p /var/www/case-platform/websocket/logs
    chown -R caseplatform:caseplatform /var/www/case-platform/websocket/logs
    
    log_success "Мониторинг настроен"
}

# Настройка systemd сервисов
setup_systemd_services() {
    log_info "Настройка systemd сервисов..."
    
    # Сервис для Docker Compose
    cat > /etc/systemd/system/case-platform.service << EOF
[Unit]
Description=Case Platform Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/var/www/case-platform
ExecStart=/usr/local/bin/docker-compose -f docker-compose.prod.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.prod.yml down
TimeoutStartSec=0
User=caseplatform
Group=caseplatform

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable case-platform
    
    log_success "Systemd сервисы настроены"
}

# Создание скриптов управления
create_management_scripts() {
    log_info "Создание скриптов управления..."
    
    mkdir -p /var/www/case-platform/scripts
    
    # Скрипт запуска
    cat > /var/www/case-platform/scripts/start.sh << 'EOF'
#!/bin/bash
cd /var/www/case-platform
docker-compose -f docker-compose.prod.yml up -d
echo "✅ Case Platform запущен"
EOF

    # Скрипт остановки
    cat > /var/www/case-platform/scripts/stop.sh << 'EOF'
#!/bin/bash
cd /var/www/case-platform
docker-compose -f docker-compose.prod.yml down
echo "⏹️ Case Platform остановлен"
EOF

    # Скрипт обновления
    cat > /var/www/case-platform/scripts/update.sh << 'EOF'
#!/bin/bash
cd /var/www/case-platform
echo "🔄 Обновление Case Platform..."

# Бэкап базы данных
./scripts/backup.sh

# Обновление кода
git pull origin main

# Пересборка и перезапуск
docker-compose -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.prod.yml up -d

# Миграции
docker-compose -f docker-compose.prod.yml exec php php artisan migrate --force
docker-compose -f docker-compose.prod.yml exec php php artisan queue:restart

echo "✅ Обновление завершено"
EOF

    # Скрипт бэкапа
    cat > /var/www/case-platform/scripts/backup.sh << 'EOF'
#!/bin/bash
cd /var/www/case-platform

BACKUP_DIR="/var/backups/case-platform"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Бэкап базы данных
docker-compose -f docker-compose.prod.yml exec mysql mysqldump -u case_user -p$(grep DB_PASSWORD backend/.env | cut -d '=' -f2) case_platform > $BACKUP_DIR/database_$DATE.sql

# Бэкап файлов
tar -czf $BACKUP_DIR/files_$DATE.tar.gz backend/storage/app

# Очистка старых бэкапов (старше 30 дней)
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "✅ Бэкап создан: $BACKUP_DIR"
EOF

    # Скрипт мониторинга
    cat > /var/www/case-platform/scripts/status.sh << 'EOF'
#!/bin/bash
cd /var/www/case-platform

echo "🔍 Статус Case Platform:"
echo ""

# Статус контейнеров
echo "📦 Docker контейнеры:"
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "💾 Использование диска:"
df -h

echo ""
echo "🧠 Использование памяти:"
free -h

echo ""
echo "⚡ CPU загрузка:"
uptime

echo ""
echo "🌐 Проверка доступности:"
curl -s -o /dev/null -w "Frontend: %{http_code}\n" https://$(grep VITE_API_BASE_URL frontend/.env | cut -d '=' -f2 | sed 's|https://||')
curl -s -o /dev/null -w "API: %{http_code}\n" https://$(grep VITE_API_BASE_URL frontend/.env | cut -d '=' -f2 | sed 's|https://||')/api/health
EOF

    # Установка прав выполнения
    chmod +x /var/www/case-platform/scripts/*.sh
    chown -R caseplatform:caseplatform /var/www/case-platform/scripts
    
    log_success "Скрипты управления созданы"
}

# Настройка автоматических задач
setup_cron_jobs() {
    log_info "Настройка автоматических задач..."
    
    # Создание crontab для пользователя caseplatform
    sudo -u caseplatform crontab -l > /tmp/caseplatform_cron 2>/dev/null || echo "" > /tmp/caseplatform_cron
    
    # Добавление задач
    cat >> /tmp/caseplatform_cron << EOF
# Case Platform автоматические задачи
0 2 * * * /var/www/case-platform/scripts/backup.sh >> /var/log/case-platform-backup.log 2>&1
*/5 * * * * /var/www/case-platform/scripts/status.sh >> /var/log/case-platform-status.log 2>&1
0 4 * * 0 docker system prune -f >> /var/log/docker-cleanup.log 2>&1
EOF
    
    sudo -u caseplatform crontab /tmp/caseplatform_cron
    rm /tmp/caseplatform_cron
    
    log_success "Автоматические задачи настроены"
}

# Финальная настройка безопасности
setup_security() {
    log_info "Финальная настройка безопасности..."
    
    # Настройка fail2ban
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[nginx-http-auth]
enabled = true

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
EOF

    systemctl restart fail2ban
    
    # Отключение ненужных сервисов
    systemctl disable --now apache2 2>/dev/null || true
    
    # Настройка SSH (если нужно)
    log_warning "Рекомендуется настроить SSH ключи и отключить парольную аутентификацию"
    
    log_success "Безопасность настроена"
}

# Основная функция установки
main() {
    echo -e "${GREEN}==================================${NC}"
    echo -e "${GREEN}Case Platform Production Installer${NC}"
    echo -e "${GREEN}==================================${NC}"
    echo ""
    
    check_os
    get_user_input
    
    log_info "Начинаем установку..."
    
    update_system
    setup_firewall
    install_docker
    install_docker_compose
    create_app_user
    install_nginx
    install_certbot
    clone_project
    create_production_config
    setup_monitoring
    setup_systemd_services
    create_management_scripts
    setup_cron_jobs
    setup_security
    
    echo ""
    echo -e "${GREEN}🎉 Установка Case Platform завершена!${NC}"
    echo ""
    echo -e "${YELLOW}📝 Следующие шаги:${NC}"
    echo "1. Разместите код проекта в /var/www/case-platform"
    echo "2. Настройте .env файлы с вашими API ключами"
    echo "3. Запустите: systemctl start case-platform"
    echo "4. Проверьте: https://$DOMAIN"
    echo ""
    echo -e "${BLUE}📁 Полезные команды:${NC}"
    echo "• Статус: /var/www/case-platform/scripts/status.sh"
    echo "• Запуск: /var/www/case-platform/scripts/start.sh"
    echo "• Остановка: /var/www/case-platform/scripts/stop.sh"
    echo "• Обновление: /var/www/case-platform/scripts/update.sh"
    echo "• Бэкап: /var/www/case-platform/scripts/backup.sh"
    echo ""
    echo -e "${GREEN}✅ Установка завершена успешно!${NC}"
}

# Запуск установки
main "$@"
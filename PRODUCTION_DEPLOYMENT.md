# 🚀 Case Platform - Деплой в продакшен

Полная инструкция по установке и настройке Case Platform на продакшен сервере.

## 📋 Требования к серверу

### Минимальные требования
- **ОС**: Ubuntu 20.04+ или Debian 11+
- **CPU**: 4 ядра
- **RAM**: 8GB
- **Storage**: 100GB SSD
- **Network**: 1Gbps

### Рекомендуемые требования
- **ОС**: Ubuntu 22.04 LTS
- **CPU**: 8 ядер
- **RAM**: 16GB
- **Storage**: 500GB SSD
- **Network**: 1Gbps с CDN

## 🔧 Автоматическая установка

### Метод 1: Полная автоматическая установка

```bash
# Скачивание и запуск установщика
wget https://raw.githubusercontent.com/your-repo/case-platform/main/scripts/install-production.sh
chmod +x install-production.sh
sudo bash install-production.sh
```

**Что происходит при установке:**
1. ✅ Проверка и обновление системы
2. ✅ Установка Docker и Docker Compose  
3. ✅ Настройка firewall (UFW)
4. ✅ Установка и настройка Nginx
5. ✅ Получение SSL сертификата (Let's Encrypt)
6. ✅ Создание пользователя приложения
7. ✅ Настройка автозапуска сервисов
8. ✅ Создание скриптов управления
9. ✅ Настройка мониторинга и логирования
10. ✅ Настройка безопасности (fail2ban)

### Метод 2: Деплой из Git репозитория

```bash
# После автоматической установки
sudo bash /var/www/case-platform/scripts/deploy-from-git.sh https://github.com/your-repo/case-platform.git main
```

## 🔐 Ручная установка (пошагово)

### Шаг 1: Подготовка сервера

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
sudo apt install -y curl wget git unzip nginx ufw fail2ban

# Настройка firewall
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### Шаг 2: Установка Docker

```bash
# Удаление старых версий
sudo apt remove docker docker-engine docker.io containerd runc

# Установка зависимостей
sudo apt install -y apt-transport-https ca-certificates gnupg lsb-release

# Добавление GPG ключа Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Добавление репозитория Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установка Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Автозапуск Docker
sudo systemctl enable docker
sudo systemctl start docker
```

### Шаг 3: Установка Docker Compose

```bash
# Скачивание последней версии
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Права выполнения
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
```

### Шаг 4: Создание пользователя приложения

```bash
# Создание пользователя
sudo useradd -r -s /bin/bash -d /var/www/case-platform -m caseplatform
sudo usermod -aG docker caseplatform
```

### Шаг 5: Клонирование проекта

```bash
# Клонирование репозитория
sudo git clone https://github.com/your-repo/case-platform.git /var/www/case-platform
sudo chown -R caseplatform:caseplatform /var/www/case-platform
cd /var/www/case-platform
```

### Шаг 6: Настройка конфигурации

```bash
# Копирование конфигурационных файлов
sudo cp backend/.env.example backend/.env
sudo cp frontend/.env.example frontend/.env
sudo cp websocket/.env.example websocket/.env
```

**Отредактируйте файлы конфигурации:**

#### backend/.env
```bash
sudo nano backend/.env
```

```env
APP_NAME="Case Platform"
APP_ENV=production
APP_DEBUG=false
APP_URL=https://yourdomain.com

DB_CONNECTION=mysql
DB_HOST=mysql
DB_DATABASE=case_platform
DB_USERNAME=case_user
DB_PASSWORD=your_secure_db_password

REDIS_HOST=redis
REDIS_PASSWORD=your_secure_redis_password

STEAM_API_KEY=your_steam_api_key
TELEGRAM_BOT_TOKEN=your_telegram_bot_token

SESSION_SECURE_COOKIE=true
SANCTUM_STATEFUL_DOMAINS=yourdomain.com,www.yourdomain.com
```

#### frontend/.env
```bash
sudo nano frontend/.env
```

```env
VITE_API_URL=https://yourdomain.com/api
VITE_API_BASE_URL=https://yourdomain.com
VITE_WS_URL=https://yourdomain.com
VITE_APP_ENV=production
```

#### websocket/.env
```bash
sudo nano websocket/.env
```

```env
NODE_ENV=production
DB_HOST=mysql
DB_PASSWORD=your_secure_db_password
REDIS_HOST=redis
REDIS_PASSWORD=your_secure_redis_password
CORS_ORIGIN=https://yourdomain.com,https://www.yourdomain.com
```

### Шаг 7: Настройка Nginx

```bash
# Создание конфигурации сайта
sudo nano /etc/nginx/sites-available/case-platform
```

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;
    
    # SSL certificates (will be configured by Certbot)
    
    client_max_body_size 100M;
    
    # Frontend
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # API
    location /api {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Admin
    location /admin {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # WebSocket
    location /socket.io/ {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400;
    }
}
```

```bash
# Активация сайта
sudo ln -s /etc/nginx/sites-available/case-platform /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

### Шаг 8: Получение SSL сертификата

```bash
# Установка Certbot
sudo apt install snapd
sudo snap install core
sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

# Получение сертификата
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

### Шаг 9: Запуск приложения

```bash
cd /var/www/case-platform

# Сборка и запуск контейнеров
sudo docker-compose -f docker-compose.prod.yml build
sudo docker-compose -f docker-compose.prod.yml up -d

# Ожидание запуска MySQL
sleep 30

# Настройка Laravel
sudo docker-compose -f docker-compose.prod.yml exec php composer install --no-dev --optimize-autoloader
sudo docker-compose -f docker-compose.prod.yml exec php php artisan key:generate --force
sudo docker-compose -f docker-compose.prod.yml exec php php artisan migrate --force
sudo docker-compose -f docker-compose.prod.yml exec php php artisan storage:link
sudo docker-compose -f docker-compose.prod.yml exec php php artisan config:cache
sudo docker-compose -f docker-compose.prod.yml exec php php artisan route:cache
sudo docker-compose -f docker-compose.prod.yml exec php php artisan view:cache

# Установка Voyager
sudo docker-compose -f docker-compose.prod.yml exec php php artisan voyager:install --with-dummy

# Создание администратора
sudo docker-compose -f docker-compose.prod.yml exec php php artisan voyager:admin admin@yourdomain.com --create
```

### Шаг 10: Настройка автозапуска

```bash
# Создание systemd сервиса
sudo nano /etc/systemd/system/case-platform.service
```

```ini
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
User=caseplatform
Group=caseplatform

[Install]
WantedBy=multi-user.target
```

```bash
# Активация сервиса
sudo systemctl daemon-reload
sudo systemctl enable case-platform
sudo systemctl start case-platform
```

## 🔍 Проверка установки

### Проверка статуса сервисов

```bash
# Статус контейнеров
cd /var/www/case-platform
sudo docker-compose -f docker-compose.prod.yml ps

# Проверка логов
sudo docker-compose -f docker-compose.prod.yml logs -f

# Проверка здоровья
curl -f https://yourdomain.com/health
curl -f https://yourdomain.com/api/health
```

### Тестирование функций

1. **Frontend**: https://yourdomain.com
2. **API**: https://yourdomain.com/api/health
3. **Админка**: https://yourdomain.com/admin
4. **WebSocket**: Проверить в консоли браузера
5. **SSL**: https://www.ssllabs.com/ssltest/

## 🛠️ Управление сервисом

### Полезные команды

```bash
# Запуск
sudo systemctl start case-platform
# или
cd /var/www/case-platform && sudo docker-compose -f docker-compose.prod.yml up -d

# Остановка
sudo systemctl stop case-platform
# или  
cd /var/www/case-platform && sudo docker-compose -f docker-compose.prod.yml down

# Перезапуск
sudo systemctl restart case-platform

# Статус
sudo systemctl status case-platform

# Логи
sudo journalctl -u case-platform -f
sudo docker-compose -f docker-compose.prod.yml logs -f
```

### Скрипты управления

После установки доступны удобные скрипты:

```bash
# Статус всех сервисов
/var/www/case-platform/scripts/status.sh

# Запуск
/var/www/case-platform/scripts/start.sh

# Остановка
/var/www/case-platform/scripts/stop.sh

# Обновление
/var/www/case-platform/scripts/update.sh

# Бэкап
/var/www/case-platform/scripts/backup.sh
```

## 🔄 Обновление и деплой

### Автоматическое обновление

```bash
# Обновление из Git
sudo bash /var/www/case-platform/scripts/deploy-from-git.sh

# Или с указанием ветки
sudo bash /var/www/case-platform/scripts/deploy-from-git.sh https://github.com/your-repo/case-platform.git production
```

### Ручное обновление

```bash
cd /var/www/case-platform

# Бэкап
sudo ./scripts/backup.sh

# Остановка сервисов
sudo docker-compose -f docker-compose.prod.yml down

# Обновление кода
sudo git pull origin main

# Сборка новых образов
sudo docker-compose -f docker-compose.prod.yml build --no-cache

# Запуск
sudo docker-compose -f docker-compose.prod.yml up -d

# Миграции
sudo docker-compose -f docker-compose.prod.yml exec php php artisan migrate --force

# Очистка кеша
sudo docker-compose -f docker-compose.prod.yml exec php php artisan config:cache
sudo docker-compose -f docker-compose.prod.yml exec php php artisan route:cache
sudo docker-compose -f docker-compose.prod.yml exec php php artisan view:cache

# Перезапуск очередей
sudo docker-compose -f docker-compose.prod.yml exec php php artisan queue:restart
```

## 💾 Бэкапы

### Автоматические бэкапы

Автоматические бэкапы настроены через cron:

```bash
# Проверка задач cron
sudo -u caseplatform crontab -l

# Ручной бэкап
sudo -u caseplatform /var/www/case-platform/scripts/backup.sh

# Расположение бэкапов
ls -la /var/backups/case-platform/
```

### Ручное создание бэкапа

```bash
cd /var/www/case-platform

# Бэкап базы данных
sudo docker-compose -f docker-compose.prod.yml exec mysql mysqldump \
  -u case_user -p$(grep DB_PASSWORD backend/.env | cut -d '=' -f2) \
  case_platform > backup_$(date +%Y%m%d_%H%M%S).sql

# Бэкап файлов приложения
sudo tar -czf app_backup_$(date +%Y%m%d_%H%M%S).tar.gz \
  backend/storage/app \
  backend/.env \
  frontend/.env \
  websocket/.env
```

### Восстановление из бэкапа

```bash
cd /var/www/case-platform

# Восстановление базы данных
sudo docker-compose -f docker-compose.prod.yml exec -T mysql mysql \
  -u case_user -p$(grep DB_PASSWORD backend/.env | cut -d '=' -f2) \
  case_platform < backup_file.sql

# Восстановление файлов
sudo tar -xzf app_backup_file.tar.gz
```

## 📊 Мониторинг

### Логи

```bash
# Логи приложения
sudo tail -f /var/www/case-platform/backend/storage/logs/laravel.log

# Логи WebSocket
sudo docker-compose -f docker-compose.prod.yml logs -f websocket

# Логи Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Системные логи
sudo journalctl -u case-platform -f
```

### Мониторинг ресурсов

```bash
# Использование ресурсов контейнерами
sudo docker stats

# Состояние сервера
htop
df -h
free -h
```

### Health Checks

```bash
# Проверка API
curl -f https://yourdomain.com/api/health

# Проверка WebSocket
curl -f https://yourdomain.com:3001/health

# Проверка всех сервисов
/var/www/case-platform/scripts/status.sh
```

## 🔐 Безопасность

### Настройка fail2ban

```bash
sudo nano /etc/fail2ban/jail.local
```

```ini
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
maxretry = 3
```

### Настройка SSH

```bash
# Генерация SSH ключей (на локальной машине)
ssh-keygen -t rsa -b 4096

# Копирование ключа на сервер
ssh-copy-id user@server_ip

# Отключение парольной аутентификации
sudo nano /etc/ssh/sshd_config
```

```
PasswordAuthentication no
PermitRootLogin no
```

```bash
sudo systemctl restart ssh
```

### Обновления безопасности

```bash
# Автоматические обновления безопасности
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

## 🚨 Решение проблем

### Общие проблемы

**1. Контейнеры не запускаются**
```bash
# Проверка логов
sudo docker-compose -f docker-compose.prod.yml logs

# Проверка портов
sudo netstat -tulpn | grep -E ':80|:443|:3306|:6379'

# Перезапуск Docker
sudo systemctl restart docker
```

**2. Ошибки базы данных**
```bash
# Проверка подключения к MySQL
sudo docker-compose -f docker-compose.prod.yml exec mysql mysql -u case_user -p

# Проверка логов MySQL
sudo docker-compose -f docker-compose.prod.yml logs mysql
```

**3. Проблемы с SSL**
```bash
# Обновление сертификата
sudo certbot renew

# Проверка конфигурации Nginx
sudo nginx -t
```

**4. Проблемы с производительностью**
```bash
# Оптимизация кеша
sudo docker-compose -f docker-compose.prod.yml exec php php artisan optimize

# Очистка логов
sudo docker-compose -f docker-compose.prod.yml exec php php artisan log:clear
```

### Контакты поддержки

- **Email**: support@case-platform.com
- **Telegram**: @case_platform_support
- **GitHub Issues**: https://github.com/your-repo/case-platform/issues

## 📈 Оптимизация производительности

### Настройка MySQL

```sql
-- Оптимизация для SSD
SET GLOBAL innodb_flush_method = 'O_DIRECT';

-- Увеличение buffer pool
SET GLOBAL innodb_buffer_pool_size = 2147483648; -- 2GB

-- Оптимизация соединений  
SET GLOBAL max_connections = 1000;
```

### Настройка Redis

```bash
# Максимальная память
redis-cli CONFIG SET maxmemory 512mb
redis-cli CONFIG SET maxmemory-policy allkeys-lru

# Сохранение на диск
redis-cli CONFIG SET save "900 1 300 10 60 10000"
```

### Кеширование статики

```nginx
# В конфигурации Nginx
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

---

🎉 **Поздравляем! Case Platform успешно развернут в продакшене!**

Теперь ваша платформа готова к работе и может обслуживать тысячи пользователей. Не забудьте настроить мониторинг, автоматические бэкапы и регулярные обновления безопасности.
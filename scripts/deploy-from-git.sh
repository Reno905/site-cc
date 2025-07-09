#!/bin/bash

# Case Platform Git Deployment Script
# Скрипт для деплоя из Git репозитория

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Параметры
GIT_REPO="${1:-https://github.com/your-username/case-platform.git}"
BRANCH="${2:-main}"
DEPLOY_DIR="/var/www/case-platform"
BACKUP_DIR="/var/backups/case-platform"

# Функции вывода
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

# Проверка прав
check_permissions() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Запустите скрипт с правами root: sudo bash deploy-from-git.sh"
        exit 1
    fi
}

# Создание бэкапа
create_backup() {
    log_info "Создание бэкапа текущего деплоя..."
    
    if [ -d "$DEPLOY_DIR" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mkdir -p "$BACKUP_DIR"
        
        # Бэкап кода
        tar -czf "$BACKUP_DIR/code_backup_$TIMESTAMP.tar.gz" -C "$(dirname $DEPLOY_DIR)" "$(basename $DEPLOY_DIR)" 2>/dev/null || true
        
        # Бэкап базы данных (если контейнеры запущены)
        if docker ps | grep -q case_platform_mysql_prod; then
            log_info "Создание бэкапа базы данных..."
            cd "$DEPLOY_DIR"
            docker-compose -f docker-compose.prod.yml exec -T mysql mysqldump \
                -u case_user -p$(grep DB_PASSWORD backend/.env | cut -d '=' -f2) \
                case_platform > "$BACKUP_DIR/database_backup_$TIMESTAMP.sql" 2>/dev/null || true
        fi
        
        log_success "Бэкап создан: $BACKUP_DIR"
    fi
}

# Клонирование или обновление репозитория
deploy_code() {
    log_info "Деплой кода из репозитория: $GIT_REPO"
    
    if [ -d "$DEPLOY_DIR/.git" ]; then
        log_info "Обновление существующего репозитория..."
        cd "$DEPLOY_DIR"
        git fetch origin
        git checkout "$BRANCH"
        git pull origin "$BRANCH"
    else
        log_info "Клонирование репозитория..."
        rm -rf "$DEPLOY_DIR"
        git clone -b "$BRANCH" "$GIT_REPO" "$DEPLOY_DIR"
        cd "$DEPLOY_DIR"
    fi
    
    log_success "Код обновлен до последней версии ветки $BRANCH"
}

# Настройка прав доступа
setup_permissions() {
    log_info "Настройка прав доступа..."
    
    chown -R caseplatform:caseplatform "$DEPLOY_DIR"
    chmod -R 755 "$DEPLOY_DIR"
    chmod +x "$DEPLOY_DIR/scripts/"*.sh
    
    # Специальные права для Laravel
    if [ -d "$DEPLOY_DIR/backend/storage" ]; then
        chmod -R 775 "$DEPLOY_DIR/backend/storage"
        chmod -R 775 "$DEPLOY_DIR/backend/bootstrap/cache"
    fi
    
    log_success "Права доступа настроены"
}

# Сборка контейнеров
build_containers() {
    log_info "Сборка Docker контейнеров..."
    
    cd "$DEPLOY_DIR"
    
    # Останавливаем текущие контейнеры
    docker-compose -f docker-compose.prod.yml down || true
    
    # Собираем новые образы
    docker-compose -f docker-compose.prod.yml build --no-cache
    
    log_success "Контейнеры собраны"
}

# Запуск сервисов
start_services() {
    log_info "Запуск сервисов..."
    
    cd "$DEPLOY_DIR"
    
    # Запуск контейнеров
    docker-compose -f docker-compose.prod.yml up -d
    
    # Ожидание запуска MySQL
    log_info "Ожидание запуска MySQL..."
    sleep 30
    
    # Проверка здоровья сервисов
    for i in {1..12}; do
        if docker-compose -f docker-compose.prod.yml ps | grep -q "Up (healthy)"; then
            break
        fi
        log_info "Ожидание готовности сервисов... ($i/12)"
        sleep 10
    done
    
    log_success "Сервисы запущены"
}

# Настройка Laravel
setup_laravel() {
    log_info "Настройка Laravel..."
    
    cd "$DEPLOY_DIR"
    
    # Установка зависимостей
    docker-compose -f docker-compose.prod.yml exec -T php composer install --no-dev --optimize-autoloader
    
    # Генерация ключа приложения (если не существует)
    if ! grep -q "APP_KEY=base64:" backend/.env; then
        docker-compose -f docker-compose.prod.yml exec -T php php artisan key:generate --force
    fi
    
    # Миграции базы данных
    docker-compose -f docker-compose.prod.yml exec -T php php artisan migrate --force
    
    # Создание символических ссылок
    docker-compose -f docker-compose.prod.yml exec -T php php artisan storage:link
    
    # Кеширование конфигурации
    docker-compose -f docker-compose.prod.yml exec -T php php artisan config:cache
    docker-compose -f docker-compose.prod.yml exec -T php php artisan route:cache
    docker-compose -f docker-compose.prod.yml exec -T php php artisan view:cache
    
    # Перезапуск очередей
    docker-compose -f docker-compose.prod.yml exec -T php php artisan queue:restart
    
    log_success "Laravel настроен"
}

# Установка Voyager (если первый деплой)
setup_voyager() {
    log_info "Проверка Voyager..."
    
    cd "$DEPLOY_DIR"
    
    # Проверяем, установлен ли Voyager
    if ! docker-compose -f docker-compose.prod.yml exec -T php php artisan voyager:admin --help >/dev/null 2>&1; then
        log_info "Установка Voyager..."
        docker-compose -f docker-compose.prod.yml exec -T php php artisan voyager:install --with-dummy
        
        log_warning "Создайте администратора: docker-compose -f docker-compose.prod.yml exec php php artisan voyager:admin email@example.com --create"
    else
        log_success "Voyager уже установлен"
    fi
}

# Проверка здоровья сервисов
health_check() {
    log_info "Проверка здоровья сервисов..."
    
    cd "$DEPLOY_DIR"
    
    # Проверка контейнеров
    if ! docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
        log_error "Некоторые контейнеры не запущены"
        docker-compose -f docker-compose.prod.yml ps
        exit 1
    fi
    
    # Проверка подключения к базе данных
    if ! docker-compose -f docker-compose.prod.yml exec -T mysql mysql -u case_user -p$(grep DB_PASSWORD backend/.env | cut -d '=' -f2) -e "SELECT 1" case_platform >/dev/null 2>&1; then
        log_error "Не удается подключиться к базе данных"
        exit 1
    fi
    
    # Проверка Redis
    if ! docker-compose -f docker-compose.prod.yml exec -T redis redis-cli -a $(grep REDIS_PASSWORD backend/.env | cut -d '=' -f2) ping >/dev/null 2>&1; then
        log_error "Не удается подключиться к Redis"
        exit 1
    fi
    
    log_success "Все сервисы работают корректно"
}

# Очистка старых образов
cleanup() {
    log_info "Очистка старых Docker образов..."
    
    docker image prune -f >/dev/null 2>&1 || true
    docker container prune -f >/dev/null 2>&1 || true
    
    # Удаление старых бэкапов (старше 30 дней)
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete 2>/dev/null || true
    find "$BACKUP_DIR" -name "*.sql" -mtime +30 -delete 2>/dev/null || true
    
    log_success "Очистка завершена"
}

# Вывод информации о деплое
show_info() {
    echo ""
    echo -e "${GREEN}🎉 Деплой Case Platform завершен!${NC}"
    echo ""
    echo -e "${BLUE}📊 Информация о деплое:${NC}"
    echo "• Репозиторий: $GIT_REPO"
    echo "• Ветка: $BRANCH"
    echo "• Директория: $DEPLOY_DIR"
    echo "• Время: $(date)"
    echo ""
    echo -e "${BLUE}🔗 Полезные команды:${NC}"
    echo "• Статус: $DEPLOY_DIR/scripts/status.sh"
    echo "• Логи: docker-compose -f $DEPLOY_DIR/docker-compose.prod.yml logs -f"
    echo "• Остановка: docker-compose -f $DEPLOY_DIR/docker-compose.prod.yml down"
    echo ""
    echo -e "${YELLOW}⚠️  Не забудьте:${NC}"
    echo "• Настроить .env файлы с реальными API ключами"
    echo "• Создать администратора Voyager"
    echo "• Настроить DNS записи для домена"
    echo ""
}

# Основная функция
main() {
    echo -e "${GREEN}🚀 Case Platform Git Deployment${NC}"
    echo -e "${BLUE}Репозиторий: $GIT_REPO${NC}"
    echo -e "${BLUE}Ветка: $BRANCH${NC}"
    echo ""
    
    check_permissions
    create_backup
    deploy_code
    setup_permissions
    build_containers
    start_services
    setup_laravel
    setup_voyager
    health_check
    cleanup
    show_info
}

# Запуск деплоя
main "$@"
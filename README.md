# Case Platform

Полнофункциональная платформа для открытия игровых кейсов с интеграцией Steam, реалтайм-функциональностью и честной системой дропа.

## 🚀 Особенности

- **Steam интеграция**: Авторизация через Steam OpenID, интеграция с инвентарем
- **Реалтайм**: WebSocket соединения для live обновлений
- **Provably Fair**: Честная система дропа с возможностью верификации
- **Современный стек**: Laravel 10, Vue.js 3, Socket.io, Redis, MySQL
- **Админка**: Полнофункциональная панель управления на Laravel Voyager
- **Платежи**: Интеграция с множественными платежными системами
- **DevOps**: Docker контейнеризация, CI/CD через GitHub Actions

## 📋 Системные требования

- Docker 20.10+
- Docker Compose 2.0+
- Node.js 18+ (для локальной разработки)
- PHP 8.2+ (для локальной разработки)

## 🛠️ Быстрый старт

### 1. Клонирование репозитория

```bash
git clone <repository-url>
cd case-platform
```

### 2. Настройка окружения

```bash
# Скопировать файлы окружения
cp backend/.env.example backend/.env
cp websocket/.env.example websocket/.env
cp frontend/.env.example frontend/.env

# Настроить переменные в backend/.env
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=case_platform
DB_USERNAME=case_user
DB_PASSWORD=case_password

REDIS_HOST=redis
REDIS_PASSWORD=redis_password
REDIS_PORT=6379

STEAM_API_KEY=your_steam_api_key
STEAM_CLIENT_ID=your_steam_client_id
STEAM_CLIENT_SECRET=your_steam_client_secret
```

### 3. Запуск через Docker

```bash
# Запуск всех сервисов
docker-compose up -d

# Для разработки с hot-reload
docker-compose --profile dev up -d
```

### 4. Инициализация backend

```bash
# Войти в PHP контейнер
docker-compose exec php bash

# Установить зависимости
composer install

# Генерация ключа приложения
php artisan key:generate

# Запуск миграций
php artisan migrate

# Заполнение тестовыми данными
php artisan db:seed

# Установка Voyager
php artisan voyager:install

# Создание администратора
php artisan voyager:admin admin@example.com --create

# Запуск Horizon (в отдельном терминале)
php artisan horizon
```

### 5. Инициализация frontend

```bash
# Войти в frontend контейнер (если используете dev профиль)
docker-compose exec frontend bash

# Или локально
cd frontend
npm install
npm run dev
```

## 🔗 Доступ к сервисам

- **Frontend**: http://localhost:3000 (dev) или http://localhost (prod)
- **API**: http://localhost/api или http://localhost:8000/api
- **Админка**: http://localhost/admin или http://localhost:8000/admin
- **WebSocket**: ws://localhost:3001
- **PhpMyAdmin**: http://localhost:8080 (dev профиль)
- **Horizon**: http://localhost:8000/horizon

## 📁 Структура проекта

```
case-platform/
├── backend/                 # Laravel API Backend
│   ├── app/
│   │   ├── Http/Controllers/
│   │   ├── Models/
│   │   ├── Services/
│   │   └── Jobs/
│   ├── database/
│   ├── routes/
│   └── config/
├── frontend/                # Vue.js Frontend
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── stores/
│   │   └── services/
│   └── public/
├── websocket/              # Node.js WebSocket Server
│   ├── src/
│   │   ├── handlers/
│   │   └── middleware/
│   └── package.json
├── docker/                 # Docker конфигурации
│   ├── nginx/
│   ├── php/
│   └── mysql/
└── .github/workflows/      # CI/CD
```

## 🔧 Разработка

### Backend (Laravel)

```bash
# Установка зависимостей
cd backend
composer install

# Запуск тестов
php artisan test

# Генерация IDE helper файлов
php artisan ide-helper:generate
php artisan ide-helper:models

# Очистка кеша
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear
```

### Frontend (Vue.js)

```bash
# Установка зависимостей
cd frontend
npm install

# Запуск dev сервера
npm run dev

# Сборка для продакшена
npm run build

# Линтинг
npm run lint

# Проверка типов
npm run type-check
```

### WebSocket Server

```bash
# Установка зависимостей
cd websocket
npm install

# Запуск dev сервера
npm run dev

# Запуск тестов
npm test

# Линтинг
npm run lint
```

## 🗃️ База данных

### Основные таблицы

- `users` - Пользователи
- `cases` - Кейсы
- `items` - Предметы
- `case_items` - Связь кейсов и предметов с шансами
- `openings` - История открытий
- `payments` - Платежи
- `promocodes` - Промокоды

### Миграции

```bash
# Создание новой миграции
php artisan make:migration create_table_name

# Запуск миграций
php artisan migrate

# Откат миграций
php artisan migrate:rollback

# Обновление миграций
php artisan migrate:refresh --seed
```

## 🔐 Безопасность

### API Authentication

Используется Laravel Sanctum для API аутентификации:

```javascript
// Frontend
const response = await axios.post('/api/login', credentials)
const token = response.data.token

// Установка заголовка для всех запросов
axios.defaults.headers.common['Authorization'] = `Bearer ${token}`
```

### Rate Limiting

Настроено ограничение запросов:
- API: 10 запросов/сек
- Login: 1 запрос/сек

### Steam Integration

```php
// Настройка Steam авторизации в config/services.php
'steam' => [
    'client_id' => env('STEAM_CLIENT_ID'),
    'client_secret' => env('STEAM_CLIENT_SECRET'),
    'redirect' => env('STEAM_REDIRECT_URI'),
    'api_key' => env('STEAM_API_KEY'),
],
```

## 📊 Мониторинг

### Laravel Horizon

Horizon предоставляет дашборд для мониторинга очередей:
- http://localhost:8000/horizon

### Логи

```bash
# Просмотр логов
docker-compose logs -f php
docker-compose logs -f websocket
docker-compose logs -f nginx

# Laravel логи
tail -f backend/storage/logs/laravel.log
```

## 🚀 Деплой

### Настройка сервера

```bash
# Установка Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Установка Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Клонирование проекта
git clone <repository-url> /var/www/case-platform
cd /var/www/case-platform
```

### Продакшен конфигурация

```bash
# Создание продакшен docker-compose файла
cp docker-compose.yml docker-compose.prod.yml

# Настройка SSL сертификатов
sudo mkdir -p /etc/ssl/certs
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/certs/case-platform.key \
  -out /etc/ssl/certs/case-platform.crt

# Запуск в продакшене
docker-compose -f docker-compose.prod.yml up -d
```

### CI/CD

GitHub Actions автоматически:
1. Запускает тесты
2. Собирает Docker образы
3. Деплоит на сервер
4. Отправляет уведомления в Slack

Настройте следующие секреты в GitHub:
- `HOST` - IP адрес сервера
- `USERNAME` - SSH пользователь
- `SSH_KEY` - SSH ключ
- `CONTAINER_REGISTRY` - URL регистра контейнеров
- `REGISTRY_USERNAME` - Логин регистра
- `REGISTRY_PASSWORD` - Пароль регистра
- `SLACK_WEBHOOK` - Webhook для уведомлений

## 🐛 Отладка

### Общие проблемы

1. **Ошибки подключения к БД**:
   ```bash
   # Проверить статус контейнеров
   docker-compose ps
   
   # Проверить логи MySQL
   docker-compose logs mysql
   ```

2. **Проблемы с Redis**:
   ```bash
   # Тест подключения к Redis
   docker-compose exec redis redis-cli ping
   ```

3. **Проблемы с правами файлов**:
   ```bash
   # Исправление прав в Laravel
   sudo chown -R www-data:www-data backend/storage
   sudo chmod -R 775 backend/storage
   ```

### Полезные команды

```bash
# Полная перезагрузка
docker-compose down -v
docker-compose up -d --build

# Очистка Docker
docker system prune -a

# Бэкап базы данных
docker-compose exec mysql mysqldump -u case_user -p case_platform > backup.sql

# Восстановление базы данных
docker-compose exec -T mysql mysql -u case_user -p case_platform < backup.sql
```

## 📝 Вклад в проект

1. Форкните репозиторий
2. Создайте feature ветку (`git checkout -b feature/amazing-feature`)
3. Зафиксируйте изменения (`git commit -m 'Add amazing feature'`)
4. Отправьте в ветку (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

## 📄 Лицензия

Этот проект лицензирован под MIT License - смотрите [LICENSE](LICENSE) файл для деталей.

## 📞 Поддержка

- Email: support@case-platform.com
- Telegram: @case_platform_support
- Documentation: https://docs.case-platform.com

---

**Сделано с ❤️ командой Case Platform**
# Case Platform - Краткое резюме проекта

## 🎯 Описание
Полнофункциональная платформа для открытия игровых кейсов с интеграцией Steam, реалтайм-функциональностью и честной системой дропа (Provably Fair).

## 📋 Стек технологий

### Backend
- **Laravel 10** - REST API, админка
- **Laravel Voyager** - админ-панель 
- **Laravel Sanctum** - API авторизация
- **Laravel Horizon** - мониторинг очередей
- **MySQL 8.0** - основная база данных
- **Redis 7** - кеш и очереди

### Frontend  
- **Vue.js 3** - SPA приложение
- **TailwindCSS** - стилизация
- **Vite** - сборщик
- **GSAP** - анимации
- **Socket.io** - WebSocket клиент

### WebSocket
- **Node.js 18** - WebSocket сервер
- **Socket.io** - реалтайм коммуникация
- **Express** - HTTP сервер

### DevOps
- **Docker** - контейнеризация
- **Nginx** - веб-сервер
- **GitHub Actions** - CI/CD

## 🚀 Быстрый старт

```bash
# 1. Установка
make install

# 2. Настройка .env файлов
# Отредактируйте backend/.env, websocket/.env, frontend/.env

# 3. Запуск для разработки
make dev-setup

# 4. Доступ к сервисам
# Frontend: http://localhost:3000
# API: http://localhost/api
# Админка: http://localhost/admin
# WebSocket: ws://localhost:3001
```

## 📁 Структура проекта

```
case-platform/
├── backend/           # Laravel API
├── frontend/          # Vue.js SPA  
├── websocket/         # Node.js WebSocket
├── docker/           # Docker конфигурации
├── .github/          # CI/CD workflows
└── docker-compose.yml
```

## 🔧 Основные команды (Makefile)

```bash
make help              # Показать все команды
make start             # Запустить все сервисы
make start-dev         # Запуск в dev режиме
make stop              # Остановить сервисы
make logs              # Показать логи
make test              # Запустить тесты
make clean             # Очистка контейнеров
```

## 🎮 Основные функции

### Пользовательские
- Steam авторизация
- Открытие кейсов с анимацией
- Инвентарь предметов
- Реферальная система
- Пополнение/вывод средств

### Административные
- Управление кейсами и предметами
- Финансовая статистика
- Управление пользователями
- Live-мониторинг активности
- Настройки платформы

### Технические
- Provably Fair система
- Антиминус система
- Rate limiting
- Автоматическое масштабирование
- Мониторинг и логирование

## 💳 Интеграции

### Платежные системы
- Qiwi
- ЮMoney  
- Crypto Bot
- Банковские карты
- Steam Market

### Внешние сервисы
- Steam OpenID + API
- Telegram Bot
- Email сервис
- Sentry (мониторинг ошибок)

## 🔐 Безопасность

- Laravel Sanctum для API
- JWT для WebSocket
- Rate limiting
- CORS настройки
- Антифрод система
- Логирование подозрительной активности

## 📊 Мониторинг

- Laravel Horizon для очередей
- Winston логирование для WebSocket
- Health checks для всех сервисов
- Метрики производительности
- Telegram уведомления

## 🚀 Деплой

### Разработка
```bash
make start-dev
```

### Продакшен
```bash
make deploy-prod
```

### CI/CD
- Автоматические тесты
- Сборка Docker образов
- Деплой через SSH
- Slack уведомления

## 📝 Конфигурация

### Backend (.env)
- Настройки БД и Redis
- Steam API ключи
- Платежные системы
- Telegram интеграция

### Frontend (.env)
- API endpoints
- WebSocket URL
- Аналитика
- Feature flags

### WebSocket (.env)
- База данных
- Redis
- JWT секрет
- CORS настройки

## 🔧 Разработка

### Backend
```bash
make backend-shell     # Доступ к контейнеру
make backend-artisan   # Artisan команды
make backend-test      # Тесты
```

### Frontend
```bash
make frontend-shell    # Доступ к контейнеру  
make frontend-build    # Сборка
make frontend-test     # Тесты
```

### WebSocket
```bash
make websocket-shell   # Доступ к контейнеру
make websocket-test    # Тесты
```

## 📈 Масштабирование

### Горизонтальное
- Load balancer
- Несколько app серверов
- Database clustering
- CDN для статики

### Вертикальное
- Увеличение ресурсов
- Database optimization
- Cache scaling
- SSD storage

## 📞 Поддержка

- **Email**: support@case-platform.com
- **Telegram**: @case_platform_support
- **Документация**: Полная в ARCHITECTURE.md
- **Issue tracking**: GitHub Issues

---

**Создано командой Case Platform** 🎲
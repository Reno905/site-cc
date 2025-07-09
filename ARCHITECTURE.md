# Архитектура платформы кейсов

## Обзор проекта

Платформа для открытия игровых кейсов с интеграцией Steam, реалтайм-функциональностью, системой платежей и честной системой дропа (Provably Fair).

## Техническая архитектура

### Backend

#### Laravel API
- **Версия**: Laravel 10+
- **Назначение**: REST API, админка, авторизация
- **Основные компоненты**:
  - API контроллеры для всех операций
  - Steam OpenID авторизация
  - Laravel Sanctum для API токенов
  - Laravel Voyager для админки
  - Provably Fair система

#### Node.js WebSocket Server
- **Назначение**: Реалтайм коммуникация
- **Технологии**: Socket.io
- **Функции**:
  - Уведомления об открытии кейсов
  - Live статистика
  - Чат (опционально)
  - Активность пользователей

#### База данных
- **Основная БД**: MySQL 8.0+ / PostgreSQL 14+
- **Кеш**: Redis 7+
- **Очереди**: Laravel Horizon + Redis

### Frontend

#### SPA Application
- **Framework**: Vue.js 3 / React 18
- **Стилизация**: TailwindCSS
- **Анимации**: GSAP, Swiper.js
- **Реалтайм**: Socket.io-client / Laravel Echo

## Структура проекта

```
case-platform/
├── backend/                    # Laravel API
│   ├── app/
│   │   ├── Http/Controllers/
│   │   │   ├── Api/
│   │   │   │   ├── AuthController.php
│   │   │   │   ├── CaseController.php
│   │   │   │   ├── UserController.php
│   │   │   │   ├── PaymentController.php
│   │   │   │   └── ItemController.php
│   │   │   └── Admin/
│   │   ├── Models/
│   │   │   ├── User.php
│   │   │   ├── Case.php
│   │   │   ├── Item.php
│   │   │   ├── CaseItem.php
│   │   │   ├── Opening.php
│   │   │   ├── Payment.php
│   │   │   └── Promocode.php
│   │   ├── Services/
│   │   │   ├── SteamService.php
│   │   │   ├── DropService.php
│   │   │   ├── PaymentService.php
│   │   │   └── ProvablyFairService.php
│   │   └── Jobs/
│   ├── database/
│   │   ├── migrations/
│   │   └── seeders/
│   ├── routes/
│   │   ├── api.php
│   │   └── web.php
│   └── config/
├── frontend/                   # Vue.js / React SPA
│   ├── src/
│   │   ├── components/
│   │   │   ├── Case/
│   │   │   ├── User/
│   │   │   ├── Payment/
│   │   │   └── Common/
│   │   ├── pages/
│   │   │   ├── Home.vue
│   │   │   ├── Cases.vue
│   │   │   ├── Profile.vue
│   │   │   └── Payment.vue
│   │   ├── store/
│   │   ├── services/
│   │   └── utils/
│   ├── public/
│   └── package.json
├── websocket/                  # Node.js WebSocket сервер
│   ├── src/
│   │   ├── server.js
│   │   ├── handlers/
│   │   └── middleware/
│   └── package.json
├── docker/
│   ├── nginx/
│   ├── php/
│   └── mysql/
├── docker-compose.yml
└── README.md
```

## Основные страницы

### 1. Главная страница
- **Компоненты**:
  - Популярные кейсы
  - Топ игроки за день/неделю/месяц
  - Лента последних выигрышей (реалтайм)
  - Промо-блоки и акции
  - Статистика платформы

### 2. Кейсы
- **Функции**:
  - Каталог с фильтрами (цена, категория, рейтинг)
  - Детальная страница кейса с содержимым
  - Анимация открытия (GSAP)
  - Auto-open и Multi-open режимы
  - История открытий пользователя

### 3. Профиль пользователя
- **Разделы**:
  - Баланс и транзакции
  - Steam trade URL
  - Инвентарь (полученные предметы)
  - История открытий
  - Реферальная система
  - Настройки аккаунта

### 4. Платежи
- **Пополнение**:
  - Qiwi, ЮMoney
  - Криптовалюты (Crypto Bot)
  - Банковские карты
  - Steam предметы (через API)
- **Вывод**:
  - Steam трейд
  - Продажа предметов
  - Вывод средств

## Админка (Laravel Voyager)

### Управление пользователями
- Просмотр профилей
- Бан/разбан
- Управление балансом
- Логи активности
- Steam профиль интеграция

### Управление кейсами
- CRUD операции для кейсов
- Настройка содержимого
- Управление шансами дропа
- Статистика открытий

### Управление предметами
- CRUD предметов
- Управление ценами
- Категоризация
- Steam API синхронизация

### Финансовая панель
- Статистика доходов/расходов
- Анализ популярности кейсов
- Отчеты по платежам
- RTP (Return to Player) аналитика

### Промокоды и бонусы
- Создание промокодов
- Настройка бонусных акций
- Статистика использования
- Реферальная система

### Настройки платформы
- Тексты и переводы
- Баннеры и изображения
- Социальные ссылки
- SEO настройки

### Live-мониторинг
- Активные пользователи
- Открытия в реальном времени
- Системные уведомления
- Логи ошибок

## Ключевые функции

### Steam интеграция
```php
// SteamService.php
class SteamService
{
    public function authenticate(string $steamId): User;
    public function getInventory(string $steamId): Collection;
    public function sendTradeOffer(User $user, array $items): bool;
    public function validateTradeUrl(string $tradeUrl): bool;
}
```

### Провably Fair система
```php
// ProvablyFairService.php
class ProvablyFairService
{
    public function generateServerSeed(): string;
    public function generateClientSeed(): string;
    public function calculateResult(string $serverSeed, string $clientSeed, int $nonce): float;
    public function verifyResult(array $data): bool;
}
```

### Генератор дропа
```php
// DropService.php
class DropService
{
    public function calculateDrop(Case $case, User $user): Item;
    public function applyAntiMinusSystem(User $user, float $dropValue): float;
    public function getDropProbabilities(Case $case): array;
}
```

## База данных

### Основные таблицы

#### users
```sql
- id
- steam_id (unique)
- username
- avatar
- email
- balance (decimal)
- trade_url
- level
- experience
- referrer_id
- is_banned
- last_activity
- created_at/updated_at
```

#### cases
```sql
- id
- name
- description
- image
- price (decimal)
- is_active
- sort_order
- min_value (decimal)
- max_value (decimal)
- created_at/updated_at
```

#### items
```sql
- id
- name
- description
- image
- price (decimal)
- rarity
- category
- steam_market_name
- is_active
- created_at/updated_at
```

#### case_items
```sql
- id
- case_id
- item_id
- chance (decimal 0-100)
- created_at/updated_at
```

#### openings
```sql
- id
- user_id
- case_id
- item_id
- server_seed
- client_seed
- nonce
- result_value (decimal)
- profit (decimal)
- created_at
```

#### payments
```sql
- id
- user_id
- type (deposit/withdrawal)
- method (qiwi/yoomoney/crypto/card)
- amount (decimal)
- status
- external_id
- created_at/updated_at
```

#### promocodes
```sql
- id
- code (unique)
- type (amount/percentage)
- value (decimal)
- uses_limit
- uses_count
- expires_at
- is_active
- created_at/updated_at
```

## DevOps

### Docker контейнеры
- **nginx**: Веб-сервер и прокси
- **php-fpm**: Laravel приложение
- **node**: WebSocket сервер
- **mysql/postgres**: База данных
- **redis**: Кеш и очереди
- **phpmyadmin**: Управление БД (dev)

### CI/CD Pipeline (GitHub Actions)
1. **Тестирование**: PHPUnit, Jest
2. **Линтинг**: PHP CS Fixer, ESLint
3. **Сборка**: Docker images
4. **Деплой**: SSH deploy на сервер
5. **Мониторинг**: Health checks

### Мониторинг и логирование
- **Логи**: Laravel Log channels
- **Мониторинг**: Laravel Horizon
- **Алерты**: Telegram уведомления
- **Метрики**: Custom dashboard

## Безопасность

### API защита
- Laravel Sanctum токены
- Rate limiting
- CORS настройки
- Валидация входных данных

### Антифрод система
- Обнаружение ботов
- Анализ паттернов игры
- IP блокировка
- Множественные аккаунты

### Платежная безопасность
- Webhook валидация
- 3D Secure поддержка
- Лимиты на операции
- Suspicious activity detection

## Производительность

### Кеширование
- Redis для сессий
- Cache API responses
- Static assets CDN
- Database query cache

### Оптимизация БД
- Индексы для частых запросов
- Connection pooling
- Query optimization
- Database sharding (при росте)

### Frontend оптимизация
- Code splitting
- Lazy loading
- Image optimization
- Bundle optimization

## Развертывание

### Системные требования
- **CPU**: 4 cores min
- **RAM**: 8GB min  
- **Storage**: 100GB+ SSD
- **Network**: 1Gbps
- **OS**: Ubuntu 22.04 LTS

### Рекомендуемая конфигурация сервера
```yaml
Web Server:
  - CPU: 8 cores
  - RAM: 16GB
  - Storage: 500GB SSD
  - Nginx + PHP-FPM

Database Server:
  - CPU: 4 cores  
  - RAM: 16GB
  - Storage: 1TB SSD
  - MySQL 8.0

Cache/Queue Server:
  - CPU: 2 cores
  - RAM: 8GB
  - Storage: 100GB SSD
  - Redis 7.0
```

### Backup стратегия
- Ежедневные бэкапы БД
- Еженедельные полные бэкапы
- Репликация на удаленный сервер
- Тестирование восстановления

## Масштабирование

### Горизонтальное масштабирование
- Load balancer (nginx/HAProxy)
- Несколько app серверов
- Database clustering
- CDN для статики

### Вертикальное масштабирование  
- Увеличение ресурсов сервера
- Database optimization
- Cache увеличение
- SSD storage upgrade

## Мониторинг KPI

### Бизнес метрики
- Количество активных пользователей
- Средний чек
- Retention rate
- RTP (Return to Player)
- Конверсия регистрация → первый депозит

### Технические метрики
- Response time API
- Database performance
- Error rate
- Uptime percentage
- WebSocket connections

## Интеграции

### Платежные системы
- **Qiwi**: REST API
- **ЮMoney**: Wallet API  
- **Crypto Bot**: Telegram Bot API
- **Банковские карты**: Stripe/Robokassa
- **Steam Market**: Community API

### Внешние сервисы
- **Steam OpenID**: Авторизация
- **Steam Web API**: Инвентарь, профили
- **Telegram Bot**: Уведомления, поддержка
- **Email service**: Transactional emails
- **SMS service**: 2FA (опционально)

## Планы развития

### Phase 1 (MVP)
- Базовая функциональность кейсов
- Steam авторизация
- Простые платежи
- Админка

### Phase 2 (Расширение)
- Реферальная система  
- Промокоды и бонусы
- Улучшенная админка
- Mobile app (PWA)

### Phase 3 (Масштабирование)
- Множественные языки
- Дополнительные игры
- API для партнеров
- Advanced аналитика

## Команда разработки

### Роли
- **Backend Developer**: Laravel, Node.js
- **Frontend Developer**: Vue.js/React
- **DevOps Engineer**: Docker, CI/CD
- **UI/UX Designer**: Интерфейсы
- **QA Engineer**: Тестирование

### Временные рамки
- **MVP**: 2-3 месяца
- **Full Version**: 4-6 месяцев  
- **Scaling**: 6+ месяцев

### Бюджет (примерный)
- Разработка: $30,000 - $50,000
- Инфраструктура: $500-2000/месяц
- Лицензии: $200-500/месяц
- Поддержка: $5,000-10,000/месяц
# 🚀 Case Platform - Быстрый деплой

Краткое руководство по развертыванию Case Platform на продакшен сервере.

## ⚡ Автоматическая установка (1 команда)

### На чистый Ubuntu/Debian сервер:

```bash
# Скачиваем и запускаем автоустановщик
wget https://raw.githubusercontent.com/your-repo/case-platform/main/scripts/install-production.sh
chmod +x install-production.sh
sudo bash install-production.sh
```

**Что потребуется ввести:**
- 📝 Доменное имя (example.com)
- 📧 Email для SSL сертификата  
- 🔑 Пароль для MySQL
- 🔑 Пароль для Redis
- 🔑 Steam API ключ
- 🔑 Telegram Bot Token (опционально)

## 📦 Деплой проекта из Git

После установки сервера:

```bash
# Деплой из вашего репозитория
sudo bash /var/www/case-platform/scripts/deploy-from-git.sh https://github.com/your-repo/case-platform.git main
```

## ✅ Проверка результата

```bash
# Проверка статуса всех сервисов
/var/www/case-platform/scripts/status.sh

# Или проверка в браузере
# https://yourdomain.com - Frontend
# https://yourdomain.com/admin - Админка  
# https://yourdomain.com/api/health - API
```

## 🛠️ Основные команды управления

```bash
# Статус
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

## 🔧 Настройка после установки

### 1. Создание администратора Voyager

```bash
cd /var/www/case-platform
sudo docker-compose -f docker-compose.prod.yml exec php php artisan voyager:admin admin@example.com --create
```

### 2. Настройка API ключей

Отредактируйте файлы конфигурации:

```bash
sudo nano /var/www/case-platform/backend/.env
sudo nano /var/www/case-platform/frontend/.env
sudo nano /var/www/case-platform/websocket/.env
```

### 3. Настройка DNS

Направьте домен на IP сервера:
- **A запись**: `yourdomain.com` → `YOUR_SERVER_IP`
- **A запись**: `www.yourdomain.com` → `YOUR_SERVER_IP`

## 🚨 Решение проблем

### Проблема: Контейнеры не запускаются

```bash
# Проверка логов
cd /var/www/case-platform
sudo docker-compose -f docker-compose.prod.yml logs

# Перезапуск Docker
sudo systemctl restart docker
sudo systemctl restart case-platform
```

### Проблема: SSL сертификат не получается

```bash
# Убедитесь что DNS настроен правильно
nslookup yourdomain.com

# Попробуйте получить сертификат вручную
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

### Проблема: База данных недоступна

```bash
# Проверка MySQL
cd /var/www/case-platform
sudo docker-compose -f docker-compose.prod.yml exec mysql mysql -u case_user -p

# Если не подключается - проверьте пароль в .env
grep DB_PASSWORD backend/.env
```

## 📊 Мониторинг

### Проверка работоспособности

```bash
# Здоровье сервисов
curl -f https://yourdomain.com/api/health
curl -f https://yourdomain.com:3001/health

# Статус контейнеров
sudo docker ps | grep case_platform

# Использование ресурсов
sudo docker stats --no-stream
```

### Логи

```bash
# Логи приложения
sudo tail -f /var/www/case-platform/backend/storage/logs/laravel.log

# Логи всех сервисов
cd /var/www/case-platform
sudo docker-compose -f docker-compose.prod.yml logs -f

# Системные логи
sudo journalctl -u case-platform -f
```

## 🔄 Обновление

```bash
# Автоматическое обновление из Git
sudo bash /var/www/case-platform/scripts/deploy-from-git.sh

# Или через скрипт обновления
sudo /var/www/case-platform/scripts/update.sh
```

## 💾 Бэкапы

```bash
# Создание бэкапа
sudo /var/www/case-platform/scripts/backup.sh

# Расположение бэкапов
ls -la /var/backups/case-platform/

# Автоматические бэкапы (настроены через cron)
sudo -u caseplatform crontab -l
```

## 📱 Доступ к сервисам

После успешной установки:

- **🌐 Frontend**: https://yourdomain.com
- **⚙️ Админка**: https://yourdomain.com/admin
- **🔗 API**: https://yourdomain.com/api
- **📊 Horizon**: https://yourdomain.com/horizon
- **💾 PhpMyAdmin**: http://yourdomain.com:8080 (только для dev)

## 🎯 Основные файлы

```
/var/www/case-platform/
├── backend/.env                    # Конфигурация Laravel
├── frontend/.env                   # Конфигурация Vue.js
├── websocket/.env                  # Конфигурация WebSocket
├── docker-compose.prod.yml         # Продакшен контейнеры
├── scripts/                        # Скрипты управления
│   ├── start.sh                   # Запуск
│   ├── stop.sh                    # Остановка
│   ├── status.sh                  # Статус
│   ├── update.sh                  # Обновление
│   └── backup.sh                  # Бэкап
└── logs/                          # Логи приложения
```

## 📞 Поддержка

Если возникли проблемы:

1. **Проверьте логи**: `sudo docker-compose -f docker-compose.prod.yml logs`
2. **Проверьте статус**: `/var/www/case-platform/scripts/status.sh`
3. **Документация**: [PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md)
4. **Issues**: https://github.com/your-repo/case-platform/issues

---

🎉 **Case Platform готов к работе!**

Платформа полностью готова к обслуживанию пользователей. Все сервисы автоматически перезапустятся при перезагрузке сервера.
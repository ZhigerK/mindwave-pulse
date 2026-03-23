#!/bin/bash

# Название корневой папки
PROJECT_NAME="mindwave-pulse"

echo "🚀 Создаем структуру монорепозитория для $PROJECT_NAME..."


# 1. Создаем структуру директорий
mkdir -p .github/workflows
mkdir -p docs
mkdir -p apps/web-student apps/web-parent apps/web-mentor
mkdir -p services/lms-content services/crm-task-engine services/billing-service services/notification-service
mkdir -p infrastructure/airflow/dags infrastructure/keycloak-theme
mkdir -p packages/shared-types packages/ui-kit

# 2. Создаем пустые файлы-заглушки (файлы конфигураций и доки)
touch .github/workflows/deploy-services.yml
touch .github/workflows/release-content.yml

# Заглушки для документации (сюда вы потом скопируете тексты наших документов)
touch docs/01_PRD_Core.md
touch docs/02_Architecture_Keycloak_Airflow.md
touch docs/03_Trigger_Matrix.md
touch docs/04_ERD_Data_Model.md

# Заглушки package.json для каждого приложения и сервиса (чтобы монорепа их увидела)
for dir in apps/* services/* packages/*; do
  echo '{ "name": "@mindwave-pulse/'$(basename $dir)'", "version": "1.0.0", "private": true }' > "$dir/package.json"
done

# 3. Создаем корневой package.json (настройка NPM Workspaces)
cat << 'EOF' > package.json
{
  "name": "mindwave-pulse-monorepo",
  "version": "1.0.0",
  "private": true,
  "workspaces": [
    "apps/*",
    "services/*",
    "packages/*"
  ],
  "scripts": {
    "docker:up": "docker-compose -f infrastructure/docker-compose.yml up -d",
    "docker:down": "docker-compose -f infrastructure/docker-compose.yml down"
  }
}
EOF

# 4. Создаем базовый docker-compose.yml (заглушка для баз данных и Keycloak)
cat << 'EOF' > infrastructure/docker-compose.yml
version: '3.8'
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: mindwave
      POSTGRES_PASSWORD: password
      POSTGRES_DB: mindwave_core
    ports:
      - "5432:5432"

  mongodb:
    image: mongo:6
    ports:
      - "27017:27017"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  # Keycloak, Airflow и RabbitMQ будут добавлены сюда позже
EOF

# 5. Создаем корневой README.md
cat << 'EOF' > README.md
# Mindwave Pulse 🌊⚡

Гибридная образовательная экосистема следующего поколения от создателей Mindwave.
Модель: Асинхронный версионируемый контент + Триггерное менторство + Абсолютная прозрачность.

## 📖 О проекте
Платформа спроектирована с нуля для работы в двух изолированных режимах:
1. **Adult Mode:** Самостоятельное обучение с фокусом на результат, предиктивное удержание и полную приватность.
2. **Child Mode:** Управляемое обучение с геймификацией и прозрачной аналитикой для родителей (Parent Dashboard).

## 📂 Документация
Вся архитектурная и продуктовая документация находится в директории `/docs`.

## 🚀 Локальный запуск (Docker)
Для запуска локального окружения со всеми базами данных:
```bash
npm install
npm run docker:up
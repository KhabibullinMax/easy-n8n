#!/bin/bash
set -e

# --- Настройки цветов ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Вспомогательные функции ---
print_step() {
    echo -e "\n${YELLOW}[${1}/${2}] ${3}${NC}"
}

generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
}

# --- Начало скрипта ---
clear
echo -e "${GREEN}=== n8n + Postgres + Portainer + NPM ===${NC}"

# Шаг 1/8: Сбор данных
print_step 1 8 "Ввод данных..."
read -p "Введите IP вашего сервера (например, 144.31.x.x): " VPS_IP
read -p "Введите ваш домен (например, site.com): " DOMAIN
CURRENT_USER="${SUDO_USER:-$USER}"

# Шаг 2/8: Генерация паролей
print_step 2 8 "Генерация паролей..."
PG_PASSWORD=$(generate_password)

# Шаг 3/8: Обновление системы
print_step 3 8 "Обновление системы..."
sudo apt update && sudo apt upgrade -y

# Шаг 4/8: Установка Docker
print_step 4 8 "Установка Docker..."
sudo apt remove -y docker.io docker-compose* || true
curl -fsSL https://get.docker.com | sh
sudo systemctl enable --now docker
sudo usermod -aG docker "$CURRENT_USER"

# Шаг 5/8: Подготовка папок и прав
print_step 5 8 "Создание папок..."
sudo mkdir -p /docker_volumes/{postgres_n8n,npm_data,npm_letsencrypt,n8n_data}
sudo chmod 777 /docker_volumes/postgres_n8n
sudo chmod 777 /docker_volumes/n8n_data
sudo mkdir -p /opt/{n8n,npm}
# Очистка конфликтов
sudo docker rm -f portainer 2>/dev/null || true
sudo docker volume create portainer_data || true

# Шаг 6/8: Portainer
print_step 6 8 "Запуск Portainer..."
sudo docker run -d --name portainer --restart=always \
  -p 8000:8000 -p 9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_/data portainer/portainer-ce:latest

# Шаг 7/8: Nginx Proxy Manager
print_step 7 8 "Запуск Nginx Proxy Manager..."
if [ -f /opt/npm/docker-compose.yml ]; then
    sudo docker compose -f /opt/npm/docker-compose.yml down 2>/dev/null || true
fi

cat > npm-compose.yml << EOF
version: "3.8"
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'
      - '443:443'
      - '81:81'
    environment:
      TZ: Europe/Moscow
    volumes:
      - /docker_volumes/npm_/data
      - /docker_volumes/npm_letsencrypt:/etc/letsencrypt
EOF
sudo mv npm-compose.yml /opt/npm/docker-compose.yml
sudo docker compose -f /opt/npm/docker-compose.yml up -d

# Шаг 8/8: n8n + Postgres
print_step 8 8 "Запуск n8n + Postgres..."
if [ -f /opt/n8n/docker-compose.yml ]; then
    sudo docker compose -f /opt/n8n/docker-compose.yml down 2>/dev/null || true
fi

cat > n8n-compose.yml << EOF
version: "3.8"
services:
  postgres:
    image: postgres:16
    container_name: postgres_n8n
    restart: unless-stopped
    environment:
      POSTGRES_USER: n8n
      POSTGRES_PASSWORD: ${PG_PASSWORD}
      POSTGRES_DB: n8n
    ports:
     - "127.0.0.1:5432:5432"
    volumes:
      - /docker_volumes/postgres_n8n:/var/lib/postgresql/data
    networks:
      - n8n_net

  n8n:
    image: docker.n8n.io/n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres_n8n
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=${PG_PASSWORD}
      - N8N_HOST=n8n.${DOMAIN}
      - WEBHOOK_URL=https://n8n.${DOMAIN}
      - N8N_SECURE_COOKIE=false
    volumes:
      - /docker_volumes/n8n_data:/home/node/.n8n
    depends_on:
      - postgres
    networks:
      - n8n_net

networks:
  n8n_net:
    driver: bridge
EOF
sudo mv n8n-compose.yml /opt/n8n/docker-compose.yml
sudo docker compose -f /opt/n8n/docker-compose.yml up -d

# --- Финальный вывод ---
clear
echo -e "${GREEN}🎉 УСТАНОВКА ЗАВЕРШЕНА!${NC}"
echo ""
echo -e "${YELLOW}⚠️ ВАЖНО: Portainer нужно активировать в течение 5 минут!${NC}"
echo -e "Если вы увидите 'Timed out', выполните: ${BLUE}docker restart portainer${NC}"
echo ""
echo -e "${YELLOW}🛠️ ИНСТРУКЦИЯ ПО НАСТРОЙКЕ:${NC}"
echo "1. Зайдите в NPM (http://${VPS_IP}:81) -> Proxy Hosts -> Add Proxy Host."
echo "2. Настройте домены:"
echo "   • ${DOMAIN} -> ${VPS_IP} : 5678 (http)"
echo "   • nginx.${DOMAIN}     -> ${VPS_IP} : 81   (http)"
echo "   • portainer.${DOMAIN} -> ${VPS_IP} : 9443 (scheme: https)"
echo "     (Для Portainer обязательно включите 'Websockets Support'!)"
echo "3. На вкладке SSL для всех хостов включите 'Force SSL' и получите сертификат."
echo ""
echo -e "${GREEN}🔗 ССЫЛКИ ДЛЯ ВХОДА:${NC}"
echo "══════════════════════════════════════════════════════════════════"
printf "${BLUE}%-15s | %-30s | %-20s${NC}\n" "СЕРВИС" "ВХОД ПО IP (Работает сразу)" "ВХОД ПО ДОМЕНУ (После NPM)"
echo "------------------------------------------------------------------"
printf "%-15s | http://%-23s | https://n8n.%s\n" "n8n" "${VPS_IP}:5678" "${DOMAIN}"
printf "%-15s | https://%-22s | https://portainer.%s\n" "Portainer" "${VPS_IP}:9443" "${DOMAIN}"
printf "%-15s | http://%-23s | https://nginx.%s\n" "NPM Admin" "${VPS_IP}:81" "${DOMAIN}"
echo "══════════════════════════════════════════════════════════════════"
echo ""
echo -e "${GREEN}🔑 УЧЕТНЫЕ ДАННЫЕ:${NC}"
echo "------------------------------------------------------------------"
echo -e "${BLUE}1. Nginx Proxy Manager:${NC}"
echo -e "   ${YELLOW}(Укажите Email и Password при первом входе!)${NC}"
echo ""
echo -e "${BLUE}2. Portainer:${NC}"
echo "   (Задайте пароль при первом открытии ссылки)"
echo ""
echo -e "${BLUE}3. Данные для Postgres ноды (внутри n8n):${NC}"
echo "   Host:     postgres_n8n"
echo "   Database: n8n"
echo "   User:     n8n"
echo "   Pass:     $PG_PASSWORD"
echo "------------------------------------------------------------------"
echo ""
echo -e "${BLUE}📢 Поддержка и обновления:${NC}"
echo "• Автор: https://t.me/maxkhabibullin"
echo "• Канал: https://t.me/not_with_a_knife"
echo ""
echo -e "${YELLOW}💡 Совет: Чтобы команды docker работали без sudo, введите:${NC}"
echo "newgrp docker"
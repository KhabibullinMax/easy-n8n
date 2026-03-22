# 🚀 n8n + Postgres + Portainer + NPM Auto-Installer

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)

Автоматический скрипт для развертывания мощного стека автоматизации на чистом VPS (Ubuntu/Debian).

Устанавливает и настраивает:
*   **n8n** (Workflow Automation) — с backend'ом на PostgreSQL (вместо SQLite).
*   **PostgreSQL** — база данных для n8n.
*   **Portainer CE** — удобный UI для управления Docker контейнерами.
*   **Nginx Proxy Manager (NPM)** — для управления доменами и SSL сертификатами.

## ✨ Особенности
*   ⚡ **Быстрая установка:** Весь стек поднимается за 2-3 минуты.
*   🔒 **Безопасность:** Portainer на HTTPS (порт 9443), отдельные сети Docker.
*   💾 **Постоянное хранение:** Все данные монтируются в `/docker_volumes`.
*   🛠 **Удобство:** Автоматическая генерация паролей для БД.

## 📋 Требования
*   Чистый сервер (VPS) с Ubuntu 20.04 / 22.04 / 24.04.
*   Наличие доменного имени и доступ к настройке A-записей в DNS. При отсутствии можно воспользоваться сервисом freedns
*   Права `root` или пользователя с `sudo`.

## 🚀 Быстрый старт
Зайдите на сервер по SSH и выполните команду:
wget -O install.sh https://raw.githubusercontent.com/KhabibullinMax/easy-n8n/main/install.sh && chmod +x install.sh && ./install.sh


Либо вручную:
1. Скачайте скрипт `install.sh`.
2. Дайте права: `chmod +x install.sh`.
3. Запустите: `./install.sh`.

## ⚙️ После установки (Важно!)

После завершения работы скрипта, вам нужно выполнить настройку в браузере:

### 1. Portainer (Срочно!)
🔴 **Внимание:** У вас есть **5 минут** после установки, чтобы создать админа в Portainer. Иначе он заблокируется (Security timeout).
*   Перейдите по ссылке: `https://your-domain:9443` (или `https://IP-ADDRESS:9443`)
*   Примите риск самоподписанного сертификата.
*   Создайте пользователя и пароль.

### 2. Nginx Proxy Manager (NPM)
*   Админка: `http://IP-ADDRESS:81`
*   Логин: `admin@example.com`
*   Пароль: `changeme` (смените при входе!)

В NPM создайте **Proxy Hosts** для ваших сервисов:

| Сервис | Domain Name | Forward Hostname / IP | Forward Port | Scheme | Опции |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **n8n** | `n8n.site.com` | IP вашего сервера | `5678` | `http` | Websockets Support |
| **Portainer** | `portainer.site.com` | IP вашего сервера | `9443` | `https` | Websockets Support |
| **NPM** | `nginx.site.com` | IP вашего сервера | `81` | `http` | Websockets Support |

*Не забудьте включить **Force SSL** и получить сертификат Let's Encrypt на вкладке SSL.*

---

## 📂 Структура папок
Все данные хранятся здесь:
*   `/docker_volumes/n8n_data` — Данные n8n
*   `/docker_volumes/postgres_n8n` — База данных
*   `/docker_volumes/npm_data` — Настройки NPM
*   `/opt/n8n` — Docker-compose файлы n8n
*   `/opt/npm` — Docker-compose файлы NPM

## 🤝 Связь с автором
*   **tg:** [Макс Хабибуллин](https://t.me/maxkhabibullin)

# Установка из репозитория

**Для данного метода установки также требуется Docker BuildX Plugin!**

Данная установка подразумевает самостоятельную сборку и загрузку образов Docker. 
**Для успешного завершения установки требуется доступ к репозиториям Docker, quay.io, Github, Hackage и PyPi!**

Скопируйте репозиторий проекта при помощи команды

```bash
git clone https://<адрес до репозитория>
```

Перейдите в новую директорию и создайте копию файла `docker-sample.env`:

```bash
cp docker-sample.env docker.env
```

В файле `docker.env` установите следующие параметры:

- `KC_HOSTNAME` - укажите будущую ссылку на Keycloak (например, `https://auth.mrtstg.local`)
- `FRONTEND_HOSTNAME` - укажите будущую ссылку на UI системы (например, `https://labforge.mrtstg.local`)
- `KC_BOOTSTRAP_ADMIN_USERNAME` и `KC_BOOTSTRAP_ADMIN_PASSWORD` - логин и пароль аккаунта администратора Keycloak
, который создается при запуске. После, может быть удален.
- `GRAFANA_ADMIN_PASSWORD` - пароль локального аккаунта Grafana `admin`

После замены параметров, потребуется изменить конфигурации под домены и
развернуть стартовый набор сервисов, в который входит база данных и Keycloak

```bash
make replace-nginx
make deploy-prod-minimal
```

В случае успешного запуска контейнеров, запустите генерацию ролей и данных клиентов:

```bash
make fill-keycloak
```

В случае успеха, будет создан файл `.clients.json`. Дальше, нужно вставить данные
в конфигурации каждого сервиса:

```bash
make fill-envs
```

Должны будут создасться следующие файлы:

- `auth.env`
- `cluster.env`
- `deployment.env`
- `frontend.env`
- `kroki.env`

Далее, запустите сборку образов: 

```bash
make build-lib-image && make build-images && make build-websockify
```

После, потребуется поместить сертификаты на указанные Вами ранее имена в директорию `deployment/nginx/ssl-prod`:

1. `labforge.crt`, `labforge.key` - сертификаты на CN домена интерфейса платформы (например, `labforge.mrtstg.local`)
2. `keycloak.crt`, `keycloak.key` - сертификаты на CN домена системы авторизации Keycloak (например, `auth.mrtstg.local`)


При отсутствии собственного CA, возможно сгенерировать самоподписанный CA при помощи системного openssl и выпустить
сертификаты для nginx:

```bash
make build-ca
```

Далее, потребуется собрать образ nginx:

```bash
make build-nginx-prod
```

И запустить все сервисы:

```bash
touch deployment/websockify/tokens.cfg
make deploy-prod
```

Проверьте доступы к выбранным доменам. Установка завершена, теперь требуется [настроить систему](./postinstall.md).

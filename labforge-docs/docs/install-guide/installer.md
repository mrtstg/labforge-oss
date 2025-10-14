# Установка при помощи установщика

Данный метод предполагает установку из готового установщика, который предоставляется с новыми
релизами проекта. Вы можете загрузить установщик в формате `.tar.gz` архива на [странице релизов проекта](https://gitverse.ru/mrtstg/labforge-oss).

Загрузите интересующую вас версию, создайте произвольную директорию на конечном сервере, на который ведется установка
и поместите туда установщик. Распакуйте его при помощи команды:

```bash
tar xzvf labforge.tar.gz
```

Загрузите образы в Docker:

```bash
make restore-images
```

После, можете зачистить директорию `images` для освобождения занятого места. Создайте копию файла `docker-sample.env`:

```bash
cp docker-sample.env docker.env
```

В файле `docker.env` установите следующие параметры:

- `KC_HOSTNAME` - укажите будущую ссылку на Keycloak (например, `https://auth.mrtstg.local`)
- `FRONTEND_HOSTNAME` - укажите будущую ссылку на UI системы (например, `https://labforge.mrtstg.local`). Также запишите домен без
протокола в поле `FRONTEND_DOMAIN` (например, `labforge.mrtstg.local`)
- `KC_BOOTSTRAP_ADMIN_USERNAME` и `KC_BOOTSTRAP_ADMIN_PASSWORD` - логин и пароль аккаунта администратора Keycloak
, который создается при запуске. После, может быть удален.
- `GRAFANA_ADMIN_PASSWORD` - пароль локального аккаунта Grafana `admin`
- `RABBITMQ_DEFAULT_PASS` - пароль от пользователя RabbitMQ

После замены параметров, потребуется изменить конфигурации под домены и
развернуть стартовый набор сервисов, в который входит база данных и Keycloak

```bash
make replace-nginx
make deploy-prod-minimal
```

По готовности сервиса, запустим процесс генерации системных ролей.

!!! info "Как определить готовность?"

    При запуске команды `docker ps` видны три контейнера, а при команде `docker logs --tail 100 keycloak` в выводе есть строчка
    "Running the server..."

```bash
make fill-keycloak
```

В случае успеха, будет создан файл `.clients.json`. Дальше, нужно вставить данные
в конфигурации каждого сервиса. **Для выполнения команды требуется наличие jq в системе!**

```bash
make fill-envs
```

В случае успеха на каждый ``*-sample.env`` файл (кроме docker-sample.env) должен создасться файл без постфикса `-sample`. После, 
потребуется поместить сертификаты на указанные Вами ранее имена в директорию `deployment/nginx/ssl-prod`:

1. `labforge.crt`, `labforge.key` - сертификаты на CN домена интерфейса платформы (например, `labforge.mrtstg.local`)
2. `keycloak.crt`, `keycloak.key` - сертификаты на CN домена системы авторизации Keycloak (например, `auth.mrtstg.local`)

При отсутствии собственного CA, возможно сгенерировать самоподписанный CA при помощи системного openssl и выпустить
сертификаты для nginx:

```bash
make build-ca
```

И запустить все сервисы:

```bash
touch deployment/websockify/tokens.cfg
make deploy-prod
make copy-nginx-prod
docker restart labforge-nginx
```

Проверьте доступы к выбранным доменам, открывается ли интерфейсс и активны ли все контейнеры. 
Установка завершена, теперь требуется [настроить систему](./postinstall.md).

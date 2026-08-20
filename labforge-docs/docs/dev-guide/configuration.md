# Конфигурация сервисов

Сервисы конфигурируются посредством переменных окружения. Также, при запуске сервисы пытаются загрузить файл `.env`, если он есть.

## Связь сервисов

Для связи между сервисами используются переменные вида `<NAME>_URL`, `<NAME>_IGNORE_SSL` и, в некоторых случаях, `<NAME>_TOKEN`.
Первая переменная отвечает за базовый URL сервиса, вторая — будет ли проверяться сертификат при HTTPS-соединении.

Помимо этого, каждый сервис конфигурируется через переменные `KEYCLOAK_CLIENT_ID`/`KEYCLOAK_CLIENT_SECRET` (клиент в Keycloak,
по которому сервис получает свой служебный токен) и `AUTH_URL`/`AUTH_IGNORE_SSL` (куда ходить для валидации токенов).

### Известные названия сервисов

| Наименование | Сервис | Комментарий |
|---|---|--|
|KEYCLOAK| Keycloak | Используется только auth-service|
|KROKI_SERVER|Kroki|Используется только kroki-proxy|
|AUTH | auth-service | Авторизация и валидация токенов|
|CLUSTER| cluster-manager | Управление нодами Proxmox|
|DEPLOYMENT|deployment-api|Развертывание и шаблоны|
|KROKI|kroki-proxy|Рендер диаграмм|
|JOBSERVICE|jobservice-api|Приём задач и управление задачами|
|REDIS|Redis|Кеш и распределённые блокировки|
|RABBITMQ|RabbitMQ|Очередь задач (используется jobservice/jobservice-api)|
|POSTGRES|PostgreSQL|База данных|

Сервисы, которые обращаются к другим сервисам, задают их URL через соответствующие переменные. Например, `frontend-server`
использует `AUTH_URL`, `CLUSTER_URL`, `DEPLOYMENT_URL`, `KROKI_URL`, `JOBSERVICE_URL`; `deployment-api` — `CLUSTER_URL`,
`JOBSERVICE_URL`, `AUTH_URL`; `jobservice` — `DEPLOYMENT_URL`, `CLUSTER_URL`, `JOBSERVICE_URL`, `AUTH_URL`.

`websockify-go` использует `PROXMOX_API_URL` и `PROXMOX_API_TOKEN` для создания временных VNC proxy. Для внутреннего CA можно
задать `PROXMOX_CA_FILE`; `PROXMOX_INSECURE_SKIP_VERIFY=true` явно отключает проверку сертификата и по умолчанию выключен.

## Пример конфигурации

Файлы `*-sample.env` в корне проекта содержат образцы конфигурации. Утилита `make fill-envs` создаёт из них рабочие файлы
(например, `auth.env`, `cluster.env`, `deployment.env`, `frontend.env`, `kroki.env`, `jobservice.env`, `jobservice-api.env`),
подставляя данные клиентов из `.clients.json` (генерируется опцией `make fill-keycloak`).

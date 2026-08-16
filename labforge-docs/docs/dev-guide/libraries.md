# Общие библиотеки

Общие компоненты вынесены в каталог `libraries/` и переиспользуются сервисами и CLI-утилитами.
Они собираются отдельно от сервисов (`make install-libs`, `make build-lib-image`).

## api-common

Библиотека общих API-определений. Содержит:

- **Схемы HTTP API** всех сервисов (`*/Schema.hs`): `AuthAPI`, `ClusterManagerAPI`, `DeploymentAPI`,
  `JobserviceAPI`, `RenderAPI` — используются и сервером, и клиентами.
- **Клиенты** (`*/Client.hs`) — типизированные обёртки над Servant client.
- **Модели данных** (`*/Models.hs`) — модели данных, используемые в Servant-схемах и клиентах
- **Общие утилиты**: `Api.hs` (тип `PagedResponse`, пагинация), `Api/Retry.hs`, `Api/Utils.hs`,
  `Api/BaseUrl.hs`, `Api/Redirect.hs`, `Models/JSONError.hs`.
- **Модули создания конфигурации сервисов**: `Service/Environment.hs` (тип `ServiceEnvironment`, переменные окружения),
  `Service/Config.hs`, `Service/Ssl.hs`.
- **Токены и авторизация**: `Auth/Token.hs`, `Auth/Client.hs`, `Auth/Schema.hs`. Данные модули содержат определение "общих" функций для
  валидации и получения токена, используемые другими сервисами при обращении к `auth-service`

## keycloak-api

Типизированный клиент Keycloak REST API (Admin REST и OpenID-connect):

- `Api/Keycloak.hs` — серверная часть/описания.
- `Api/Keycloak/Client.hs` — клиент к Keycloak (realm, клиенты, роли, группы, пользователи, токены).
- `Api/Keycloak/Models/` — модели: `User`, `Role`, `Group`, `Token`, `Introspect`, `Auth`.
- `Api/Keycloak/Token.hs` — получение и валидация служебных токенов.

Используется в первую очередь сервисом `auth-service`.

## proxmox-api

Клиент Proxmox VE REST API и модели данных:

- `Proxmox/Client.hs` — вызовы API: узлы, VM, сети, SDN, хранилища, снапшоты, версия.
- `Proxmox/Models/` — модели: `Node`, `VM`, `VMConfig`, `VMClone`, `Network`, `NetworkInterface`,
  `SDNZone`, `SDNNetwork`, `Storage`, `Snapshot`, `Task`, `Version`.
- `Proxmox/Retry.hs` — обёртки с повторными попытками запроса над клиентом.
- `Proxmox/Schema.hs` — Servant-схема Proxmox API.

## proxmox-deploy-toolkit

Логика планирования и исполнения развертывания, общая для `jobservice` и `proxmox-compose`:

- `Proxmox/Deploy/Models/Config*` — модели конфигурации развертывания: `DeployParams`, `ConfigTemplate`,
  `ConfigNetwork` (existing/sdn/bridge), `ConfigVM` (сети, диски, cloud-init), `DeployAgentConfig`.
- `Proxmox/Deploy/Models/Transaction.hs` - типы определения транзакции и ее состояния.
- `Proxmox/Deploy/Transaction.hs` — планирование транзакции: `planTransactionStages`,
  `planTransactionActions`, `executeTransaction`.
- `Proxmox/Deploy/Ssl.hs` — создание менеджера Proxmox с учётом `ignore_ssl`.

Подробнее о конфигурации — в [документации proxmox-compose](../proxmox-compose/index.md).

## redis-utils

Утилиты для работы с Redis:

- `Redis/Common.hs` — кеширование (`cacheValue`, `getValue`, `getOrCacheJsonValue`), типы `RedisConnection`.
- `Redis/Lock.hs` — распределённые блокировки: `redisNXLockWrapper`, `redisLockWrapper`,
  `redisRateLockWrapper` (для ограничения частоты запросов).
- `Redis/Environment.hs` — построение соединения из переменных окружения.

Используется для кеша, распределённых блокировок и ограничения частоты запросов (rate limiting) в сервисах.

# Справочник по API

Сервисы системы общаются между собой и с фронтендом по HTTP. Все внутренние API требуют аутентификации
по Bearer-токену: заголовок `Authorization: Bearer <token>` (обязательный заголовок `Authorization`).

Ниже приведено описание HTTP-эндпоинтов каждого сервиса. Описание основано на определениях схем в библиотеке
`libraries/api-common` (каталоги `*/Schema.hs`).

## Общие сущности

### PagedResponse

Многие эндпоинты возвращают постраничные списки. Тело ответа имеет вид:

```json
{
  "pageSize": 20,
  "total": 100,
  "objects": [ ... ]
}
```

Страницы передаются параметром запроса `?page=<номер>`, начиная с 1.

### Ошибки

При ошибке сервисы возвращают JSON вида:

```json
{
  "error": "имя ошибки",
  "message": "человекочитаемое описание",
  "context": null/object
}
```

## auth-service

Сервис авторизации — прокси к Keycloak. Реализует OAuth2-логин, валидацию токенов и управление
ролями/группами/пользователями. Схема — `AuthAPI` (`libraries/api-common/src/Auth/Schema.hs`).

| Метод | Путь | Описание |
|---|---|---|
| POST | `/api/auth` | Обмен токена (`GrantRequest` → `GrantResponse`). Используется для client-credentials авторизации сервисов |
| POST | `/api/auth/validate` | Валидация JWT-токена (`IntrospectResponse`). Требует роль `validate-users` |
| GET | `/api/auth/roles` | Список realm-ролей. Требует роль `role-read` |
| POST | `/api/auth/roles` | Создание роли (`RoleCreateRequest`). Требует роль `role-manage` |
| DELETE | `/api/auth/roles/{roleName}` | Удаление роли. Требует роль `role-manage` |
| GET | `/api/auth/capabilities` | Роли токена (realm roles) |
| GET | `/api/auth/login?redirectTo=` | Начало OAuth2-логина, редирект на Keycloak |
| GET | `/api/auth/logout` | Выход, очистка cookie и редирект на Keycloak logout |
| GET | `/api/auth/fail` | Страница ошибки логина |
| GET | `/api/auth/callback?code=&state=` | Callback OAuth2, выдаёт cookie `token` |
| GET | `/api/auth/groups?page=` | Список групп (страница). Требует роль `group-read` |
| GET | `/api/auth/groups/all` | Полный список групп. Требует роль `group-read` |
| GET | `/api/auth/group/{name}/members?page=` | Участники группы (страница). Требует роль `user-read` |
| GET | `/api/auth/group/{name}/members/all` | Все участники группы. Требует роль `user-read` |
| GET | `/api/auth/user/{id}/groups?page=` | Группы пользователя. Требует роль `user-read` |
| GET | `/api/auth/user/{id}/groups/all` | Все группы пользователя. Требует роль `user-read` |
| GET | `/api/auth/user/{id}` | Краткая информация о пользователе (`BriefUser`). Требует роль `user-read` |
| GET | `/api/auth/portal` | Редирект в консоль администрирования Keycloak |
| GET | `/api/auth/user/{id}/roles` | Realm-роли пользователя. Требует роль `role-read` |

## cluster-manager

Хранит данные о нодах Proxmox в базе данных и выбирает ноду для развертывания. Схема — `ClusterManagerAPI`
(`libraries/api-common/src/Cluster/Schema.hs`).

| Метод | Путь | Описание |
|---|---|---|
| GET | `/api/cluster/nodes?page=` | Список нод (страница, по 15). Требует роль `cluster-admin` |
| GET | `/api/cluster/nodes/{name}` | Информация о ноде по имени. Требует роль `cluster-admin` |
| POST | `/api/cluster/nodes` | Добавление ноды (`ClusterNode`). Требует роль `cluster-admin` |
| DELETE | `/api/cluster/nodes/{name}` | Удаление ноды. Требует роль `cluster-admin` |
| GET | `/api/cluster/deploy/node` | Выбор доступной ноды для развертывания (с учётом нагрузки и занятых VMID) |
| GET | `/api/cluster/websockify/config` | Устаревшая конфигурация `tokens.cfg`; сохранена для совместимости и новым gateway не используется. **Не требует токена** |

### ClusterNode (JSON)

```json
{
  "name": "pve-1",
  "apiUrl": "https://192.168.1.101:8006/api2/json",
  "ignoreSSL": true,
  "apiToken": "root@pam!token=...",
  "startVMID": 100,
  "agentUrl": "https://192.168.1.101:8000",
  "agentToken": "...",
  "displayNetwork": "0.0.0.0",
  "minDisplay": 100,
  "maxDisplay": 5000,
  "displayIP": "192.168.1.101",
  "excludedPorts": [8006, 8000]
}
```

## deployment-api

Центральный сервис развертывания: хранит шаблоны, экземпляры стендов, управляет аллокацией VMID/дисплеев/сетей
и отправляет задачи в `jobservice`. Схема — `DeploymentAPI` (`libraries/api-common/src/Deployment/Schema.hs`).

### Работа с образами (шаблонами VM)

| Метод | Путь | Описание |
|---|---|---|
| GET | `/api/deployment/templates?page=` | Список образов (`ConfigTemplate`). Требует `image-view` или `image-admin` |
| DELETE | `/api/deployment/templates/{id}` | Удаление образа. Требует `image-admin` |
| POST | `/api/deployment/templates` | Создание образа (`ConfigTemplate`). Требует `image-admin` |
| POST | `/api/deployment/templates/names/list` | Поиск образов по списку имён. Требует `image-view`/`image-admin` |

`ConfigTemplate` содержит поля `name` (название) и `id` (VMID шаблона в Proxmox).

### Работа с шаблонами развертывания

| Метод | Путь | Описание |
|---|---|---|
| GET | `/api/deployment/deployments?page=` | Список шаблонов развертывания. Требует `deployment-admin` или `deployment-create` |
| POST | `/api/deployment/deployments` | Создание шаблона (`DeploymentCreate`). Требует `deployment-admin`/`deployment-create` |
| GET | `/api/deployment/deployments/{id}` | Информация о шаблоне. Доступ владельцу/админу |
| DELETE | `/api/deployment/deployments/{id}` | Удаление шаблона. Только если нет незавершённых экземпляров |
| PATCH | `/api/deployment/deployments/{id}` | Обновление шаблона (`DeploymentCreate`) |
| GET | `/api/deployment/deployments/{id}/deploy/group?group=` | Развернуть стенды на группу |
| GET | `/api/deployment/deployments/{id}/destroy/group?group=&force=` | Уничтожить стенды группы (`force` — принудительно) |
| GET | `/api/deployment/deployments/{id}/snapshot/group?group=&snapname=&mask=&delete=&rollback=` | Групповой снапшот/откат/удаление снапшота |
| GET | `/api/deployment/deployments/{id}/power/group?group=&mask=&on=` | Вкл/выкл питания стендов группы |
| GET | `/api/deployment/deployments/{id}/hide?group=` | Скрыть/показать шаблон для группы |
| GET | `/api/deployment/deployments/{id}/instances?page=&group=` | Список экземпляров шаблона |
| GET | `/api/deployment/deployments/{id}/instances/stats?group=` | Статистика по состояниям экземпляров |
| GET | `/api/deployment/ownership/deployment/{userId}?page=` | Шаблоны, которыми владеет пользователь |

### Аллокация ресурсов

| Метод | Путь | Описание |
|---|---|---|
| GET | `/api/deployment/vmid/{node}/{instanceId}?amount=` | Выделить N VMID на ноде. Требует `deployment-alloc` |
| GET | `/api/deployment/display/{node}/{instanceId}?amount=` | Выделить N дисплеев на ноде. Требует `deployment-alloc` |
| GET | `/api/deployment/network/{node}/{instanceId}?amount=` | Выделить N имён сетей (SDN). Требует `deployment-alloc` |
| GET | `/api/deployment/vm/allocations/amount/undeployed` | Карта нод → число неразвернутых VM. Требует `cluster-admin` |

### Экземпляры стендов

| Метод | Путь | Описание |
|---|---|---|
| GET | `/api/deployment/instances/my?page=` | Мои экземпляры |
| GET | `/api/deployment/instances/{id}` | Информация об экземпляре (`DeploymentInstance`) |
| GET | `/api/deployment/instances/{id}/power?on=` | Изменить питание стенда |
| GET | `/api/deployment/instances/{id}/destroy` | Уничтожить экземпляр |
| GET | `/api/deployment/instances/{id}/snapshot?snapname=&mask=&delete=&rollback=` | Снапшот/откат/удаление для экземпляра |
| PATCH | `/api/deployment/instances/{id}` | Частичное обновление (`DeploymentPatch`). Требует `deployment-instance-admin` |
| DELETE | `/api/deployment/instances/{id}` | Удалить запись экземпляра |
| POST | `/api/deployment/instances/{id}/log` | Добавить строку в лог развертывания экземпляра |

### Операции над VM по порту

Порт — это ключ вида `имя_ноды-N` (например, `pve-1-105`). Эти эндпоинты используются фронтендом
и websockify.

| Метод | Путь | Описание |
|---|---|---|
| GET | `/api/deployment/vm/{port}/power` | Текущее состояние питания |
| GET | `/api/deployment/vm/{port}/power/switch` | Переключить питание (с защитой от частых запросов) |
| GET | `/api/deployment/vm/{port}/networks` | Карта MAC-адрес → название сети |
| GET | `/api/deployment/vmport/access` | Проверка доступа к VNC-порту (заголовок `X-VM-PORT`) |
| GET | `/api/deployment/vm/{port}/snapshot/policy` | Политика снапшотов |
| GET | `/api/deployment/vm/{port}/snapshot?name=` | Создать снапшот |
| DELETE | `/api/deployment/vm/{port}/snapshot?name=` | Удалить снапшот |
| GET | `/api/deployment/vm/{port}/snapshot/list` | Список снапшотов |
| GET | `/api/deployment/vm/{port}/snapshot/rollback?name=` | Откат до снапшота |

### DeploymentCreate / DeploymentSnapshotPolicy (JSON)

```json
{
  "title": "Название",
  "vms": [ ...ConfigVM... ],
  "availableVMs": ["vm1"],
  "networks": [ ...ConfigNetwork... ],
  "snapshot": { "quota": 3, "deleteOwned": true, "useAny": false, "deleteAny": false }
}
```

Политика снапшотов: `quota` — лимит пользовательских снапшотов на VM, `deleteOwned` — удаление своих,
`useAny` — использование всех снапшотов (включая созданные администратором), `deleteAny` — удаление любых.

## jobservice-api

Приём задач в очередь RabbitMQ и управление задачами. Схема — `JobserviceAPI`
(`libraries/api-common/src/Jobservice/Schema.hs`).

| Метод | Путь | Описание |
|---|---|---|
| POST | `/api/jobservice/message` | Отправка задачи (`JobserviceTask`). Требует роль `jobservice-send` |
| GET | `/api/jobservice/images/held` | Список образов, занятых развертываниями. Требует `image-view`/`image-admin` |
| GET | `/api/jobservice/image/{name}/usage` | Использование образа (по каким развертываниям). Требует `image-view`/`image-admin` |
| GET | `/api/jobservice/deployment/{id}/lock/{type}` | Проверка блокировки развертывания (`any`/`generic`/`snapshot`/`power`) |
| DELETE | `/api/jobservice/task/{id}` | Досрочно закрыть задачу |
| GET | `/api/jobservice/task/{id}/{status}` | Проверить, достигла ли задача статуса |
| POST | `/api/jobservice/task/{id}/{status}` | Установить статус задачи |
| GET | `/api/jobservice/task/{id}` | Информация о задаче (`JobserviceTaskData`) |
| GET | `/api/jobservice/task?page=` | Список задач (страница) |
| DELETE | `/api/jobservice/task/group/{groupId}` | Удалить группу задач |

### JobserviceTask (JSON)

```json
{
  "key": "конфликтный_ключ (опц.)",
  "meta": {
    "deployment": "id экземпляра",
    "template": 5,
    "group": "группа (опц.)",
    "user": "целевой пользователь (опц.)",
    "author": "автор (опц.)"
  },
  "data": {
    "type": "deployInstance | destroyInstance | snapshotInstance | rollbackInstance | powerInstance | allocateNode | updateImages",
    ...поля в зависимости от типа...
  }
}
```

Типы задач:
- `deployInstance` — развернуть стенд
- `destroyInstance` — уничтожить стенд
- `snapshotInstance` — создать снапшот (`snapshot`, `delete`, `mask`, `comment`)
- `rollbackInstance` — откат (`snapshot`, `mask`)
- `powerInstance` — питание (`power`, `mask`)
- `allocateNode` — выбор ноды
- `updateImages` — пересчёт использования образов

Задача с конфликтным ключом не будет принята, пока существует другая задача с тем же ключом (ошибка `429`).

## kroki-proxy

Прокси для отрисовки диаграмм Kroki (топологии стендов). Схема — `RenderAPI`
(`libraries/api-common/src/Kroki/Schema.hs`).

| Метод | Путь | Описание |
|---|---|---|
| GET | `/api/render/instance/{instanceKey}` | SVG-топология экземпляра стенда. Требует токен и доступ к данным стенда от автора запроса |

## frontend-server

Отдаёт HTML-страницы пользовательского интерфейса. Помимо статики (`/static/*`), реализует HTML-маршруты
(`PagesAPI` в `frontend-server/src/Api/Pages.hs`):

| Путь | Описание |
|---|---|
| `/` | Главная страница (список доступных стендов) |
| `/notfound`, `/internalerror`, `/norights` | Страницы ошибок |
| `/instance/{id}` | Страница стенда (топология, таблица подключений) |
| `/instance/{id}/schema` | Схема стенда |
| `/instance/{id}/delete` | Удаление стенда |
| `/vnc/{port}` и `/vnc/{port}/full` | Страница VNC-подключения |
| `/deployment/create` | Создание шаблона развертывания |
| `/deployment/my?page=` | Список шаблонов |
| `/deployment/{id}/edit` | Редактирование шаблона |
| `/deployment/{id}/instances` | Экземпляры шаблона |
| `/image/my?page=`, `/image/create`, `/image/{id}/delete` | Управление образами |
| `/tasks?page=`, `/tasks/{id}/cancel`, `/tasks/group/{id}/cancel` | Просмотр и отмена задач |

## websockify-go

Проксирует VNC-трафик по WebSocket через Proxmox `vncproxy`. Не имеет публичного REST API: принимает WebSocket-соединения
на пути вида `/api/vm/{node-vmid}/vnc?token={node-vmid}`, которые nginx проверяет через
`/api/deployment/vmport/access`. Для каждого подключения сервис создаёт новый временный proxy и подключается к Proxmox
`vncwebsocket`; API credentials и VNC ticket клиенту не передаются.

## proxmox-fs-agent

Агент на гипервизоре, корректирует параметры VM, закрытые для API Proxmox (поле `args`, VNC-дисплей).
Реализует один эндпоинт:

| Метод | Путь | Описание |
|---|---|---|
| POST | `/args/vnc/{vmid}` | Установка VNC-дисплея для VM. Тело: `{"display": <число>, "network": "<сеть>"}`. Требует Bearer-токен агента (`PROXMOX_AGENT_ACCESS_TOKEN`) |

# jobservice: конвейер развертывания

`jobservice` — фоновый воркер, который выполняет операции над виртуальными машинами и стендами.
Задачи он получает из очереди RabbitMQ, публикуемой сервисом `jobservice-api`. Логика развертывания
вынесена в общую библиотеку `proxmox-deploy-toolkit` и переиспользуется также CLI-утилитой `proxmox-compose`.

## Поток задач

1. `jobservice-api` принимает задачу по HTTP и публикует её в обмен `jobserviceExchange` (очередь `jobserviceQueue`),
   предварительно сохранив запись задачи в базе данных.
2. `jobservice` потребляет сообщения из очереди и декодирует их в `JobserviceTask`.
3. В зависимости от типа задачи выполняется соответствующий обработчик.
4. Задачи исполняются с учётом блокировок, лимитов и возможности отмены.

## Обрабатываемые типы задач

| Тип | Обработчик | Назначение |
|---|---|---|
| `updateImages` | `cacheUsedImages` | Пересчёт использования образов (какие шаблоны VM заняты стендами) |
| `allocateNode` | `allocateNode` | Выбор ноды для развертывания и подготовка `DeployConfig` |
| `deployInstance` | `deployInstance` | Развертывание стенда (клонирование VM, сети, запуск) |
| `destroyInstance` | `destroyInstance` | Уничтожение стенда |
| `powerInstance` | `jobservicePower` | Включение/выключение VM по маске действия |
| `snapshotInstance` | `jobserviceSnapshot` | Создание снапшота |
| `rollbackInstance` | `jobserviceRollback` | Откат до снапшота |

## Блокировки и ограничения

### Ограничение параллельных развертываний

Переменная `CONCURRENT_DEPLOYMENTS` (по умолчанию 2) задаёт максимальное число одновременно развертываемых/уничтожаемых
стендов. Если лимит достигнут, сообщение возвращается в очередь с задержкой (`recreateMessageWithDelay`). Также применяется
случайная задержка перед началом развертывания, чтобы разнести пиковые нагрузки.

### Redis-блокировки

Для операций над конкретным стендом используются распределённые блокировки на основе Redis (`redisNXLockWrapper`):

- `deployment_action_<id>` — блокировка развертывания/уничтожения (срок жизни 600 секунд)
- `deployment_snapshot_<id>` — блокировка операций со снапшотами
- `deployment_power_task_<id>` — блокировка переключения питания
- `allocate_node_lock` — глобальная блокировка выбора ноды
- `global_vmid_lock`, `global_display_lock`, `global_network_lock` — блокировки аллокации ресурсов в `deployment-api`

Если блокировка занята, операция пропускается (а при `resendTask=True` сообщение возвращается в очередь).

### Отмена задач

Задача, имеющая ключ, исполняется в гонке с проверкой её статуса через `jobservice-api`. Перед выполнением статус
устанавливается в `running`. Если задача была отменена (`cancelled`), она не исполняется и удаляется из базы. Так
реализуется остановка долгих операций и групп задач.

## Планирование транзакции

Перед выполнением `deployInstance`/`destroyInstance` строится транзакция действий (`planTransactionStages` +
`planTransactionActions` в `proxmox-deploy-toolkit`):

1. Собираются данные Proxmox: мосты ноды, SDN-зоны и сети, хранилища, карта VM ноды.
2. Для каждого элемента конфигурации определяется стадия (`NetworkExists`, `VMExists`, `TemplateExists`,
   `VMStopped`, `SnapshotExists` и.т.д) и планируются необходимые действия.
3. Итоговый список действий (`TransactionAction`) исполняется по порядку: создание SDN-сетей, клонирование VM,
   назначение VMID, конфигурация cloud-init, подключение сетей,
   запуск VM и применение сетей (`ApplySDNNetworks`).

Доступные действия транзакции: `DeploySDNNetwork`, `DestroySDNNetwork`, `UnassignVMID`, `AssignVMID`, `CloneVM`,
`ConfigureVM`, `ConfigureVMRaw`, `SetVMDisplay`, `CreateVM`, `DestroyVM`, `StopVM`, `StartVM`, `RemoveNetworks`,
`AttachNetwork`, `DetachNetwork`, `MakeSnapshot`, `DeleteSnapshot`, `RollbackVM`, `ApplySDNNetworks`, `AllocateDisk`,
`CreateBridge`, `DestroyBridge`, `UpdateNodeNetworks`.

## Смена состояний стенда

Жизненный цикл стенда (`DeploymentInstance`) проходит состояния: `created` → `deploying` → `deployed`,
затем `destroying` для удаления; при ошибке — `failed`. Статусы учитываются в статистике развертываний
и при фильтрации в интерфейсе.

## Конфигурация

| Переменная | Назначение |
|---|---|
| `DEPLOY_SDN_ZONE` | SDN-зона, в которой создаются сети для стендов (обязательная) |
| `THREADS_AMOUNT` | Количество потоков-воркеров (по умолчанию 4) |
| `CONCURRENT_DEPLOYMENTS` | Максимум параллельных развертываний (по умолчанию 2) |
| `RABBITMQ_HOST/PORT/USER/PASS` | Подключение к RabbitMQ |
| `REDIS_HOST/PORT` | Подключение к Redis |
| `AUTH_URL`, `DEPLOYMENT_URL`, `JOBSERVICE_URL`, `CLUSTER_URL` | URL связанных сервисов |
| `KEYCLOAK_CLIENT_ID/SECRET` | Служебный клиент для получения токена |

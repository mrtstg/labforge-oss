# Пост-установочные действия

## Создание администратора

После завершения установки нет доступных пользователей для управления системой. Вы можете создать
пользователя-администратора при помощи команды

```bash
make create-admin
```

После, воспользуйтесь УЗ `labforge_admin`:`P@ssw0rd` (пароль на первый вход)

## Самостоятельное создание пользователей

Вы можете зайти по данным из `docker.env` (поля `KC_BOOTSTRAP_ADMIN_USERNAME` и `KC_BOOTSTRAP_ADMIN_PASSWORD`). Далее, воспользуйтесь
[руководством по созданию локальных пользователей](../keycloak/local-users.md).

Также не забудьте создать [группы пользователей](../keycloak/creating-groups.md), на них распространяются развертывания стендов.

## Создайте SDN-зону

Создайте SDN-зону, которую указали в процессе установки или зону `default`, если ничего не меняли. Проверена работа `simple` и `vxlan` зон.

## Добавление серверов в базу данных

Для использования сервера в развертывании также нужно добавить информацию и доступы к нему в БД сервиса `cluster-manager`. Для этого используется следующая
команда

```bash
docker exec -it labforge-cluster ./haskell-binary <аргументы>
```

Для простоты можете завести alias, например:

```bash
alias lnmgr="docker exec -it labforge-cluster ./haskell-binary"
```

### Создание сервера

!!! note "На какое имя создать токен?"

    На текущий момент рекомендуем токен на пользователя root с выключенным разделением прав.

Для создания сервера используется команда `create-node` со следующими аргументами:

```
--name <...> - имя сервера в PVE
--api-url <ссылка на PVE API, включая api2/json. Например, https://192.168.1.101:8006/api2/json> - ссылка на API Proxmox
--ignore-ssl - опциональный флаг, отключение проверок сертификата от API PVE и файлового агента
--token - токен доступа PVE, в формате соединенного через равно Token ID и Token secret. Например, root@pam!token=f0c55f32-20a6-40b5-9e13-a014e5dc6353 
--start-vmid <число от 100> - начальный VMID, который будет использоваться для развертывания 
```

!!! warning "Что будет при несовпадении имен в Proxmox и базе данных?"

    Из-за несовпадения имен алгоритм ротации серверов не сможет найти сервер, а развертывание завершится с ошибкой.

После добавления, вы можете проверить доступ к ноде:

```
docker exec -it labforge-cluster ./haskell-binary check --node <имя сервера в PVE>
```

### Пример команд

```bash
~ ➤ lnmgr create-node --name example --api-url https://192.168.1.101:8006/api2/json --ignore-ssl --token 'root@pam!token=0636f001-07d4-4423-a8c9-8c58261c747a' --start-vmid 100
Node created!
~ ➤ lnmgr check --node example
Successful response!
~ ➤ lnmgr delete --node example
```

## Настройка VNC gateway

VNC gateway подключается к Proxmox API напрямую. Укажите в `docker.env` адрес API и полный API-token:

```env
PROXMOX_API_URL=https://proxmox.example:8006
PROXMOX_API_TOKEN=PVEAPIToken=user@pve!gateway=secret
PROXMOX_CA_FILE=/path/to/internal-ca.pem
PROXMOX_INSECURE_SKIP_VERIFY=false
```

`PROXMOX_CA_FILE` можно не задавать для сертификата от системно доверенного CA. Отключение проверки сертификата через
`PROXMOX_INSECURE_SKIP_VERIFY=true` предназначено только для явно доверенной тестовой или закрытой сети.

После замены параметров выполните команду `make deploy-prod`

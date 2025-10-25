# proxmox-compose: основы использования

proxmox-compose - CLI-утилита для использования тулкита развертываия, разработанного в рамках данного проекта.
proxmox-compose использует произвольный конфигурационный YAML-файл. По умолчанию программа ищет файлы в рабочем каталоге:

- proxmox-compose.yaml
- proxmox-compose.yml

Любые другие файлы можно указать при помощи флага, об этом далее. **После использования конфигурационного файла
для развертывания, его не стоит переименовывать. Файл состояний в директории файла привязывается к имени файла.**

# Структура конфигурационного файла

Конфигурационный файл из нескольких секций:

- deploy - настройка параметров развертывания Proxmox - адрес, имя ноды, токен и.т.д
- agent - **полностью опциональная** область. Если на вашей ноде установлен [файловый агент](../install-guide/postinstall.md), вы можете его использовать для установки
статичных дисплеев
- templates - определения шаблонов виртуальных машин
- vms - определение создаваемых виртуальных машин. **На текущий момент поддерживается только клонирование машин из шаблона.**
- networks - определния сетей. **На текущий момент поддерживается использование существующих bridge-интерфейсов и SDN-сетей**

## Секция "deploy"

Пример заполнения:

```yaml
deploy:
  url: https://192.168.1.100:8006/api2/json
  token: "root@pam!token=974a0d9d-edb7-42a7-8488-f23a5d9d3408"
  node: pve-1
  ignore_ssl: true
  start_vmid: 5000
```

Секция включает в себя пять полей:

| Поле | Тип | Значение |
|------|-----|----------|
| url | Строка | URL на API Proxmox, вплоть до /api2/json |
| token | Строка | Access Token Proxmox в формате соединенного через равно Token ID и Token secret. Может быть неопределен и далее передан через флаг. |
| node | Строка | Имя целевой ноды в Proxmox, на которую ведется развертывание |
| ignore_ssl | Boolean | Включить/выключить игнорирование сертификата Proxmox и файловых агентов, если используется. По умолчанию false (проверка выполняется) |
| start_vmid | Число | Начальный номер VMID при динамическом выделении (если не указан явно) |


## Секция "agent"

Пример заполнения:

```yaml
agent:
  url: https://192.168.1.100:3000
  token: MEGASECRETTOKEN
  display_network: 0.0.0.0
```

Секция включает в себя три поля:

| Поле | Тип | Значение |
|------|-----|----------|
| url | Строка | URL на API файлового агента |
| token | Строка | Токен доступа к файловому агенту |
| display_network | Строка | Сеть, в которую будет направлен VNC дисплей. **Опционален, по умолчанию 0.0.0.0** |


## Секция "templates"

Секция представляет собой массив элементов из следующих ключей:


| Поле | Тип | Значение |
|------|-----|----------|
| name | Строка | Имя шаблона. Используется далее для указанния источника клонирования. Может отличаться от названия в Proxmox |
| id | Число | VMID шаблона в Proxmox |

Пример заполнения:

```yaml
templates:
  - name: debian-template
    id: 10001
  - name: redos-template
    id: 10002
```

## Секция "networks"

Секция представляет из себя массив элементов, которые определяют разные сущности. 

### Существующий bridge-интерфейс

Примеры заполнения:

```yaml
networks:
  - name: existing-network
  - type: existing
    name: exists-too
```

Для существующего `bridge` интерфейса требуется только указать его название и (опционально) тип `existing`.

### SDN-сеть

Пример заполнения:

```yaml
networks:
  - type: sdn
    zone: yourzone
    name: netname
    vlanaware: false
```

Для указания SDN-сети требуется указать параметр `type: sdn`, а также следующие параметры:


| Поле | Тип | Значение |
|------|-----|----------|
| zone | Строка | SDN-зона, в рамках которой создается сеть. Гарантированно поддерживаются simple и vxlan зоны на текущий момент. |
| name | Строка | Имя SDN-сети. Ограничено требованиями Proxmox |
| vlanaware | Boolean | Включение vlan-aware флага на интерфейсе. **Опционален, по умолчанию, false** |


## Секция "vms"

Для создания VM из шаблона требуется указать два параметра:

- `name` - имя виртуальной машины
- `clone_from` - имя шаблона из секции `templates`

Например:

```yaml
templates:
  - name: debian-template
    id: 10001

vms:
  - clone_from: debian-template
    name: test-vm
```

### Общие параметры (необязательные)

#### VMID

Указывает статический VMID для виртуальной машины в поле `vmid`, без кавычек. Если параметр не указан, присвоится динамический VMID

```yaml
vms:
  - clone_from: debian-template
    name: test-vm
    vmid: 105
```

#### Задержка после включения

Поле `delay` хранит в себе задержку после выключения виртуальной машины до следующего развертывания

```yaml
vms:
  - clone_from: debian-template
    name: test-vm
    delay: 10
```
#### Подключение сетей

Поключение сетей производится через поле `networks`, которое содержит в себе поле объектов сетей

```yaml
vms:
  - name: client
    networks:
      - number: 0
        model: e1000e
        name: test
```

##### Объект сети


| Название | Тип | Обязательный | Описание |
|-|-|-|-|
| name | Строка | Да | Имя сети, куда ведется подключение |
| number | Число | Нет | Номер сетевого устройства (от 0 до 31) |
| firewall | Boolean | Нет | Сеть использует Firewall Proxmox (по умочанию, true) |
| tag | Число | Нет | Числовой тег интерфейса |
| type | Строка, в определенном формате | Нет | Тип сетевого устройства. По умолчанию, virtio. Может иметь значение: `e1000`, `e1000-82540em`, `e1000-82544gc`, `e1000-82545em`, `e1000e`, `i82551`, `i82557b`, `i82559er`, `ne2k_isa`, `ne2k_pci`, `pcnet`, `rtl8139`, `virtio`, `vmxnet3` |
| cloudinit_address | Строка | Нет | Адрес (через cloudinit), если шаблон его поддерживает и у интерфейса указан номер. Может быть указан как `dhcp` в случае DHCP и `X.X.X.X/X` в случае конкретного адреса. |
| cloudinit_gateway | Строка | Нет | Шлюз (через cloudinit), если шаблон его поддерживает и у интерфейса указан номер. Если адрес интерфейса указан `dhcp`, то значение поля игнорируется и шлюз запрашивается по DHCP в любом случае. Иначе, требуется адрес с десятичной маской в формате `X.X.X.X/X` |


##### Быстрое создание сетей

Для того, чтобы быстро создать `virtio`-интерфейс со стандартными настройками можете указать только строку-наименование сети, например:

```yaml
vms:
  - name: client
    networks:
      - number: 0
        model: e1000e
        name: test
      - test2
      - test3
```

#### Очистка сетей

Если ваш шаблон содержит сетевые интерфейсы и вы не хотите их использовать в планируемой виртуальной машине, используйте поле
`clean_networks`. По умолчанию при клонировании сетевые интерфейсы не очищаются.

```yaml
vms:
  - clone_from: debian-template
    name: test-vm
    clean_networks: true
```

#### Запускать VM под конец клонирования

По умолчанию, VM после завершения работ включаются. Используйте поле `running: false` для того, чтобы изменить данное поведение.

```yaml
vms:
  - clone_from: debian-template
    name: test-vm
    running: false
```

#### Хранилище VM

Для linked-клонирования на то же хранилище, где и находится шаблон - не указывайте ничего. Для Full Copy на отдельное хранилище передайте поле
`storage` с именем целевого хранилища из proxmox, например:

```yaml
vms:
  - clone_from: debian-template
    name: test-vm
    storage: nfs
```

#### Дисплей VM

**Работает, только если указаны данные файлового агента!** Для указания статического VNC-порта, передайте число от 1 до требуемого порта в поле
`display`.

```yaml
vms:
  - clone_from: debian-template
    name: test-vm
    display: 15
```

#### CPU/память/CPU limit

По умолчанию, клонируются параметры шаблона, которые можно далее настроить:

- Количество ядер: поле `cores`, целое число
- Лимит CPU: поле `cpu_limit`, дробное число
- Память: поле `memory`, целое число в МБ

```yaml
vms:
  - clone_from: debian-template
    name: test-vm
    cores: 4
    memory: 2048
    cpu_limit: 2.5
```

#### Теги

Для присвоения тегов используется поле-список `tags`. Теги не могут содержать кириллицу и ряд специальных символов,
поэтому они автоматически транслитерируются.

```yaml
vms:
  - clone_from: debian-template
    name: test-vm
    tags:
     - Debian
     - Тег для транслитерации
```

#### cloudinit-параметры

Для поддерживающих cloudinit шаблонов доступны следующие поля. Если поле не указано, то оно либо не будет указано, либо будет использовано из
шаблона, если оно там указано.

- `cloudinit_user` - логин пользователя для создания
- `cloudinit_password` - пароль нового пользователя
- `cloudinit_dns` - DNS-сервер
- `cloudinit_domain` - поисковый домен
- `cloudinit_sshkeys` - публичные SSH-ключи через `\n` (newline) для доверия от лица нового пользователя
- `cloudinit_upgrade` - обновлять ли пакеты после запуска. Boolean-поле

```yaml
vms:
  - clone_from: debian-template
    name: test-vm
    cloudinit_user: user
    cloudinit_password: P@ssw0rd
    cloudinit_dns: 8.8.8.8
    cloudinit_domain: local.localdomain
    cloudinit_sshkeys: |
      ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCvVtBWqn8ya8jM4yy/WH6uNjSTU4tazZJBLqpbjUhwn+rPN6nVJlPksmpRigP+oNJKMIk6MInbzllSRr1HAb+YOPx6uc4WK7a2ZvtjsOxou16O/E86HoKY5NxEnd053p4M0DvGrKuCVR9rXYbfjurCL8TpG5hgFOhlUTBmjiZ6uoJkYWt3r+8rrTh5j3vGAtvX5zomE2V+3K9v/LUVEKCbZ9pgaxhuYXXuElOLRtAcntwoUeceYjttalgGIkzyLXMbK1rafOaAtuQXsnkQglmBCq60EX8+asxUX4kMZyYeUooPf7On/XdQYMdVPlmvU5LxulSCc/0DJcvO8booHbz9nZp6EwDT4b/LlEqaTEPkmcAJ1UOJ0Xbc4STc9IYhrqsdlFVCSWIRzBRiKNchQovwL1syS6pT9GY+N8VQfZl0x24qLkbUEdf1dg/6LWNA0du8lKYsnXwIsVgO+zgz4UjzVHH0E7jzysoR+IVw4RQRcYPMSG73U1M4x9wyC69WSOU= ilya@ilya
    cloudinit_upgrade: true
```

#### Добавление дисков

Документация в процессе написания.

# Вызов команды

Утилита статически слинкована, поэтому для запуска можно поместить исполняемый файл в любую PATH-директорию или просто вызвать 
с указанием пути.

## Общие флаги

### Указание файла конфигурации

В случае использования нестандартного наименования файла, при помощи `-f` можно передать произвольный путь.

```bash
./proxmox-compose -f config.yaml <...>
```

### Передача токена

В случае, если в файле конфигурации не передан API-токен при помощи флага `-t` можно передать его значение.

```bash
./proxmox-compose -f config.yaml -t root@api!token=123
```

### Вербозность вывода

Добавить подробность вывода можно при помощи флага `-v`.

## Команды

После передачи нужных флагов требуется добавить `up/down` для развертывания/свертывания соответственно. Если после вычисления, действия
не нужны, вы увидите примерный вывод (*самое важное в конце вывода*):

```bash
./proxmox-compose down
2025-10-25 18:10:45 MSK INFO ProxmoxCompose.Main: Started logging!
2025-10-25 18:10:45 MSK INFO ProxmoxCompose.Main: Found proxmox v8.2.2
2025-10-25 18:10:45 MSK INFO ProxmoxCompose.Main: Retrieving node virtual machines info...
2025-10-25 18:10:45 MSK INFO ProxmoxCompose.Main: Getting node bridges...
2025-10-25 18:10:46 MSK INFO ProxmoxCompose.Main: Getting target node storages...
2025-10-25 18:10:46 MSK INFO ProxmoxCompose.Main: Building transaction...
2025-10-25 18:10:46 MSK INFO ProxmoxCompose.Main: No actions needed!
```

Если действия нужны, вы увидите краткий вывод действий и следующую строку в конце:

```bash
2025-10-25 18:13:51 MSK INFO ProxmoxCompose.Main: Are you agree to execute following actions? [yes/no]
```

Для согласия на выполнение действий нужно написать `yes`, для прерывания `no`

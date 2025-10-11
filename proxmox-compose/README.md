# proxmox-compose

CLI tool for deploying virtual machines on Proxmox, inspired by Docker Compose.

# TODO

- Storage check
- Creating VMs not from templates
- Проверка "переходимости" ВМ со storage

# Общие принципы работы

- При клонировании не удаляются сети, если не указано иначе
- При изменении сетей и если ВМ существует, если второе подключение сети не указано явно, первое подключение к бриджу отключается
- ВСЕ VM должны находиться на Target-ноде

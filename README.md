# Infrastructure as Code - WordPress + Grafana + Loki

Автоматизоване розгортання інфраструктури на AWS з використанням Terraform та Ansible.

## Архітектура

- **Traefik Instance** (публічний) - Reverse proxy з SSL від Let's Encrypt
- **Monitoring Instance** (приватний) - Grafana + Loki + Promtail
- **Database Instance** (приватний) - MySQL для WordPress та Grafana

## Налаштування секретів

### Локальне використання

1. Створіть vault password файл:
```bash
echo "your_vault_password" > .vault_pass
chmod 600 .vault_pass
```

2. Відредагуйте зашифровані змінні:
```bash
ansible-vault edit ansible/group_vars/all/vault.yml --vault-password-file .vault_pass
```

3. Створіть SSH ключі:
```bash
ssh-keygen -t rsa -b 2048 -f terraform/my-key -N ""
```

4. Налаштуйте AWS credentials:
```bash
export AWS_ACCESS_KEY_ID="your_key"
export AWS_SECRET_ACCESS_KEY="your_secret"
```

### GitHub Actions Setup

Додайте наступні **Secrets** в налаштуваннях GitHub репозиторію
1. **AWS_ACCESS_KEY_ID** - AWS Access Key
2. **AWS_SECRET_ACCESS_KEY** - AWS Secret Key
3. **SSH_PRIVATE_KEY** - Вміст файлу `terraform/my-key`
4. **SSH_PUBLIC_KEY** - Вміст файлу `terraform/my-key.pub`
5. **ANSIBLE_VAULT_PASSWORD** - Пароль для розшифрування vault.yml (той що в `.vault_pass`)

### Локально

```bash
# 1. Deploy infrastructure
cd terraform
terraform init
terraform apply

# 2. Configure services
cd ../ansible
ansible-playbook -i inventory.ini playbook.yml --vault-password-file ../.vault_pass
```

### Через GitHub Actions

1. Push код в main гілку
2. Вручну

## Структура проєкту

```
.
├── terraform/           # Terraform конфігурації
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── ansible/            # Ansible playbooks
│   ├── playbook.yml
│   ├── files/          # Docker Compose & configs
│   └── group_vars/
│       └── all/
│           ├── vault.yml    # Зашифровані паролі
│           └── vars.yml     # Публічні змінні
└── .github/
    └── workflows/
        └── deploy.yml  # CI/CD pipeline

```

## DNS налаштування

Додайте A записи

- `wordpress.домен` → `<TRAEFIK_PUBLIC_IP>`
- `grafana.домен` → `<TRAEFIK_PUBLIC_IP>`


## Моніторинг

Логи всіх сервісів збираються через Promtail → Loki → Grafana.

Для перегляду логів WordPress:
1. Відкрийте Grafana
2. Explore → Loki
3. Query: `{job="dockerlogs", instance="traefik"}`

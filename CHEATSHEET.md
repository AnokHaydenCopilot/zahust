# 🚀 Quick Reference

## Локальне використання

### Перший деплой
```bash
./deploy.sh
```

### Видалити інфраструктуру
```bash
./destroy.sh
```

### Змінити паролі
```bash
# 1. Відредагувати vault
ansible-vault edit ansible/group_vars/all/vault.yml --vault-password-file .vault_pass

# 2. Задеплоїти зміни
cd ansible
ansible-playbook -i inventory.ini playbook.yml --vault-password-file ../.vault_pass
```

### Перевірка vault
```bash
# Показати зміст (розшифрований)
ansible-vault view ansible/group_vars/all/vault.yml --vault-password-file .vault_pass

# Змінити vault password
ansible-vault rekey ansible/group_vars/all/vault.yml
```

## GitHub Actions

### Secrets для додавання:
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
SSH_PRIVATE_KEY
SSH_PUBLIC_KEY
ANSIBLE_VAULT_PASSWORD
```

### Швидке додавання через CLI:
```bash
gh secret set AWS_ACCESS_KEY_ID -b "YOUR_KEY"
gh secret set AWS_SECRET_ACCESS_KEY -b "YOUR_SECRET"
gh secret set SSH_PRIVATE_KEY < terraform/my-key
gh secret set SSH_PUBLIC_KEY < terraform/my-key.pub
gh secret set ANSIBLE_VAULT_PASSWORD < .vault_pass
```

## Корисні команди

### Terraform
```bash
cd terraform
terraform init                    # Ініціалізація
terraform plan                    # Подивитись зміни
terraform apply                   # Застосувати
terraform output                  # Показати outputs
terraform destroy                 # Видалити все
```

### Ansible
```bash
cd ansible
# Запуск playbook
ansible-playbook -i inventory.ini playbook.yml --vault-password-file ../.vault_pass

# Тільки для database
ansible-playbook -i inventory.ini playbook.yml --limit database --vault-password-file ../.vault_pass

# Перевірка синтаксису
ansible-playbook playbook.yml --syntax-check

# Dry run
ansible-playbook -i inventory.ini playbook.yml --check
```

### SSH до серверів
```bash
# Traefik (публічний)
ssh -i terraform/my-key ubuntu@<TRAEFIK_IP>

# Monitoring (через traefik)
ssh -o ProxyCommand="ssh -i terraform/my-key -W %h:%p ubuntu@<TRAEFIK_IP>" -i terraform/my-key ubuntu@<MONITORING_IP>

# Database (через traefik)
ssh -o ProxyCommand="ssh -i terraform/my-key -W %h:%p ubuntu@<TRAEFIK_IP>" -i terraform/my-key ubuntu@<DATABASE_IP>
```

### Docker на серверах
```bash
# Переглянути контейнери
docker ps

# Логи контейнера
docker logs <container_name>

# Перезапустити
docker compose restart

# Зупинити все
docker compose down

# Запустити заново
docker compose up -d
```

## URLs

- WordPress: https://wordpress.infratestapp.pp.ua
- Grafana: https://grafana.infratestapp.pp.ua
- Grafana API Health: https://grafana.infratestapp.pp.ua/api/health

## Паролі (дивись в vault.yml)

```bash
ansible-vault view ansible/group_vars/all/vault.yml --vault-password-file .vault_pass
```

## Troubleshooting

### SSL сертифікати не отримуються
```bash
# Перевірити логи Traefik
ssh -i terraform/my-key ubuntu@<TRAEFIK_IP> "docker logs traefik"

# Перезапустити Traefik
ssh -i terraform/my-key ubuntu@<TRAEFIK_IP> "cd /opt/traefik && docker compose restart"
```

### WordPress не підключається до БД
```bash
# Перевірити MySQL логи
ssh ... ubuntu@<DATABASE_IP> "docker logs mysql_db"

# Перевірити connectivity
ssh ... ubuntu@<TRAEFIK_IP> "telnet <DATABASE_IP> 3306"
```

### Grafana 502 помилка
```bash
# Перевірити логи
ssh ... ubuntu@<MONITORING_IP> "docker logs grafana"

# Перевірити чи працює
ssh ... ubuntu@<MONITORING_IP> "curl localhost:3000"
```

# GitHub Actions Setup Guide

## 📋 Крок за кроком налаштування CI/CD

### 1. Створити Git репозиторій

```bash
cd /home/moder/ALL/Pleskanka
git init
git add .
git commit -m "Initial commit: Infrastructure as Code"

# Створіть репозиторій на GitHub, потім:
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git branch -M main
git push -u origin main
```

### 2. Додати GitHub Secrets

Перейдіть до: **Settings → Secrets and variables → Actions → New repository secret**

#### Потрібні секрети:

##### AWS Credentials
```bash
# AWS_ACCESS_KEY_ID
# Значення: ваш AWS Access Key

# AWS_SECRET_ACCESS_KEY  
# Значення: ваш AWS Secret Key
```

##### SSH Keys
```bash
# SSH_PRIVATE_KEY
# Значення: вміст файлу terraform/my-key
cat terraform/my-key

# SSH_PUBLIC_KEY
# Значення: вміст файлу terraform/my-key.pub
cat terraform/my-key.pub
```

##### Ansible Vault
```bash
# ANSIBLE_VAULT_PASSWORD
# Значення: ваш vault пароль (той що в .vault_pass)
cat .vault_pass
```

### 3. Приклад додавання секретів через GitHub CLI (опціонально)

```bash
# Встановіть GitHub CLI
# Ubuntu: sudo apt install gh
# Mac: brew install gh

# Авторизація
gh auth login

# Додавання секретів
gh secret set AWS_ACCESS_KEY_ID -b "YOUR_ACCESS_KEY"
gh secret set AWS_SECRET_ACCESS_KEY -b "YOUR_SECRET_KEY"
gh secret set SSH_PRIVATE_KEY < terraform/my-key
gh secret set SSH_PUBLIC_KEY < terraform/my-key.pub
gh secret set ANSIBLE_VAULT_PASSWORD < .vault_pass
```

### 4. Перевірка налаштування

```bash
# Переглянути список secrets
gh secret list

# Повинно показати:
# AWS_ACCESS_KEY_ID         Updated YYYY-MM-DD
# AWS_SECRET_ACCESS_KEY     Updated YYYY-MM-DD
# ANSIBLE_VAULT_PASSWORD    Updated YYYY-MM-DD
# SSH_PRIVATE_KEY           Updated YYYY-MM-DD
# SSH_PUBLIC_KEY            Updated YYYY-MM-DD
```

### 5. Запуск деплою

#### Автоматичний (при push):
```bash
git add .
git commit -m "Update configuration"
git push origin main
```

#### Ручний запуск:
1. Перейдіть до **Actions** tab на GitHub
2. Виберіть **Deploy Infrastructure**
3. Натисніть **Run workflow**
4. Виберіть гілку `main`
5. Натисніть зелену кнопку **Run workflow**

### 6. Моніторинг виконання

1. Перейдіть до **Actions** tab
2. Клікніть на запущений workflow
3. Спостерігайте за логами кожного job
4. Після завершення перевірте outputs

### 7. Destroy інфраструктури

1. **Actions** → **Destroy Infrastructure** → **Run workflow**
2. В полі `confirm` введіть: `destroy`
3. Натисніть **Run workflow**

## 🔒 Безпека

### ✅ Що НЕ треба комітити:
- ❌ `terraform/my-key` (приватний SSH ключ)
- ❌ `.vault_pass` (пароль vault)
- ❌ `*.tfstate` (Terraform state files)
- ❌ `Vitalii_accessKeys.csv` (AWS credentials)
- ❌ `ansible/inventory.ini` (генерується автоматично)

### ✅ Що комітити:
- ✅ `ansible/group_vars/all/vault.yml` (зашифрований!)
- ✅ `terraform/my-key.pub` (публічний ключ - безпечно)
- ✅ Всі `.yml`, `.tf`, `.j2` файли
- ✅ `.github/workflows/*`
- ✅ `README.md`, `deploy.sh`, `destroy.sh`

## 🐛 Troubleshooting

### Помилка: "Error: No valid credential sources found"
**Рішення**: Перевірте що секрети `AWS_ACCESS_KEY_ID` і `AWS_SECRET_ACCESS_KEY` додані правильно

### Помилка: "Permission denied (publickey)"
**Рішення**: Перевірте що `SSH_PRIVATE_KEY` містить весь ключ включно з `-----BEGIN` та `-----END`

### Помилка: "Ansible Vault password is incorrect"
**Рішення**: Перевірте що `ANSIBLE_VAULT_PASSWORD` співпадає з паролем, яким шифрували `vault.yml`

### Workflow не запускається
**Рішення**: Переконайтеся що workflow файли знаходяться в `.github/workflows/` і закомічені

## 📊 Структура Workflow

```
Deploy Infrastructure
├── Job 1: Terraform Apply
│   ├── Checkout code
│   ├── Configure AWS
│   ├── Setup Terraform
│   ├── Create SSH keys
│   ├── Terraform init/plan/apply
│   └── Output: traefik_ip
├── Job 2: Ansible Deploy (needs terraform)
│   ├── Checkout code
│   ├── Setup Python & Ansible
│   ├── Create SSH & Vault files
│   ├── Wait for instances
│   ├── Run playbook
│   └── Verify deployment
└── Job 3: Cleanup (always)
    └── Remove temporary files
```

## 🎯 Best Practices

1. **Завжди тестуйте локально** перед push в main
2. **Використовуйте branches** для експериментів
3. **Перевіряйте логи** GitHub Actions для debugging
4. **Rotate credentials** регулярно
5. **Не діліться** скріншотами з секретами
6. **Backup** важливих даних перед destroy

## 📝 Приклад комітів

```bash
# Хороші commit messages:
git commit -m "feat: add monitoring stack"
git commit -m "fix: update Grafana password configuration"
git commit -m "docs: update README with DNS setup"
git commit -m "chore: update Terraform to 1.9.0"
```

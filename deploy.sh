#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Infrastructure Deployment Script${NC}\n"

# Check if vault password file exists
if [ ! -f ".vault_pass" ]; then
    echo -e "${YELLOW}⚠️  Vault password file not found${NC}"
    read -sp "Enter Ansible Vault password: " VAULT_PASS
    echo
    echo "$VAULT_PASS" > .vault_pass
    chmod 600 .vault_pass
    echo -e "${GREEN}✓ Created .vault_pass${NC}"
fi

# Check SSH keys
if [ ! -f "terraform/my-key" ]; then
    echo -e "${YELLOW}⚠️  SSH keys not found${NC}"
    echo "Generating SSH keys..."
    ssh-keygen -t rsa -b 2048 -f terraform/my-key -N ""
    echo -e "${GREEN}✓ SSH keys generated${NC}"
fi

# Check AWS credentials
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo -e "${RED}❌ AWS credentials not set${NC}"
    echo "Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables"
    exit 1
fi

# Deploy Terraform
echo -e "\n${GREEN}📦 Deploying Terraform...${NC}"
cd terraform
terraform init
terraform plan
read -p "Apply Terraform changes? (yes/no): " CONFIRM
if [ "$CONFIRM" = "yes" ]; then
    terraform apply -auto-approve
else
    echo "Terraform deployment cancelled"
    exit 0
fi

# Wait for instances
echo -e "\n${YELLOW}⏳ Waiting 60 seconds for instances to initialize...${NC}"
sleep 60

# Deploy Ansible
echo -e "\n${GREEN}⚙️  Deploying Ansible...${NC}"
cd ../ansible
ansible-playbook -i inventory.ini playbook.yml --vault-password-file ../.vault_pass

# Get outputs
cd ../terraform
TRAEFIK_IP=$(terraform output -raw traefik_public_ip)

echo -e "\n${GREEN}✅ Deployment completed!${NC}\n"
echo "Traefik Public IP: $TRAEFIK_IP"
echo ""
echo "🔗 Services:"
echo "  WordPress: https://wordpress.infratestapp.pp.ua"
echo "  Grafana:   https://grafana.infratestapp.pp.ua"
echo ""
echo "📝 Don't forget to update DNS records to point to: $TRAEFIK_IP"

#!/bin/bash
set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}🗑️  Infrastructure Destroy Script${NC}\n"
echo -e "${YELLOW}⚠️  WARNING: This will destroy all infrastructure!${NC}\n"

read -p "Are you sure you want to destroy? Type 'yes' to confirm: " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Destruction cancelled"
    exit 0
fi

cd terraform
terraform destroy -auto-approve

echo -e "\n${RED}✓ Infrastructure destroyed${NC}"

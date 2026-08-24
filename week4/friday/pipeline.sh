#!/bin/bash

set -euo pipefail

echo "Starting KijaniKiosk IaC pipeline"

# 1. Terraform
echo "Applying Terraform"

cd terraform
terraform apply -auto-approve
cd ..

# 2. Get Multipass IPs
echo "Collecting VM IPs"

API_IP=$(multipass info kijanikiosk-api | grep IPv4 | awk '{print $2}')
PAYMENTS_IP=$(multipass info kijanikiosk-payments | grep IPv4 | awk '{print $2}')
LOGS_IP=$(multipass info kijanikiosk-logs | grep IPv4 | awk '{print $2}')


# 3. Generate inventory
echo "Generating inventory"

cat > ansible/inventory.ini <<EOF
[kijanikiosk_api]
api-staging ansible_host=$API_IP

[kijanikiosk_payments]
payments-staging ansible_host=$PAYMENTS_IP

[kijanikiosk_logs]
logs-staging ansible_host=$LOGS_IP

[kijanikiosk:children]
kijanikiosk_api
kijanikiosk_payments
kijanikiosk_logs

[kijanikiosk:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/home/sharon/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3
EOF


# 4. Run Ansible
echo "Running Ansible"

cd ansible
ansible-playbook -i inventory.ini kijanikiosk.yml

echo "Pipeline complete"

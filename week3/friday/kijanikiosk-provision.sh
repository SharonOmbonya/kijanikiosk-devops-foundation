#!/bin/bash

set -euo pipefail
echo "Starting KijaniKiosk"

echo "Phase 1: Pre-provisioning state acknowledged"
echo "# System may already contain users, groups, UFW rules, systemd units"


#Phase 2:Service User


if id kk-api &>/dev/null; then
  echo "kk-api already exists"
else
  useradd --system --no-create-home --home-dir /nonexistent --shell /usr/sbin/nologin --comment "KijaniKiosk API Service" kk-api
  echo "Created kk-api"
fi

if id kk-payments &>/dev/null; then
  echo "kk-payments already exists"
else
  useradd --system --no-create-home --home-dir /nonexistent --shell /usr/sbin/nologin --comment "Kijanikiosk Payments Service" kk-payments
  echo "Created kk-payments"
fi

if id kk-logs &>/dev/null; then
  echo "kk-logs already exists"
else
   useradd --system --no-create-home --home-dir /nonexistent --shell /usr/sbin/nologin --comment "KijanikioskLogs Service" kk-logs
  echo "Created kk-logs"
fi


# Phase 3: Group Setup


if getent group kijanikiosk &>/dev/null; then
  echo "Group kijanikiosk already exists"
else
  groupadd kijanikiosk
  echo "Group kijanikiosk created"
fi

usermod -aG kijanikiosk kk-api
usermod -aG kijanikiosk kk-payments
usermod -aG kijanikiosk kk-logs

# Phase 4: Directory Structure and Permissions
mkdir -p /opt/kijanikiosk/api
mkdir -p /opt/kijanikiosk/payments
mkdir -p /opt/kijanikiosk/logs
mkdir -p /opt/kijanikiosk/shared/logs
mkdir -p /opt/kijanikiosk/config
mkdir -p /opt/kijanikiosk/health

echo "Directories created"

#ownership and permissions

chown -R kk-api:kk-api /opt/kijanikiosk/api
chmod 750 /opt/kijanikiosk/api

chown -R kk-payments:kk-payments /opt/kijanikiosk/payments
chmod 750 /opt/kijanikiosk/payments

chown kk-logs:kk-logs /opt/kijanikiosk/logs
chmod 750 /opt/kijanikiosk/logs

chown kk-logs:kijanikiosk /opt/kijanikiosk/shared/logs
chmod 2770 /opt/kijanikiosk/shared/logs

chown root:kijanikiosk /opt/kijanikiosk/config
chmod 750 /opt/kijanikiosk/config

chown root:kijanikiosk /opt/kijanikiosk/health
chmod 750 /opt/kijanikiosk/health

# -------------------------
# Shared Logs (ACL CORE)
# -------------------------


# ACL permissions for services
setfacl -m u:kk-api:rwx /opt/kijanikiosk/shared/logs
setfacl -m u:kk-payments:r-x /opt/kijanikiosk/shared/logs
setfacl -m u:kk-logs:rwx /opt/kijanikiosk/shared/logs

# Default ACLs
setfacl -d -m u:kk-api:rwx /opt/kijanikiosk/shared/logs
setfacl -d -m u:kk-payments:r-x /opt/kijanikiosk/shared/logs
setfacl -d -m u:kk-logs:rwx /opt/kijanikiosk/shared/logs

echo "ACL configured"

# Phase 5: Firewall

ufw --force reset

#security
ufw default deny incoming
ufw default allow outgoing

# basic services
ufw allow 22/tcp comment "SSH access"
ufw allow 80/tcp comment "HTTP access"

# internal access ONLY
ufw allow from 10.0.1.0/24 to any port 3001 proto tcp comment "Monitoring access to payments endpoint"
ufw allow in on lo to any port 3001 proto tcp comment "Local access"

echo "Firewall configured"

verify_firewall() {
  local failed=0
  local status
  status=$(sudo ufw status)

  echo "$status" | grep -q "22/tcp.*ALLOW IN" \
    && echo "PASS: SSH (22) allowed" \
    || { echo "FAIL: SSH rule missing"; ((failed++)); }

  echo "$status" | grep -q "80/tcp.*ALLOW IN" \
    && echo "PASS: HTTP (80) allowed" \
    || { echo "FAIL: HTTP rule missing"; ((failed++)); }

  echo "$status" | grep -q "3001.*DENY IN" \
    && echo "PASS: port 3001 external deny present" \
    || { echo "FAIL: port 3001 deny rule missing"; ((failed++)); }

  [[ $failed -eq 0 ]] || { echo "ERROR: ${failed} firewall check(s) failed"; return 1; }

  echo "Firewall verification passed"
  return 0
}


# Phase 6: systemd Units

# /etc/systemd/system/kk-api.service
cat > /etc/systemd/system/kk-api.service <<EOF
[Unit]
Description=KijaniKiosk API Service
Documentation=https://github.com/kijanikiosk/api/blob/main/README.md
After= kk-payments.service network-online.target
Wants=network-online.target

[Service]
Type=simple
User=kk-api
Group=kk-api
WorkingDirectory=/opt/kijanikiosk/api
ExecStart=/usr/bin/node /opt/kijanikiosk/api/server.js
Restart=on-failure
RestartSec=5s

# restart cap
StartLimitIntervalSec=60
StartLimitBurst=3

TimeoutStartSec=30s
TimeoutStopSec=30s

# Environment files
EnvironmentFile=/opt/kijanikiosk/config/db.env
EnvironmentFile=/opt/kijanikiosk/config/api.env
Environment="NODE_ENV=production"
Environment="PORT=3000"

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=kk-api

# Hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
CapabilityBoundingSet=

ReadWritePaths=/opt/kijanikiosk/api
ReadWritePaths=/opt/kijanikiosk/shared/logs
ReadWritePaths=/opt/kijanikiosk/config

[Install]
WantedBy=multi-user.target

EOF

echo "systemd units deployed"


# Phase 7: Journal Persistence and Log Rotation

echo " Logging configuration"

provision_logging() {

  # Ensure persistent journal storage exists
  mkdir -p /var/log/journal
  systemd-tmpfiles --create --prefix /var/log/journal || true

  # Configure journald persistence + size limits
  mkdir -p /etc/systemd/journald.conf.d

  cat > /etc/systemd/journald.conf.d/kijanikiosk.conf <<EOF
[Journal]
Storage=persistent
Compress=yes
SystemMaxUse=500M
SystemMaxFileSize=50M
EOF

  systemctl restart systemd-journald || true

  # Logrotate configuration
  cat > /etc/logrotate.d/kijanikiosk <<EOF
/opt/kijanikiosk/shared/logs/*.log {
   su kk-logs kijanikiosk
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 640 kk-logs kijanikiosk
    sharedscripts
    postrotate
        systemctl reload kk-logs.service 2>/dev/null || true
    endscript
}
EOF
echo "Logging configured"
}
provision_logging

# Phase 8: Health Check


api_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3000" 2>/dev/null && echo '"ok"' || echo '"down"')
payments_status=$(timeout 2 bash -c "echo >/dev/tcp/localhost/3001" 2>/dev/null && echo '"ok"' || echo '"down"')

mkdir -p /opt/kijanikiosk/health

printf '{"timestamp":"%s","kk-api":%s,"kk-payments":%s}\n' \
"$(date -Is)" "$api_status" "$payments_status" \
> /opt/kijanikiosk/health/last-provision.json

chown kk-logs:kijanikiosk /opt/kijanikiosk/health/last-provision.json
chmod 640 /opt/kijanikiosk/health/last-provision.json

echo "Health check written"


echo " Provisioning Complete "


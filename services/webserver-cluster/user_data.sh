#!/bin/bash
set -e  # Exit immediately on error

# Update and install busybox
apt-get update -y
apt-get install -y busybox

# Setup web root
mkdir -p /var/www/html
chown www-data:www-data /var/www/html

# Write HTML file
cat > /var/www/html/index.html <<EOF
<h1>${SERVER_TEXT}</h1>
<p>DB address: ${DB_ADDRESS}</p>
<p>DB port: ${DB_PORT}</p>
EOF

# Create a systemd service for busybox httpd
cat > /etc/systemd/system/busybox-httpd.service <<SERVICE
[Unit]
Description=BusyBox HTTPD Web Server
After=network.target

[Service]
ExecStart=/bin/busybox httpd -f -p ${SERVER_PORT} -h /var/www/html
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

# Reload systemd to pick up new service
systemctl daemon-reload

# Enable and start the service
systemctl enable busybox-httpd
systemctl start busybox-httpd


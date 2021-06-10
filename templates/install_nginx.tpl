#!/bin/bash
set -e
echo "Installing nginx..."
apt update
apt install -y nginx
ufw allow '${ufw_allow_nginx}'
systemctl enable nginx
systemctl restart nginx

echo "Installation of nginx completed!"

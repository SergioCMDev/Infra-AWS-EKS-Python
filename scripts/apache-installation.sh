#!/bin/bash
# Logs detallados
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=== Actualizando sistema 1 ==="
timeout 10m dnf update -y

if [ $? -eq 124 ]; then
    echo "Actualización cancelada por timeout, continuando..."
elif [ $? -eq 0 ]; then
    echo "Actualización completada exitosamente"
else
    echo "Error en la actualización, continuando..."
fi

dnf upgrade --releasever=2023.8.20250818
echo "Configurando SSM Agent..."
sudo dnf install -y amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

echo "=== Instalando paquetes base ==="
dnf install -y httpd php

echo "=== Configurando Apache ==="
systemctl enable httpd
systemctl start httpd

echo "health" | sudo tee /var/www/html/health.html
chown apache:apache /var/www/html/health.html
chmod 644 /var/www/html/health.html

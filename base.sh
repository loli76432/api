#!/bin/bash

# Actualizar el sistema
echo "Actualizando paquetes..."
sudo apt update && sudo apt upgrade -y

# Instalar PostgreSQL
echo "Instalando PostgreSQL..."
sudo apt install postgresql -y

# Crear usuario y base de datos para Tryton
echo "Configurando PostgreSQL para Tryton..."
sudo -u postgres createuser --createdb --no-superuser --no-createrole server
sudo -u postgres psql -c "ALTER USER server WITH ENCRYPTED PASSWORD 'server';"
sudo -u postgres createdb -O server trytondb

# Instalar Tryton Server
echo "Instalando Tryton Server..."
sudo apt install tryton-server -y

# Configurar Tryton Server
echo "Configurando Tryton Server..."
TRYTON_CONF="/etc/tryton/trytond.conf"
sudo sed -i "s|^# uri =.*|uri = postgresql://server:server@localhost:5432/trytondb|" "$TRYTON_CONF"

# Reiniciar y habilitar Tryton Server
echo "Iniciando Tryton Server..."
sudo systemctl restart tryton-server
sudo systemctl enable tryton-server

# Configurar firewall (opcional)
echo "Configurando firewall..."
sudo ufw allow 8000/tcp

# Mensaje final
echo "Instalación y configuración de Tryton completada. Ahora puedes conectarte con el cliente Tryton."

#!/bin/bash

set -e  # Detener el script si hay errores

echo "Instalación de Trytond en openSUSE"

# Solicitar detalles
read -p "Nombre de la base de datos: " DB_NAME
read -p "Usuario de PostgreSQL: " DB_USER
read -sp "Contraseña para $DB_USER: " DB_PASS

echo "\nActualizando repositorios y paquetes..."
zypper refresh && zypper install -y postgresql postgresql-server python311 python311-pip python311-devel gcc \
    trytond trytond-tools trytond-party trytond-company trytond-account trytond-sale \
    trytond-product trytond-purchase trytond-stock trytond-calendar

# Inicializar PostgreSQL si es necesario
if ! systemctl is-active --quiet postgresql; then
    echo "Iniciando y habilitando PostgreSQL..."
    systemctl start postgresql
    systemctl enable postgresql
    sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$DB_PASS';"
fi

# Crear usuario y base de datos en PostgreSQL
sudo -u postgres psql <<EOF
CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASS';
CREATE DATABASE $DB_NAME OWNER $DB_USER;
EOF

echo "Configurando Trytond..."
mkdir -p /etc/tryton/
cat > /etc/tryton/trytond.conf <<EOL
[database]
host = localhost
port = 5432
database = $DB_NAME
user = $DB_USER
password = $DB_PASS
EOL

# Permitir acceso remoto a PostgreSQL
PG_HBA="/var/lib/pgsql/data/pg_hba.conf"
if ! grep -q "host all all 0.0.0.0/0 md5" $PG_HBA; then
    echo "host all all 0.0.0.0/0 md5" >> $PG_HBA
    systemctl restart postgresql
fi

# Configurar firewall para permitir acceso a Trytond
firewall-cmd --permanent --add-port=8000/tcp
firewall-cmd --reload

# Iniciar Trytond
trytond -c /etc/tryton/trytond.conf &
echo "Trytond está corriendo en el puerto 8000"

echo "Instalación completada. Puedes conectarte desde otro equipo en la red a IP_DEL_SERVIDOR:8000"

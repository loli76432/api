#!/bin/bash

# Función para mostrar mensajes de error
error() {
    echo "[ERROR] $1"
    exit 1
}

# 1. Revisar la configuración de Tryton para que escuche en todas las interfaces
echo "Verificando configuración de Tryton..."
TRYTON_CONF="/etc/tryton/trytond.conf"
LISTEN_SETTING=$(grep -E '^listen' "$TRYTON_CONF" | awk '{print $3}')

if [[ "$LISTEN_SETTING" != "0.0.0.0:8000" && "$LISTEN_SETTING" != "127.0.0.1:8000" ]]; then
    echo "No se encontró configuración de 'listen' adecuada, configurando a 0.0.0.0:8000"
    sudo sed -i 's/^listen = .*/listen = 0.0.0.0:8000/' "$TRYTON_CONF"
else
    echo "La configuración de Tryton ya está correcta en listen = 0.0.0.0:8000"
fi

# Reiniciar Tryton Server para aplicar cambios
echo "Reiniciando Tryton Server..."
sudo systemctl restart tryton-server || error "No se pudo reiniciar Tryton Server."

# 2. Verificar si el puerto 8000 está siendo escuchado
echo "Verificando si Tryton está escuchando en el puerto 8000..."
ss -tulnp | grep ':8000' > /dev/null
if [ $? -ne 0 ]; then
    error "Tryton no está escuchando en el puerto 8000. Revisa la configuración."
else
    echo "Tryton está escuchando en el puerto 8000."
fi

# 3. Configurar el firewall para permitir el acceso al puerto 8000
echo "Verificando y configurando el firewall para permitir el puerto 8000..."
sudo ufw allow 8000/tcp || error "No se pudo configurar el firewall."
sudo ufw reload || error "No se pudo recargar el firewall."

# Verificar que el puerto esté abierto en el firewall
echo "Verificando que el firewall permita conexiones al puerto 8000..."
sudo ufw status | grep '8000' > /dev/null
if [ $? -ne 0 ]; then
    error "El puerto 8000 no está abierto en el firewall."
else
    echo "El puerto 8000 está abierto en el firewall."
fi

# 4. Configurar PostgreSQL para aceptar conexiones remotas
echo "Verificando configuración de PostgreSQL..."
POSTGRES_CONF="/etc/postgresql/14/main/postgresql.conf"
PG_HBA="/etc/postgresql/14/main/pg_hba.conf"

# Asegurarse de que PostgreSQL escuche en todas las interfaces
PG_LISTEN=$(grep '^listen_addresses' "$POSTGRES_CONF" | awk '{print $3}')
if [[ "$PG_LISTEN" != "'*'" ]]; then
    echo "Configurando PostgreSQL para escuchar en todas las interfaces..."
    sudo sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" "$POSTGRES_CONF"
else
    echo "PostgreSQL ya está configurado para escuchar en todas las interfaces."
fi

# Asegurarse de que PostgreSQL permite conexiones remotas
PG_HBA_SETTING=$(grep "0.0.0.0/0" "$PG_HBA")
if [ -z "$PG_HBA_SETTING" ]; then
    echo "Configurando PostgreSQL para aceptar conexiones remotas..."
    echo "host all all 0.0.0.0/0 md5" | sudo tee -a "$PG_HBA"
else
    echo "PostgreSQL ya está configurado para aceptar conexiones remotas."
fi

# Reiniciar PostgreSQL para aplicar cambios
echo "Reiniciando PostgreSQL..."
sudo systemctl restart postgresql || error "No se pudo reiniciar PostgreSQL."

# 5. Verificar conectividad al servidor desde otra máquina
echo "Verificando la conectividad al servidor desde otra máquina (ping)..."
ping -c 4 $(hostname -I | awk '{print $1}') > /dev/null
if [ $? -ne 0 ]; then
    error "No se puede hacer ping a la IP del servidor. Verifica la red."
else
    echo "Ping exitoso a la IP del servidor."
fi

# 6. Verificar que el puerto 8000 es accesible desde otro sistema
echo "Verificando si el puerto 8000 es accesible desde otra máquina..."
nc -zv $(hostname -I | awk '{print $1}') 8000
if [ $? -ne 0 ]; then
    error "No se puede conectar al puerto 8000 desde otro sistema."
else
    echo "El puerto 8000 es accesible desde otra máquina."
fi

# 7. Confirmación final
echo "Verificación y configuración completadas exitosamente. Ahora intenta conectarte desde el cliente Tryton."

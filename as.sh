#!/bin/bash

# Variables - actualiza estos valores según tu configuración
DB_NAME="trytond"        # Nombre de la base de datos
DB_USER="tryton"                    # Usuario de la base de datos (por defecto es 'tryton')
TRYTOND_CONF_PATH="trytond.conf"  # Ruta al archivo trytond.conf
USER_LOGIN="server"          # Nombre de usuario de Tryton a verificar o crear
USER_PASSWORD="server"    # Contraseña del nuevo usuario

# Verificar si psql está disponible
if ! command -v psql &>/dev/null; then
    echo "psql no está instalado. Asegúrate de tener PostgreSQL instalado."
    exit 1
fi

# Conectarse a la base de datos y verificar si el usuario existe
echo "Verificando si el usuario '$USER_LOGIN' existe en la base de datos..."

USER_EXISTS=$(psql -U $DB_USER -d $DB_NAME -tAc "SELECT EXISTS (SELECT 1 FROM res_user WHERE login = '$USER_LOGIN');")

if [ "$USER_EXISTS" == "t" ]; then
    echo "El usuario '$USER_LOGIN' ya existe en la base de datos."
else
    echo "El usuario '$USER_LOGIN' no existe. Creando el usuario..."
    
    # Crear el usuario en la base de datos
    psql -U $DB_USER -d $DB_NAME <<EOF
    INSERT INTO res_user (login, password) VALUES ('$USER_LOGIN', '$USER_PASSWORD');
EOF
    echo "Usuario '$USER_LOGIN' creado exitosamente."
fi

# Actualizar la base de datos
echo "Actualizando la base de datos..."
trytond-admin --update=all --db=$DB_NAME

# Reiniciar el servidor Tryton (si tienes el servicio configurado)
echo "Reiniciando el servidor Tryton..."
systemctl restart trytond

# Si no tienes el servicio de Tryton configurado, puedes reiniciarlo manualmente:
# trytond --config=$TRYTOND_CONF_PATH

echo "El proceso ha finalizado. Intenta iniciar sesión en Tryton con el usuario '$USER_LOGIN'."

#!/bin/bash

# Este script descarga la imagen de Tails, corrige el problema del offset de la
# partición y extrae el kernel y el initrd para el arranque PXE.

# --- CONFIGURACIÓN DE RUTAS Y VERSIONES ---
TAILS_URL="https://download.tails.net/tails/stable/tails-amd64-7.2/tails-amd64-7.2.img"
TAILS_IMAGE_NAME="tails-amd64-7.2.img"

# Rutas dentro de tu proyecto
TFTP_ROOT="tftpboot"
TAILS_DIR="$TFTP_ROOT/tails"                  # Donde va vmlinuz e initrd (TFTP)
HTTP_DEST_DIR="$TFTP_ROOT/kali/tails-iso"    # Donde va la imagen completa (NGINX/HTTP)

# Basado en la depuración, la imagen de Tails 7.2 tiene solo una partición GPT (la 1)
LIVE_MEDIA_PARTITION=1

# --- VALIDACIÓN DE DEPENDENCIAS ---
echo "--- 1. Verificando dependencias y directorios ---"
if ! command -v wget &> /dev/null || ! command -v fdisk &> /dev/null || ! command -v parted &> /dev/null; then
    echo "ERROR: Por favor, instala 'wget', 'fdisk' y 'parted' antes de continuar."
    exit 1
fi
if [ "$(uname)" != "Linux" ]; then
    echo "ADVERTENCIA: Este script requiere comandos de montaje de Linux ('fdisk', 'mount') y 'sudo'."
fi

# Crea las carpetas necesarias
mkdir -p "$TAILS_DIR" "$HTTP_DEST_DIR"

# --- 2. DESCARGA Y COLOCACIÓN DE LA IMAGEN COMPLETA ---
echo "--- 2. Descargando Tails Image ---"
if [ ! -f "$HTTP_DEST_DIR/$TAILS_IMAGE_NAME" ]; then
    echo "   Descargando Tails Image (archivo grande)..."
    wget -q -O "$TAILS_IMAGE_NAME" "$TAILS_URL"
    if [ $? -ne 0 ]; then
        echo "   ERROR: La descarga de Tails falló."
        exit 1
    fi
    mv "$TAILS_IMAGE_NAME" "$HTTP_DEST_DIR"/
else
    echo "   Tails Image ya existe. Saltando descarga."
fi


# --- 3. EXTRACCIÓN DEL KERNEL Y INITRD (Sección de corrección de offset) ---
echo "--- 3. Extrayendo Kernel y Initrd ---"

LOCAL_IMAGE_PATH="$HTTP_DEST_DIR/$TAILS_IMAGE_NAME"
MOUNT_POINT="/mnt/tails_extract"

# 3.1: CREAR PUNTO DE MONTAJE CON SUDO
echo "   Creando punto de montaje temporal con sudo..."
# El punto de montaje debe crearse con sudo para evitar el error 'Permission denied' en /mnt/
sudo mkdir -p "$MOUNT_POINT"
if [ $? -ne 0 ]; then
    echo "   ERROR: Fallo al crear el punto de montaje. ¿Tienes permisos de sudo?"
    exit 1
fi

# 3.2: CALCULAR OFFSET CON PARTED Y RUTA ABSOLUTA
echo "   Calculando offset de la partición $LIVE_MEDIA_PARTITION con 'parted'..."

# Intentamos usar /sbin/parted y /usr/sbin/parted para mayor compatibilidad
PARTED_CMD=""
if [ -x /sbin/parted ]; then PARTED_CMD="/sbin/parted";
elif [ -x /usr/sbin/parted ]; then PARTED_CMD="/usr/sbin/parted";
else echo "ERROR: No se encontró el binario de 'parted'. Instálalo o verifica tu PATH."; sudo rmdir "$MOUNT_POINT"; exit 1;
fi

# El formato de parted -m es: NÚMERO:INICIO:FIN:TAMAÑO:FS:BANDERA
START_SECTOR=$(sudo "$PARTED_CMD" -m "$LOCAL_IMAGE_PATH" unit s print | grep "^$LIVE_MEDIA_PARTITION:" | cut -d: -f2 | sed 's/s$//')

if [ -z "$START_SECTOR" ]; then
    echo "   ERROR: No se pudo encontrar el sector de inicio para la partición $LIVE_MEDIA_PARTITION. El cálculo falló."
    sudo rmdir "$MOUNT_POINT"
    exit 1
fi

OFFSET_BYTES=$((START_SECTOR * 512))
echo "   Sector de inicio: $START_SECTOR. Offset calculado: $OFFSET_BYTES bytes."


# 3.3: MONTAR LA PARTICIÓN CON SUDO Y OFFSET CORRECTO
echo "   Montando la partición de Tails (requiere sudo)..."
sudo mount -o loop,offset="$OFFSET_BYTES" "$LOCAL_IMAGE_PATH" "$MOUNT_POINT"
if [ $? -ne 0 ]; then
    echo "   ERROR: El montaje de la partición falló con el offset $OFFSET_BYTES. Revisa 'dmesg(1)'."
    sudo rmdir "$MOUNT_POINT" 2>/dev/null
    exit 1
fi

# 3.4: COPIAR KERNEL E INITRD
echo "   Copiando vmlinuz e initrd.img a $TAILS_DIR..."
# Tails mantiene los archivos de arranque en la carpeta /live/
if [ -f "$MOUNT_POINT"/live/vmlinuz ] && [ -f "$MOUNT_POINT"/live/initrd.img ]; then
    sudo cp "$MOUNT_POINT"/live/vmlinuz "$TAILS_DIR"/vmlinuz
    sudo cp "$MOUNT_POINT"/live/initrd.img "$TAILS_DIR"/initrd.img
    echo "   Archivos encontrados en /live/."
else
    echo "   ERROR: No se pudo encontrar vmlinuz o initrd.img en la ruta /live/."
    # Limpiamos antes de salir
    sudo umount "$MOUNT_POINT"
    sudo rmdir "$MOUNT_POINT" 2>/dev/null
    exit 1
fi


# --- 4. LIMPIEZA ---
echo "--- 4. Limpieza ---"
sudo umount "$MOUNT_POINT"
sudo rmdir "$MOUNT_POINT"

echo "¡Configuración de Tails completada! Archivos de arranque listos en $TAILS_DIR/"
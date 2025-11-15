#!/bin/bash

# ==============================================================================
# PXE SERVER PROVISIONING SCRIPT
# Downloads, extracts, and organizes all necessary files for PXE boot (TFTP/HTTP).
# ==============================================================================

# --- CONFIGURATION PATHS AND VERSIONS ---
TFTP_ROOT="tftp"
HTTP_ROOT="http"
TAILS_IMAGE_NAME="tails-amd64-7.2.img"
KALI_ISO_NAME="kali-linux-2025.3-live-amd64.iso"
SYSLINUX_VERSION="6.03"
MEMTEST_VERSION="7.20"

# Download URLs
SYSLINUX_URL="https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-${SYSLINUX_VERSION}.zip"
KALI_URL="https://cdimage.kali.org/kali-2025.3/${KALI_ISO_NAME}"
TAILS_URL="https://download.tails.net/tails/stable/tails-amd64-7.2/${TAILS_IMAGE_NAME}"
MEMTEST_URL="https://www.memtest.org/download/v${MEMTEST_VERSION}/mt86plus_${MEMTEST_VERSION}.binaries.zip"

# Destination Paths
SYSLINUX_DIR="$TFTP_ROOT"
KALI_TFTP_DIR="$TFTP_ROOT/kali"
KALI_HTTP_DIR="$HTTP_ROOT"
TAILS_TFTP_DIR="$TFTP_ROOT/tails"
TAILS_HTTP_DIR="$HTTP_ROOT"
MEMTEST_TFTP_DIR="$TFTP_ROOT/memtest"

# --- 1. DEPENDENCY AND DIRECTORY VALIDATION ---
echo "--- 1. Checking dependencies and directories ---"
DEPS="wget tar parted mount umount unzip" 
MISSING_DEPS=""
for dep in $DEPS; do
    # Corrected: Use 'command -v' without the hyphen if necessary, though 'command -v' is standard.
    # Reverting to 'command -v' as it is the most portable syntax.
    if ! command -v $dep &> /dev/null; then
        MISSING_DEPS="$MISSING_DEPS $dep"
    fi
done

if [ ! -z "$MISSING_DEPS" ]; then
    echo "ERROR: Please install the following dependencies: $MISSING_DEPS"
    exit 1
fi
if [ "$(uname)" != "Linux" ]; then
    echo "WARNING: This script requires Linux mount commands ('mount', 'umount') and 'sudo'."
fi

# Create necessary working folders
mkdir -p "$TFTP_ROOT" "$HTTP_ROOT"
mkdir -p "$KALI_TFTP_DIR" "$TAILS_TFTP_DIR" "$MEMTEST_TFTP_DIR"

# ==============================================================================
# 2. SYSLINUX PROVISIONING (PXE Loader and Modules)
# ==============================================================================
echo "--- 2. Provisioning SYSLINUX ---"
SYSLINUX_ARCHIVE_ZIP="syslinux-${SYSLINUX_VERSION}.zip"

if [ ! -f "$SYSLINUX_DIR/pxelinux.0" ]; then
    echo "   Downloading SYSLINUX Binaries (ZIP) from official kernel mirror..."
    wget --show-progress -O "$SYSLINUX_ARCHIVE_ZIP" "$SYSLINUX_URL"
    
    if [ $? -ne 0 ]; then
        echo "   ERROR: SYSLINUX download failed. Check URL or network connection."
        rm -f "$SYSLINUX_ARCHIVE_ZIP" 2>/dev/null
        exit 1
    fi
    if [ ! -s "$SYSLINUX_ARCHIVE_ZIP" ]; then
        echo "   ERROR: Downloaded SYSLINUX file is empty or corrupt."
        rm -f "$SYSLINUX_ARCHIVE_ZIP" 2>/dev/null
        exit 1
    fi

    echo "   Extracting necessary boot files using 'unzip -j'..."

    # Required C32 modules for menu.c32, libcom32.c32, and ldlinux.c32
    unzip -q -j "$SYSLINUX_ARCHIVE_ZIP" \
        "bios/core/pxelinux.0" \
        "bios/com32/menu/menu.c32" \
        "bios/com32/chain/chain.c32" \
        "bios/com32/lib/libcom32.c32" \
        "bios/com32/libutil/libutil.c32" \
        "bios/com32/elflink/ldlinux/ldlinux.c32" \
        -d "$SYSLINUX_DIR"

    if [ $? -ne 0 ]; then
        echo "   WARNING: Unzip reported issues, but checking for pxelinux.0..."
    fi

    if [ ! -f "$SYSLINUX_DIR/pxelinux.0" ]; then
        echo "   ERROR: pxelinux.0 could not be extracted. Please check the ZIP file content manually."
        rm -f "$SYSLINUX_ARCHIVE_ZIP" 2>/dev/null
        exit 1
    fi

    # Cleanup intermediate files
    rm -f "$SYSLINUX_ARCHIVE_ZIP"

    echo "   SYSLINUX (${SYSLINUX_VERSION}) completed with C32 binaries."
else
    echo "   SYSLINUX files already exist. Skipping download."
fi

# ==============================================================================
# 3. KALI LINUX PROVISIONING
# ==============================================================================
echo "--- 3. Provisioning Kali Linux ---"
KALI_ISO_PATH="$KALI_HTTP_DIR/$KALI_ISO_NAME"
KALI_MOUNT_POINT="/mnt/kali_extract"

# 3.1: Download Kali ISO
if [ ! -f "$KALI_ISO_PATH" ]; then
    echo "   Downloading Kali ISO (large file)..."
    wget -q --show-progress -O "$KALI_ISO_PATH" "$KALI_URL"
    if [ $? -ne 0 ]; then
        echo "   ERROR: Kali download failed."
        exit 1
    fi
else
    echo "   Kali ISO already exists. Skipping download."
fi

# 3.2: Mount ISO and extract kernel/initrd
echo "   Mounting Kali ISO and extracting kernel/initrd (sudo required)..."
sudo mkdir -p "$KALI_MOUNT_POINT"
sudo mount "$KALI_ISO_PATH" "$KALI_MOUNT_POINT" -o loop,ro

if [ $? -ne 0 ]; then
    echo "   ERROR: Failed to mount Kali ISO."
else
    # Kali's kernel and initrd are located in /live/
    if [ -f "$KALI_MOUNT_POINT"/live/vmlinuz ] && [ -f "$KALI_MOUNT_POINT"/live/initrd.img ]; then
        sudo cp "$KALI_MOUNT_POINT"/live/vmlinuz "$KALI_TFTP_DIR"/vmlinuz
        sudo cp "$KALI_MOUNT_POINT"/live/initrd.img "$KALI_TFTP_DIR"/initrd.img
        echo "   Kali files extracted successfully."
    else
        echo "   WARNING: Could not find vmlinuz or initrd.img in expected paths."
    fi
    sudo umount "$KALI_MOUNT_POINT"
fi
sudo rmdir "$KALI_MOUNT_POINT" 2>/dev/null

# ==============================================================================
# 4. TAILS PROVISIONING (Using offset logic for the IMG file)
# ==============================================================================
echo "--- 4. Provisioning Tails ---"
LOCAL_IMAGE_PATH="$TAILS_HTTP_DIR/$TAILS_IMAGE_NAME"
MOUNT_POINT="/mnt/tails_extract"
LIVE_MEDIA_PARTITION=1

# 4.1: Download Tails Image
if [ ! -f "$LOCAL_IMAGE_PATH" ]; then
    echo "   Downloading Tails Image (large file)..."
    wget -q --show-progress -O "$LOCAL_IMAGE_PATH" "$TAILS_URL"
    if [ $? -ne 0 ]; then
        echo "   ERROR: Tails download failed."
        exit 1
    fi
else
    echo "   Tails Image already exists. Skipping download."
fi

# 4.2: Extract Kernel and Initrd 
echo "   Calculating offset and extracting kernel/initrd (sudo required)..."

# Calculate offset using parted
PARTED_CMD=$(command -v parted)
if [ -z "$PARTED_CMD" ]; then
    echo "   ERROR: 'parted' command not found."
    exit 1
fi

# Use parted to find the start sector of the first partition
START_SECTOR=$(sudo "$PARTED_CMD" -m "$LOCAL_IMAGE_PATH" unit s print | grep "^$LIVE_MEDIA_PARTITION:" | cut -d: -f2 | sed 's/s$//')

if [ -z "$START_SECTOR" ]; then
    echo "   ERROR: Could not find partition start sector."
    exit 1
fi

OFFSET_BYTES=$((START_SECTOR * 512))

# Mount partition with offset
sudo mkdir -p "$MOUNT_POINT"
sudo mount -o loop,offset="$OFFSET_BYTES" "$LOCAL_IMAGE_PATH" "$MOUNT_POINT"

if [ $? -ne 0 ]; then
    echo "   ERROR: Failed to mount Tails partition."
else
    # Copy Kernel and Initrd
    if [ -f "$MOUNT_POINT"/live/vmlinuz ] && [ -f "$MOUNT_POINT"/live/initrd.img ]; then
        sudo cp "$MOUNT_POINT"/live/vmlinuz "$TAILS_TFTP_DIR"/vmlinuz
        sudo cp "$MOUNT_POINT"/live/initrd.img "$TAILS_TFTP_DIR"/initrd.img
        echo "   Tails files extracted successfully."
    else
        echo "   ERROR: Could not find vmlinuz or initrd.img for Tails."
    fi
    # Cleanup
    sudo umount "$MOUNT_POINT"
fi
sudo rmdir "$MOUNT_POINT" 2>/dev/null

# ==============================================================================
# 5. MEMTEST86+ PROVISIONING
# ==============================================================================
echo "--- 5. Provisioning Memtest86+ ---"
MEMTEST_ZIP="mt86plus_${MEMTEST_VERSION}.binaries.zip"

if [ ! -f "$MEMTEST_TFTP_DIR/memtest32.bin" ]; then
    echo "   Downloading Memtest86+ binaries..."
    wget -q -O "$MEMTEST_TFTP_DIR/$MEMTEST_ZIP" "$MEMTEST_URL"

    echo "   Extracting .bin files..."
    unzip -q "$MEMTEST_TFTP_DIR/$MEMTEST_ZIP" -d "$MEMTEST_TFTP_DIR"

    # Remove .efi files and the zip, leaving only .bin for SYSLINUX
    rm -f "$MEMTEST_TFTP_DIR"/*.efi
    rm -f "$MEMTEST_TFTP_DIR/$MEMTEST_ZIP"

    if [ -f "$MEMTEST_TFTP_DIR/memtest32.bin" ]; then
        echo "   Memtest86+ completed."
    else
        echo "   ERROR: Failed to extract or find Memtest binary files."
    fi
else
    echo "   Memtest files already exist. Skipping download."
fi


# ==============================================================================
# 6. FILE PERMISSIONS ASSIGNMENT
# ==============================================================================
echo "--- 6. Setting File Permissions ---"

# Read-only permissions for files served by TFTP/HTTP
echo "   Setting permissions on $TFTP_ROOT and $HTTP_ROOT..."
sudo chmod -R 755 "$TFTP_ROOT"/* "$HTTP_ROOT"/*

echo "=================================================================="
echo "PROVISIONING COMPLETE."
echo "=================================================================="
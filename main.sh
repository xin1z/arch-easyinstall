#!/bin/bash

# exit the script when any command inside fails
set -e

echo "LAUNCHED"
echo "arch-easyinstall: an easy-to-use Arch install script with automatic detection and installation for drivers."

# Still in Development, remove when completed
echo "This script is still in development, and can cause unexpected problems. Use with caution."

# Set value for the size of EFI and the minimum size of ROOT
EFI_SIZE=512
ROOT_MIN=2048

# Get path
BASE_DIR=$(cd "$(dirname "$0")" && pwd)

# Start module select_disk
TMPFILE=$(mktemp)

"${BASE_DIR}/modules/01_select_disk.sh" "$EFI_SIZE" "$ROOT_MIN" "$TMPFILE" || {
    echo "Error: Disk selection failed, aborting..."
    exit 1
}

eval "$(cat "$TMPFILE")"
rm -f "$TMPFILE"

# Start module create_partitions
TMPFILE=$(mktemp)
echo ""
"${BASE_DIR}/modules/02_create_partitions.sh" "$EFI_SIZE" "$ROOT_MIN" "$TARGET_DISK" "$DISK_SIZE_MiB" "$TMPFILE" || {
    echo "Error: Disk creation failed, aborting..."
    exit 1
}

eval "$(cat "$TMPFILE")"
rm -f "$TMPFILE"

# Start module format_partitions
echo ""
"${BASE_DIR}/modules/03_format_partitions.sh" "$TARGET_DISK" "$USE_SWAP" || {
    echo "Error: Formatting partitions failed, aborting..."
    exit 1
}

# Start module mount_partitions
echo ""
"${BASE_DIR}/modules/04_mount_partitions.sh" "$TARGET_DISK" "$USE_SWAP" || {
    echo "Error: Mounting partitions failed, aborting..."
    exit 1
}

# Set default mount points
MOUNT_POINT="/mnt"
EFI_MOUNT_POINT="/mnt/boot"
EFI_MOUNT_POINT_INSIDE="/boot"

# Start module pacstrap_partitions
echo ""
"${BASE_DIR}/modules/05_pacstrap_system.sh" "${MOUNT_POINT}" || {
    echo "Error: Pacstrapping partitions failed, aborting..."
    exit 1
}

# Start module install_gpu_drivers
TMPFILE=$(mktemp)

"${BASE_DIR}/modules/06_install_gpu_drivers.sh" "${MOUNT_POINT}" "${TMPFILE}" || {
    echo "Error: Installing GPU drivers failed, aborting..."
    exit 1
}

eval "$(cat "$TMPFILE")"
rm -f "$TMPFILE"

# Start module configure_fstab_and_boot
"${BASE_DIR}/modules/07_configure_fstab_and_boot.sh" "${MOUNT_POINT}" "${EFI_MOUNT_POINT_INSIDE}" || {
    echo "Error: Configuring fstab and bootloader failed, aborting..."
    exit 1
}

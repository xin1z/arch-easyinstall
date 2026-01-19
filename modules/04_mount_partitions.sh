#!/bin/bash

# exit the script when any command inside fails
set -e

TARGET_DISK="$1"
USE_SWAP=$2

if [[ -z "$TARGET_DISK" || -z "$USE_SWAP" ]]; then
    echo "Usage: $0 TARGET_DISK USE_SWAP"
    exit 1
fi

echo "Mounting partitions..."

# ---determine partition names---
# check for NVMe devices
if [[ "${TARGET_DISK}" =~ "nvme" ]]; then
    EFI_PART="${TARGET_DISK}p1"
    ROOT_PART="${TARGET_DISK}p2"
    [[ "$USE_SWAP" == "1" ]] && SWAP_PART="${TARGET_DISK}p3"
else
    EFI_PART="${TARGET_DISK}1"
    ROOT_PART="${TARGET_DISK}2"
    [[ "$USE_SWAP" == "1" ]] && SWAP_PART="${TARGET_DISK}3"
fi

# ---mount partitions---
echo "Mounting ${ROOT_PART} to /mnt"
mount "${ROOT_PART}" /mnt

echo "Creating /mnt/boot/efi directory for EFI partition"
mkdir -p /mnt/boot/efi

echo "Mounting ${EFI_PART} to /mnt/boot/efi"
mount "${EFI_PART}" /mnt/boot/efi

# ---enable SWAP---
if [[ "$USE_SWAP" == "1" ]]; then
    echo "Enabling SWAP partition ${SWAP_PART}"
    swapon "${SWAP_PART}"
fi

echo "Mounting completed."
echo "Current mount points:"
lsblk "${TARGET_DISK}"

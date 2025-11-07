#!/bin/bash

# exit the script when any command inside fails
set -e

TARGET_DISK="$1"
USE_SWAP=$2

if [[ -z "$TARGET_DISK" || -z "$USE_SWAP" ]]; then
    echo "Usage: $0 TARGET_DISK USE_SWAP"
    exit 1
fi

echo "Formatting partitions..."

# ---format partitions---
# confirm names for partitions
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

# format Root as EXT4
mkfs.ext4 -F "${ROOT_PART}" -L ARCH_ROOT

# format EFI as FAT32
mkfs.fat -F32 "${EFI_PART}" -n EFI_SYSTEM

# Enable SWAP (if exists)
if [[ "$SWAP_SPACE" -gt 0 ]]; then
    mkswap "${SWAP_PART}" -L ARCH_SWAP
fi

echo "Formatting completed."

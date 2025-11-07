#!/bin/bash

set -e

# Parameters of the size of EFI && the minimun size of ROOT
EFI_SIZE=$1
ROOT_MIN=$2
TMPFILE=${!#}

if [[ -z "$EFI_SIZE" || -z "$ROOT_MIN" || -z "$TMPFILE" ]]; then
    echo "Usage: $0 EFI_SIZE ROOT_MINi TMPFILE"
    exit 1
fi

# List all available disks
echo ""
echo "Please select the disk you want to install Arch Linux."
echo "Available disks:"

lsblk -dno NAME,SIZE,TYPE | awk '$3=="disk" || $3=="rom" {print " /dev/"$1, $2}'

DISK_SIZE_MIN=$((EFI_SIZE + ROOT_MIN))

validate_disk() {
    local disk="$1"

    # Validate if the disk even exists
    if [[ ! -b "$disk" ]]; then
        echo "Error: disk ${disk} doesn't exist or isn't a block device."
        return 1
    fi

    # Get size
    local size
    size=$(parted -s "$disk" unit MiB print \
        | awk '/^Disk/ {gsub("MiB","",$3); print int($3); exit}')
    if [[ -z "$size" || "$size" -le 0 ]]; then
        echo "Error: Unable to detect disk size."
        return 1
    fi

    # The size must be greater than the minimun value
    if (( size < DISK_SIZE_MIN )); then
        echo "Error: disk size ${size}MiB is smaller than minimun ${DISK_SIZE_MIN}MiB."
        return 1
    fi

    echo "Disk ${disk} detected: ${size}MiB (OK)"
    DISK_SIZE_MiB=$size
    return 0
}

while true; do
    read -r -p "Please select the target disk to install (e.g. /dev/sda, /dev/vda, /dev/nvmeXnX etc.). The size should be at least ${DISK_SIZE_MIN} MiB in total: " TARGET_DISK
    if validate_disk "$TARGET_DISK"; then
        break
    fi
done

echo "target disk CONFIRMED as ${TARGET_DISK}."

# Ask if really want to proceed
echo ""
read -r -p "Warning here: Everything in ${TARGET_DISK} will be ERASED. Are you sure you want to proceed? (yes/no): " CONFIRM

if [[ "${CONFIRM}" != "yes" ]]; then
    echo "Operation canceled."
    exit 1
fi

# Double check here lah
read -r -p "Double confirmation here - Do you REALLY want to proceed? Make sure that you understand everything in ${TARGET_DISK} will be ERASED. If yes, please type 'Yes, I understand everything in ${TARGET_DISK} will be ERASED.' (This part is case and punctuation sensitive): " DOUBLE_CHECK

if [[ "${DOUBLE_CHECK}" != "Yes, I understand everything in ${TARGET_DISK} will be ERASED." ]]; then
    echo "Operation canceled."
    exit 1
fi

echo "TARGET_DISK=${TARGET_DISK}" > "$TMPFILE"
echo "DISK_SIZE_MiB=$DISK_SIZE_MiB" >> "$TMPFILE"

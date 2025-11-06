#!/bin/bash

# exit the script when any command inside fails
set -e

echo "LAUNCHED"
echo "arch-easyinstall: an easy-to-use Arch install script with automatic detection and installation for drivers."

# Still in Development lah, remove when completed
echo "This script is still in development, and can cause unexpected problems. Use with caution."

# List all available disks
echo ""
echo "Please select the disk you want to install Arch Linux."
echo "Available disks:"

lsblk -dno NAME,SIZE,TYPE | awk '$3=="disk" || $3=="rom" {print " /dev/"$1, $2}'

echo ""
read -r -p "Please select the target disk to install (e.g. /dev/sda, /dev/vda, /dev/nvmeXnX etc.): " TARGET_DISK

# Simple input validation
while [[ ! -b "${TARGET_DISK}" ]]; do
    read -r -p  "Error: disk ${TARGET_DISK} doesn't exist or isn't a block device. Try again: " TARGET_DISK
done

echo "target disk CONFIRMED as ${TARGET_DISK}"

# Ask if really want to proceed
echo ""
read -r -p "Warning here: Everything in ${TARGET_DISK} will be ERASED. Are you sure you want to proceed? (yes/no): " CONFIRM

if [[ "${CONFIRM}" != "yes" ]]; then
    echo "Operation canceled."
    exit 0
fi

# Double check here lah
read -r -p "Double confirmation here - Do you REALLY want to proceed? Make sure that you understand everything in ${TARGET_DISK} will be ERASED. (yes/no): " DOUBLE_CHECK

if [[ "${DOUBLE_CHECK}" != "yes" ]]; then
    echo "Operation canceled."
    exit 0
fi

echo ""
echo "START PARTITIONING:"


# ---Create SWAP---
# Get size of RAM (MiB)
TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')

# Set recommended size for SWAP
if [[ "$TOTAL_RAM" -lt 2048 ]]; then
    RECOMMENDED_SWAP=2048
elif [[ "$TOTAL_RAM" -le 8192 ]]; then
    RECOMMENDED_SWAP=$TOTAL_RAM
else
    RECOMMENDED_SWAP=4096
fi

echo ""
echo "System RAM detected: ${TOTAL_RAM} MiB"
echo "Recommended SWAP size: ${RECOMMENDED_SWAP} MiB (you can modify)"

# ask for spaces allocated for SWAP
read -r -p "Space allocated for SWAP (in MiB, leave blank to use the recommended value, input 0 to skip): " SWAP_SPACE_INPUT

# Simple input validation
while [[ -n "$SWAP_SPACE_INPUT" && ! "$SWAP_SPACE_INPUT" =~ ^[0-9]+$ ]]; do
    read -r -p "Error: '$SWAP_SPACE_INPUT' is invalid. It MUST be a positive number or 0 (MiB). Try again: " SWAP_SPACE_INPUT
done

# Set SWAP_SPACE variable based on input
SWAP_SPACE=0

if [[ -z "$SWAP_SPACE_INPUT" || "$SWAP_SPACE_INPUT" == "$RECOMMENDED_SWAP" ]]; then
    # Use recommended SWAP if blank or matching recommendation
    SWAP_SPACE=$RECOMMENDED_SWAP
    echo "Use the recommended size for SWAP: ${SWAP_SPACE} MiB."
elif [[ "$SWAP_SPACE_INPUT" == "0" ]]; then
    SWAP_SPACE=0
    echo "No SWAP will be created."
else
    SWAP_SPACE=$SWAP_SPACE_INPUT
    echo "SWAP will be created with ${SWAP_SPACE} MiB in size."
fi


# ---Start automatic partitioning (GPT+UEFI)---

# Define starting points for partitions
PART_START="1MiB"

# End point for EFI
EFI_END="513MiB"
# Starting point of Root
ROOT_START="${EFI_END}"

# Calculate end point of Root
if [[ "$SWAP_SPACE" -gt 0 ]]; then
    DISK_SIZE_MiB=$(parted -s "$TARGET_DISK" unit MiB print \
                | awk '/^Disk/ {gsub("MiB","",$3); print int($3); exit}')
    if [[ -z "$DISK_SIZE_MiB" || "$DISK_SIZE_MiB" -le 0 ]]; then
        echo "Error: Unable to detect disk size for ${TARGET_DISK}."
        exit 1
    fi
    ROOT_END_MiB=$((DISK_SIZE_MiB - SWAP_SPACE - 2))
    ROOT_END="${ROOT_END_MiB}MiB"
    SWAP_START="$((ROOT_END_MiB + 1))MiB"

    echo "ROOT_END_MiB=${ROOT_END_MiB}, SWAP_SPACE=${SWAP_SPACE}"
    SWAP_END="100%"
else
    ROOT_END="100%"
fi

echo ""
echo "Erasing and creating partitions in ${TARGET_DISK}..."

# erasing all partition tables and create a new one
parted -s "${TARGET_DISK}" mklabel gpt

# create EFI partition (512 MiB)
echo "Creating EFI: start=${PART_START} end=${EFI_END}"
parted -s "${TARGET_DISK}" mkpart primary fat32 "${PART_START}" "${EFI_END}"
parted -s "${TARGET_DISK}" set 1 esp on

# create root partition (EXT4)
echo "Creating ROOT: start=$ROOT_START end=$ROOT_END"
parted -s "${TARGET_DISK}" mkpart primary ext4 "${ROOT_START}" "${ROOT_END}"

# create swap (if want)
if [[ "$SWAP_SPACE" -gt 0 ]]; then
    echo "Creating SWAP: start=$SWAP_START end=$SWAP_END"
    parted -s "$TARGET_DISK" mkpart primary linux-swap "${SWAP_START}" "${SWAP_END}"
    parted -s "${TARGET_DISK}" set 3 swap on
fi

echo "Partitions created. Here's the current partition table:"
lsblk "${TARGET_DISK}"

# ---format partitions---
echo ""
echo "formatting partitions..."

# confirm names for partitions
# check for NVMe devices
if [[ "${TARGET_DISK}" =~ "nvme" ]]; then
    EFI_PART="${TARGET_DISK}p1"
    ROOT_PART="${TARGET_DISK}p2"
    [[ "$SWAP_SPACE" -gt 0 ]] && SWAP_PART="${TARGET_DISK}p3"
else
    EFI_PART="${TARGET_DISK}1"
    ROOT_PART="${TARGET_DISK}2"
    [[ "$SWAP_SPACE" -gt 0 ]] && SWAP_PART="${TARGET_DISK}3"
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


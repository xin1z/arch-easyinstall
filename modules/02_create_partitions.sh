#!/bin/bash

# exit the script when any command inside fails
set -e

# Get EFI_SIZE && ROOT_MIN && TARGET_DISK && DISK_SIZE_MiB
EFI_SIZE=$1
ROOT_MIN=$2
TARGET_DISK="$3"
DISK_SIZE_MiB=$4
TMPFILE=${!#}

if [[ -z "$EFI_SIZE" || -z "$ROOT_MIN" || -z "$TARGET_DISK" || -z "$DISK_SIZE_MiB" || -z "$TMPFILE" ]]; then
    echo "Usage: $0 EFI_SIZE ROOT_MIN TARGET_DISK DISK_SIZE_MiB TMPFILE"
    exit 1
fi

echo "Start creating partitions."

# ---Create SWAP---
# Get size of RAM (MiB)
TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')

# Set recommended size for SWAP
if (( $TOTAL_RAM < 2048 )); then
    RECOMMENDED_SWAP=2048
elif (( $TOTAL_RAM <= 8192 )); then
    RECOMMENDED_SWAP=$TOTAL_RAM
else
    RECOMMENDED_SWAP=4096
fi

# Get available space that can be allocated to SWAP
SWAP_SPACE_AVAILABLE=$((DISK_SIZE_MiB - ROOT_MIN - EFI_SIZE - 2))
if (( $SWAP_SPACE_AVAILABLE <= 0 )); then
    SWAP_SPACE_AVAILABLE=0
fi

if [[ ! "${SWAP_SPACE_AVAILABLE}" -gt "${RECOMMENDED_SWAP}" ]]; then
    RECOMMENDED_SWAP=${SWAP_SPACE_AVAILABLE}
fi

echo ""
echo "System RAM detected: ${TOTAL_RAM} MiB"
echo "Recommended SWAP size: ${RECOMMENDED_SWAP} MiB (you can modify), Space available to be allocated to SWAP: ${SWAP_SPACE_AVAILABLE}"

validate_swap()
{
    local input=$1
    
    if [[ -z "$input" ]]; then
        echo "$RECOMMENDED_SWAP"
        return 0
    fi
    if ! [[ "$input" =~ ^[0-9]+$ ]]; then
        return 1
    fi
    if (( input > SWAP_SPACE_AVAILABLE )); then
        echo "$SWAP_SPACE_AVAILABLE"
        return 0
    fi
    echo "$input"
    return 0
}
# ask for spaces allocated for SWAP
while true; do
    read -r -p "Space allocated for SWAP (MiB, leave blank if want to use the recommended size, input 0 to skip): " SWAP_SPACE_INPUT
    SWAP_SPACE=$(validate_swap "$SWAP_SPACE_INPUT") || {
        echo "Invalid input, try again."
        continue
    }
    break
done

# Define starting and end points for partitioning
PART_START_MiB=1
PART_START="${PART_START_MiB}MiB"
EFI_END_MiB=$((PART_START_MiB + EFI_SIZE))
EFI_END="${EFI_END_MiB}MiB"
ROOT_START="${EFI_END_MiB}MiB"

# Calculate end point of Root
if (( SWAP_SPACE > 0 )); then
    ROOT_END_MiB=$((DISK_SIZE_MiB - SWAP_SPACE - 2))
    ROOT_END="${ROOT_END_MiB}MiB"
    SWAP_START="$((ROOT_END_MiB + 1))MiB"
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
USE_SWAP=0
if (( SWAP_SPACE > 0 )); then
    USE_SWAP=1
    echo "Creating SWAP: start=$SWAP_START end=$SWAP_END"
    parted -s "$TARGET_DISK" mkpart primary linux-swap "${SWAP_START}" "${SWAP_END}"
    parted -s "${TARGET_DISK}" set 3 swap on
fi

echo "Partitions created. Here's the current partition table:"
lsblk "${TARGET_DISK}"

echo "USE_SWAP=${USE_SWAP}" > "$TMPFILE"

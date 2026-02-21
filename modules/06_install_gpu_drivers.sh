#!/bin/bash

 # Exit the script when any command inside fails
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 MOUNT_POINT TMPFILE"
    exit 1
fi

MOUNT_POINT="$1"
TMPFILE="$2"

# Check if the mount point is valid
if ! mountpoint -q "$MOUNT_POINT"; then
    echo "Error: '$MOUNT_POINT' is not a valid mount point."
    exit 1
fi

# Load package configs from packages.conf
echo "Loading configs..."
source "$(dirname "$0")/../packages.conf" || {
    echo "Error: Unable to load config files 'packages.conf'."
    exit 1
}

# Detect GPUs
echo "Detecting GPUs..."
declare -a PACKAGE_LIST=()
declare -i GPU_FOUND=0
declare -i NVIDIA_PROPRIETARY_USED=0

if lspci | grep -Eqi "VGA|3D|Display" | grep -qi "nvidia"; then
    GPU_FOUND+=1
    CONFIRM=""
    while true; do
        read -r -p "NVIDIA GPU detected, do you want to install the proprietary drivers? (y/n): " CONFIRM
        case "$CONFIRM" in
            [Yy]* )
                NVIDIA_PROPRIETARY_USED=1
                PACKAGE_LIST+=("${NVIDIA_PROPRIETARY[@]}")
                echo "-> Proprietary drivers will be installed."
                break ;;
            [Nn]* )
            PACKAGE_LIST+=("${NVIDIA_OPEN[@]}")
            echo "-> Open-source drivers will be installed."
            break ;;
        * ) echo "Input '${CONFIRM}' is invalid, please try again: " ;;
        esac
    done
fi

if lspci | grep -Eqi "VGA|3D|Display" | grep -qi "amd"; then
    GPU_FOUND+=1
    PACKAGE_LIST+=("${AMD_DRIVERS[@]}")
    echo "-> AMD GPU detected, related drivers will be installed."
fi

if lspci | grep -Eqi "VGA|3D|Display" | grep -qi "intel"; then
    GPU_FOUND+=1
    PACKAGE_LIST+=("${INTEL_DRIVERS[@]}")
    echo "-> Intel GPU detected, related drivers will be installed."
fi

if [[ $GPU_FOUND == 0 ]]; then
    PACKAGE_LIST+=("${GENERAL_DRIVERS[@]}")
    echo "Unable to detect GPU. '${GENERAL_DRIVERS[@]}' will be installed."
fi

# Check if the GPUs are hybrid
if [[ $NVIDIA_PROPRIETARY_USED  == 1 && $GPU_FOUND -gt 1 ]]; then
    PACKAGE_LIST+=("${NVIDIA_PROPRIETARY_PRIME[@]}")
    echo "NVIDIA hybrid GPU detected, '${NVIDIA_PROPRIETARY_PRIME[@]}' will be installed."
fi

# Pacstrap packages
echo "The following packages will be installed:"
echo "${PACKAGE_LIST[@]}"
echo ""
while true; do
    read -r -p "Do you want to proceed? (Y/n): " CONFIRM
    if [[ -z "${CONFIRM}" || "${CONFIRM}" == "Y" || "${CONFIRM}" == "y" ]]; then
        break
    elif [[ "${CONFIRM}" == "N" || "${CONFIRM}" == "n" ]]; then
        echo "Operation canceled."
        exit 0
    fi
done

echo "Pacstrapping packages..."
pacstrap "$MOUNT_POINT" "${PACKAGE_LIST[@]}" --noconfirm || {
    echo "Pacstrapping packages failed, aborting..."
    exit 1
}
echo "Drivers installed successfully."

echo "NVIDIA_PROPRIETARY_USED=${NVIDIA_PROPRIETARY_USED}" > "$TMPFILE"

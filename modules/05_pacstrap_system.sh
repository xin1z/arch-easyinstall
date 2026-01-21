#!/bin/bash

# exit the script when any command inside fails
set -e

MOUNT_POINT="$1"

if [[ -z "$MOUNT_POINT" ]]; then
    echo "Usage: $0 MOUNT_POINT"
    exit 1
fi

# Check if the mount points are valid
if ! mountpoint -q "$MOUNT_POINT"; then
    echo "Error: '$MOUNT_POINT' is not a valid mount point."
    exit 1
fi

# Install base system
echo "Installing base system to ${MOUNT_POINT}..."

# Load package configs from packages.conf
echo "Loading configs..."
source "$(dirname "$0")/../packages.conf" || {
    echo "Error: Unable to load config files 'packages.conf'."
    exit 1
}

echo ""
echo "Pacstrapping packages..."
echo "The following packages will be installed on ${MOUNT_POINT}:"
echo "${BASE_PACKAGES[@]}"
echo "${EXTRA_PACKAGES[@]}"

echo "Installing base packages..."
pacstrap $MOUNT_POINT ${BASE_PACKAGES[@]} --noconfirm || {
    echo "Error: Unable to pacstrap base packages."
    exit 1
}

echo "Installing extra packages..."
pacstrap $MOUNT_POINT ${EXTRA_PACKAGES[@]} --noconfirm || {
    echo "Error: Unable to pacstrap extra packages."
    exit 1
}

echo "Installing CPU ucode..."
echo "Checking CPU vendor..."

# Get CPU vender
CPU_VENDOR=$(lscpu | awk -F': +' '/Vendor ID:/ {print $2}')

if [[ "$CPU_VENDOR" == "GenuineIntel" ]]; then
    pacstrap $MOUNT_POINT intel-ucode --noconfirm || {
        echo "Error: Unable to install Intel ucode."
        exit 1
    }
    echo "Intel ucode installed successfully."
elif [[ "$CPU_VENDOR" == "AuthenticAMD" ]]; then
    pacstrap $MOUNT_POINT amd-ucode --noconfirm || {
        echo "Error: Unable to install AMD ucode."
        exit 1
    }
    echo "AMD ucode installed successfully."
else
    echo "Unknown CPU vendor: $CPU_VENDOR. Skipping ucode installation."
fi

echo "Packages installed successfully."

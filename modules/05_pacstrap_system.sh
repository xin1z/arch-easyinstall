#!/bin/bash

# exit the script when any command inside fails
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 MOUNT_POINT"
    exit 1
fi

MOUNT_POINT="$1"

# Check if the mount point is valid
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
echo "BASE: ${BASE_PACKAGES[@]}"
echo "EXTRA: ${EXTRA_PACKAGES[@]}"

# Aggregate packages
declare -a FINAL_PACKAGES=()
FINAL_PACKAGES+=("${BASE_PACKAGES[@]}")
FINAL_PACKAGES+=("${EXTRA_PACKAGES[@]}")

# Get CPU vendor
echo ""
echo "Checking CPU vendor..."
if grep -q "GenuineIntel" /proc/cpuinfo; then
    FINAL_PACKAGES+=("intel-ucode")
    echo "Intel CPU detected, package 'intel-ucode' will be installed."
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    FINAL_PACKAGES+=("amd-ucode")
    echo "AMD CPU detected, package 'amd-ucode' will be installed."
else
    echo "Unable to detect CPU vendor. Skipping ucode installation."
fi

echo ""
echo "Installing packages..."
pacstrap $MOUNT_POINT "${FINAL_PACKAGES[@]}" --noconfirm || {
    echo "Error: Unable to pacstrap packages."
    exit 1
}

echo "Packages installed successfully."

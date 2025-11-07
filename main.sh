#!/bin/bash

# exit the script when any command inside fails
set -e

echo "LAUNCHED"
echo "arch-easyinstall: an easy-to-use Arch install script with automatic detection and installation for drivers."

# Still in Development lah, remove when completed
echo "This script is still in development, and can cause unexpected problems. Use with caution."

# Set value for the size of EFI and the minimun size of ROOT
EFI_SIZE=512
ROOT_MIN=2048

# Start module select_disk
TMPFILE=$(mktemp)

./modules/01_select_disk.sh "$EFI_SIZE" "$ROOT_MIN" "$TMPFILE" || {
    echo "Disk selection failed, aborting..."
    exit 1
}

eval "$(cat "$TMPFILE")"
rm -f "$TMPFILE"

# Start module create_partitions
TMPFILE=$(mktemp)
echo ""
./modules/02_create_partitions.sh "$EFI_SIZE" "$ROOT_MIN" "$TARGET_DISK" "$DISK_SIZE_MiB" "$TMPFILE" || {
    echo "Disk creation failed, aborting..."
    exit 1
}

eval "$(cat "$TMPFILE")"
rm -f "$TMPFILE"

# Start module
echo ""
./modules/03_format_partitions.sh "$TARGET_DISK" "$USE_SWAP" || {
    echo "Formatting partitions failed, aborting..."
    exit 1
}

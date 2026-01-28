#!/bin/bash

 # Exit the script when any command inside fails
set -e

MOUNT_POINT="$1"
EFI_MOUNT_POINT_INSIDE="$2"
if [[ -z $MOUNT_POINT || -z $EFI_MOUNT_POINT_INSIDE ]]; then
    echo "Usage: $0 MOUNT_POINT EFI_MOUNT_POINT_INSIDE"
    exit 1
fi

# Check if the mount point is valid
if ! mountpoint -q "${MOUNT_POINT}"; then
    echo "Error: '$MOUNT_POINT' is not a valid mount point."
    exit 1
fi

if ! mountpoint -q "${MOUNT_POINT}${EFI_MOUNT_POINT_INSIDE}"; then
    echo "Error: '$EFI_MOUNT_POINT_INSIDE' is not a valid mount point."
    exit 1
fi
# Generate fstab
echo "Generating fstab for ${MOUNT_POINT}..."
genfstab -U "$MOUNT_POINT" >> "$MOUNT_POINT/etc/fstab" || {
    echo "genfstab failed, aborting..."
    exit 1
}
echo "fstab Generated successfully."

# Load package configs from packages.conf
echo "Loading configs..."
source "$(dirname "$0")/../packages.conf" || {
    echo "Error: Unable to load config files 'packages.conf'."
    exit 1
}

# Install a bootloader
declare -i SELECT
echo "Available bootloader:"
echo "1. GRUB"
echo "2. systemd-boot"
while true; do
    read -r -p "Select one: [1/2] " SELECT
    if [[ $SELECT -eq 1 ]]; then
        echo "GRUB will be installed."
        echo ""
        echo "Installing GRUB..."

        # Install related packages
        echo "Installing necessary packages..."
        arch-chroot "$MOUNT_POINT" pacman -S --noconfirm "${GRUB_PACKAGES[@]}" || {
            echo "Installing packages failed, aborting..."
            exit 1
        }
        
        echo "Running grub-install..."
        arch-chroot "${MOUNT_POINT}" grub-install --target=x86_64-efi --efi-directory="${EFI_MOUNT_POINT_INSIDE}" --bootloader-id=GRUB || {
            echo "grub-install failed, aborting..."
            exit 1
        }
        
        echo "Running grub-mkconfig..."
        arch-chroot "$MOUNT_POINT" grub-mkconfig -o /boot/grub/grub.cfg || {
            echo "grub-mkconfig failed, aborting..."
            exit 1
        }

        break
    elif [[ $SELECT -eq 2 ]]; then
        echo "systemd-boot will be installed."
        echo ""
        echo "Installing systemd-boot..."

        # Install related packages
        echo "Installing necessary packages..."
        arch-chroot "${MOUNT_POINT}" pacman -S --noconfirm "${SYSTEMD_BOOT_PACKAGES[@]}" || {
            echo "Installing packages failed, aborting..."
            exit 1
        }

        # bootctl install
        echo "Running bootctl install..."
        arch-chroot "${MOUNT_POINT}" bootctl install || {
            echo "bootctil install failed, aborting..."
            exit 1
        }
        
        # Configure loader.conf
        echo "Configuring loader.conf..."
        cat "$(dirname "$0")/../templates/loader.conf.tpl" > "${MOUNT_POINT}${EFI_MOUNT_POINT_INSIDE}/loader/loader.conf" || {
            echo "Copying configs to designated place failed, aborting..."
            exit 1
        }

        # Get UCODE_LINE
        UCODE_LINE=""
        if [[ -f "${MOUNT_POINT}${EFI_MOUNT_POINT_INSIDE}/intel-ucode.img" ]]; then
            echo "Intel ucode detected."
            UCODE_LINE="initrd /intel-ucode.img"
        elif [[ -f "${MOUNT_POINT}${EFI_MOUNT_POINT_INSIDE}/amd-ucode.img" ]]; then
            echo "AMD ucode detected."
            UCODE_LINE="initrd /amd-ucode.img"
        else
            echo "Warning: No ucode detected in ${EFI_MOUNT_POINT_INSIDE}."
        fi

        echo "Getting UUID for ROOT..."
        ROOT_UUID=$(findmnt -n -o UUID -M "${MOUNT_POINT}")
        if [[ -z "${ROOT_UUID}" ]]; then
            echo "Unable to get UUID for ROOT."
            exit 1
        fi

        echo "Creating boot entry arch.conf..."
        sed -e "s|@UCODE_LINE@|${UCODE_LINE}|g" \
            -e "s|@ROOT_UUID@|${ROOT_UUID}|g" \
            "$(dirname "$0")/../templates/arch.conf.tpl" > "${MOUNT_POINT}${EFI_MOUNT_POINT_INSIDE}/loader/entries/arch.conf" || {
                echo "Failed to create arch.conf entry."
                exit 1
            }

        echo "Boot entry created successfully."
        break
    fi
done

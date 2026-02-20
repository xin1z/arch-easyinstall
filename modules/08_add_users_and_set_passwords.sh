#!/bin/bash

 # Exit the script when any command inside fails
set -e

MOUNT_POINT="$1"

if [[ -z $MOUNT_POINT ]]; then
    echo "Usage: $0 MOUNT_POINT"
    exit 1
fi

# Check if the mount point is valid
if ! mountpoint -q "${MOUNT_POINT}"; then
    echo "Error: '$MOUNT_POINT' is not a valid mount point."
    exit 1
fi

echo "Setting root password..."
ROOT_PASSWORD=""
ROOT_PASSWORD_DOUBLE_CONFIRMATION=""
while true; do
    read -rs -p "Input root password (can't left blank): " ROOT_PASSWORD
    echo
    if [[ -n $ROOT_PASSWORD ]]; then
        break;
    fi
done

while true; do
    read -rs -p "Input again for double confirmation: " ROOT_PASSWORD_DOUBLE_CONFIRMATION
    echo
    if [[ $ROOT_PASSWORD_DOUBLE_CONFIRMATION == $ROOT_PASSWORD ]]; then
        echo "Root password confirmed."
        break;
    fi
    echo "Password mismatch."
done

arch-chroot "$MOUNT_POINT" chpasswd <<< "root:${ROOT_PASSWORD}" || {
    echo "Failed to set root password, aborting..."
    exit 1
}

echo "Root password set."
function add_user {
    local username=""
    local password=""
    local password_double_confirmation=""

    # Get username
    while true; do
        read -r -p "Input a username: " username
        if [[ $username =~ ^[a-z_][a-z0-9_-]*$ ]]; then
            if ! arch-chroot "${MOUNT_POINT}" id "${username}" &>/dev/null; then
                echo "${username} will be the username."
                break;
            fi
            echo "Username ${username} already exists."
        fi
    done

    # Get password
    while true; do
        read -rs -p "Input a password: " password
        echo
        if [[ -n $password ]]; then
            break;
        fi
        echo "password can't be blank, try again."
    done

    while true; do
        read -rs -p "Input again for double confirmation: " password_double_confirmation
        echo
        if [[ $password_double_confirmation == $password ]]; then
            echo "Password confirmed."
            break;
        fi
        echo "Password mismatch."
    done

    echo "Adding user..."
    arch-chroot "${MOUNT_POINT}" useradd -m -s /bin/bash "${username}" || {
        echo "Failed to add this user, aborting..."
        exit 1
    }
    echo "Setting password for ${username}..."
    arch-chroot "$MOUNT_POINT" chpasswd <<< "${username}:${password}" || {
        echo "Failed to set password, aborting..."
        exit 1
    }
    
    # Add user to certain groups
    while true; do
        local confirm=""
        read -r -p "Do you want to add this user to a group? (y/N): " confirm
        if [[ "${confirm}" == "N" || "${confirm}" == "n" || -z $confirm ]]; then
            break;
        fi

        while true; do
            local command=""
            read -r -p "Input a group name (input m to get all existing groups): " command
            if [[ $command == "m" ]]; then
                arch-chroot "${MOUNT_POINT}" getent group | cut -d: -f1 || {
                    echo "Failed to get existing groups, aborting..."
                    exit 1
                }
            elif arch-chroot "${MOUNT_POINT}" getent group "${command}" > /dev/null; then
                echo "Adding user ${username} to group ${command}..."
                arch-chroot "${MOUNT_POINT}" usermod -aG "${command}" "${username}" || {
                    echo "Failed to add user ${username} to group ${command}, aborting..."
                    exit 1
                }

                echo "User ${username} has been added to ${command}."
                break;
            else
                echo "Input can't be recognized, try again."
            fi
        done
    done
    
    echo "All done!"
}

# Ask for adding users
while true; do
    confirm=""
    read -r -p "Do you want to add a user? [y/n]: " confirm
    if [[ "${confirm}" == "Y" || "${confirm}" == "y" ]]; then
        add_user
    elif [[ "${confirm}" == "N" || "${confirm}" == "n" ]]; then
        break;
    fi
done

# Arch Easy-Install—an Archinstall Script with Automatic Detection and Installation for Drivers

![status](https://img.shields.io/badge/status-development-yellow)
![license](https://img.shields.io/badge/license-GPL--3.0-blue)

### Upcoming Features

1. Auto-configuration for PipeWire.
2. Auto-configuration for various major desktop environments.

### Introduction

Arch Easy-Install is an Archinstall script with automatic hardware detection and GPU driver installation. It's written fully in Bash.

Status: *In development*, not fully functional. Use with caution.

### What for?

This project aims to provide a modular, script-based Arch Linux installer that prioritizes predictability and transparency over full automation.

It isn't intended to replace the official `archinstall`, but to give users a more transparent installer. It is also not designed for beginners with no Linux experience.

### Features

Implemented:

* Automatically create, format and mount partitions (EFI, ROOT, SWAP) with recommended sizes.
* Automatically pacstrap base system and install CPU ucode.
* Automatically detect and install proper GPU drivers.
* Automatically configure fstab, install GRUB or systemd-boot after base system installation.
* Automatically configure NVIDIA proprietary drivers, related arguments and nvidia-prime.

Not Implemented yet:
* Automatically configure PipeWire.
* Automatically configure locale, add users and set password.
* Auto-install desktop environment.

### Requirements

* Arch Linux live environment
* `git` installed in the live environment

Install `git` if needed:

```bash
pacman -Sy git
```

### Installation

Clone the repository and run the script with the commands below:

```bash
git clone https://github.com/xin1z/arch-easyinstall.git
cd arch-easyinstall
chmod +x main.sh ./modules/*
./main.sh
```

Then, follow the interactive prompts to select the target disk, configure SWAP size, and confirm partitioning.

> Warning: This script will erase all data on the selected disk.

Or, since this is a modularized script, you can also choose to run those modular scripts in `modules/` seperately. Please run `./{script_name}.sh` to know the exact syntax.

## Usage (For now)

1. Select the target disk where you want to install the OS when prompted.
2. Confirm that you understand all data on the disk will be erased.
3. Optionally specify SWAP size, or use the recommended value.
4. The script will automatically create partitions and format them.
5. It will then mount them to `/mnt`, with EFI partition mounted to `/mnt/boot`, and pacstrap the base system.
6. The script will detect and install GPU drivers after base system installation.
7. It will run `genfstab`, install and configure GRUB or systemd-boot automatically.

More features will be added in future.

## License

This project is licensed under **GPL-3.0 License**.

* You are free to fork and distribute it under the same license.
* If you use any source code from this project, your project must also be open-source under GPL-3.0.

For full license details, see [GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.html).

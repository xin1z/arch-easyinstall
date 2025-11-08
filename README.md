# Arch Easy-Install - an Installation Script for Arch Linux with Automatic Hardware Detection and Driver Installation

![status](https://img.shields.io/badge/status-development-yellow)
![license](https://img.shields.io/badge/license-GPL--3.0-blue)

### Things I'm adding to this

1. Automatic hardware detection and driver installation.
2. Modularized scripts.
3. Auto-configuration for various major desktop environments.

### Introduction

Arch Easy-Install is an Arch Linux installation script with automatic hardware detection (not implemented yet) and driver installation (also not implemented...).

Status: *In development*, not fully functional. Use with caution.

### Features

Implemented:

* Automatic creation of partitions(EFI, ROOT, SWAP) with recommended sizes.

Not Implemented yet:

* Automatic detection of available disks and hardware.
* Automatic formatting and basic system installation.
* Optional driver installation after base system setup.

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

Or, since this is a modularized script, you can also choose to run those modular scripts in `modules/` seperately. For usage of specific script, run `./{script_name}.sh` to know the exact syntax.

## Usage (For now)

1. Select the target disk where you want to install the OS when prompted.
2. Confirm that you understand all data on the disk will be erased.
3. Optionally specify SWAP size, or use the recommended value.
4. the script will automatically create partitions and format them.

*etc.*

*And yeah, that's everything it can do for now. I'll implement other features in the future.*

## License

This project is licensed under **GPL-3.0 License**.

* You are free to fork and distribute it under the same license.
* If you use any source code from this project, your project must also be open-source under GPL-3.0.

For full license details, see [GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.html).

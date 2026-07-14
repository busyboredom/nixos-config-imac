# Deployment & Testing Guide

This document covers validating the configuration in a virtual machine and deploying it to the physical 2013 iMac.

## Part 1: Virtual Machine Testing

### Method A: Quick UI/Package Validation (VM Wrapper)

This method utilizes the `virtualisation.vmVariant` block to instantly compile and run a QEMU instance of your system without executing disk partitioning. It is ideal for verifying the COSMIC desktop and package list.

1. Navigate to the directory containing the flake.

2. Build the VM runner:

```bash
nix build .#nixosConfigurations.imac.config.system.build.vm
```

3. Execute the virtual machine:

```bash
./result/bin/run-imac-vm
```

### Method B: Full Deployment Simulation

To validate Disko formatting and SOPS secret decryption, you must simulate a bare-metal install.

- Spin up a VM in Virt-Manager/QEMU (UEFI boot, 4GB RAM).
- Change the `device = "/dev/sda";` in `disko.nix` to match the VM's block device (e.g., `/dev/vda`).
- Follow the bare-metal installation instructions below.

## Part 2: Creating the NixOS Live USB

### From Linux

1. Download the NixOS Graphical ISO from https://nixos.org/download.html
2. Identify your USB drive with `lsblk` (e.g., `/dev/sdb`)
3. Write the image:

```bash
sudo dd if=nixos-graphical-26.05.iso of=/dev/sdX bs=4M status=progress conv=fdatasync
```

> **Warning:** Use the whole disk device (e.g., `/dev/sdb`), not a partition (e.g., `/dev/sdb1`). This will erase all data on the USB drive.

### From macOS

1. Find the USB device: `diskutil list`
2. Unmount it: `diskutil unmountDisk diskN`
3. Write the image:

```bash
sudo dd if=~/Downloads/nixos-graphical-26.05.iso of=/dev/rdiskN
```

> Using `rdiskN` instead of `diskN` is significantly faster.

### From Windows

Download and use [Rufus](https://rufus.ie/) or [balenaEtcher](https://www.balena.io/etcher/) — select the ISO, select the USB drive, and click Flash.

### Booting from the USB on the iMac

1. Shut down the iMac completely.
2. Plug in a **wired USB keyboard** (Bluetooth keyboards may not connect in time).
3. Plug in the NixOS USB drive.
4. Press the power button, then immediately hold the **Option (⌥)** key.
5. The Startup Manager will appear showing all available boot volumes.
6. Select the orange drive icon labeled **EFI Boot** and click the arrow.

> The 2013 iMac has no T2 chip, so there are no restrictions on booting from external media.

## Part 3: Bare-Metal Installation (2013 iMac)

### Prerequisites

- Push the configuration repository to a remote Git host (GitHub, GitLab, etc.). This is a one-time step — the live USB will clone from it during installation.
- Ensure you have a wired ethernet connection, as the proprietary Wi-Fi drivers are not present on the standard Live USB.

### 1. Clone the Configuration

On the live USB, clone the repository:

```bash
nix-shell -p git --run "git clone https://github.com/youruser/imac.git"
```

### 2. Generate the Master Age Key

This key will be used to encrypt and decrypt your system secrets.

```bash
sudo mkdir -p /var/lib/sops-nix
sudo nix-shell -p rage --run "rage-keygen -o /var/lib/sops-nix/key.txt"
```

Copy the generated Public Key output — you will need it in the next step.

### 3. Configure SOPS

Edit `.sops.yaml` in the cloned repository. Uncomment `imac` and replace the placeholder with the public key from the previous step:

```yaml
keys:
  - &charlie_laptop age1rkqemt2zv5tfw8g5ld26uksgw2z5hxjulyy9f7cmnas67as845rq9n0lxt
  - &imac YOUR_GENERATED_PUBLIC_KEY_HERE
creation_rules:
  - path_regex: secrets/[^/]+\.yaml$
    key_groups:
      - age:
          - *charlie_laptop
          - *imac
```

### 4. Add the iMac Key to Secrets

Re-encrypt the secrets file so both your laptop and the iMac can decrypt it:

```bash
sops updatekeys secrets/secrets.yaml
```

Confirm when prompted. The secret values are unchanged — only the encryption metadata is updated.

> The restic password can be changed if desired, but must be set before Step 8 (`restic init`).

### 5. Disk Partitioning

Verify the physical disk identifier (`lsblk`, usually `/dev/sda` on this iMac) matches the `device` line in `disko.nix`.

```bash
sudo nix run github:nix-community/disko -- --mode disko /path/to/imac/disko.nix
```

### 6. Stage Decryption Keys

Copy the generated Age key to the newly formatted root partition so the system can decrypt secrets on its first boot.

```bash
sudo mkdir -p /mnt/var/lib/sops-nix
sudo cp /var/lib/sops-nix/key.txt /mnt/var/lib/sops-nix/key.txt
sudo chmod 600 /mnt/var/lib/sops-nix/key.txt
```

### 7. Execute Installation

```bash
sudo nixos-install --flake /path/to/imac#imac
```

Once finished, safely reboot the machine.

### 8. Initialize the Backup Repository

After booting into the new system, initialize the restic repository. The password has been securely materialized by sops-nix.

Ensure your external backup drive is mounted to `/mnt/backup-drive`:

```bash
sudo restic -r /mnt/backup-drive/restic-repo -p /run/secrets/restic/password init
```

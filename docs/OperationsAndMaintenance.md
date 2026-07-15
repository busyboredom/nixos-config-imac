# iMac NixOS: Operations & Maintenance

This document outlines the standard operating procedures for the end user of the iMac system.

## 1. Package Management Overview

NixOS supports two ways to install software:

- **Imperative (Flatpak):** You install and update applications by running commands or using COSMIC Store. This is the familiar app-store experience — apps appear and disappear as you choose them. Flatpak is used here because it sandboxes applications for security and gives access to a large catalog of desktop software without polluting the system configuration.

- **Declarative (/etc/nixos):** You declare packages in the configuration files and rebuild the system. The packages are then guaranteed to exist. This is useful when you want rigorous reproducibility — for example, all packages would be automatically installed if the system is ever reinstalled on a new computer. The tradeoff is that adding software requires editing configuration files and running a rebuild command.

## 2. Flatpak Application Management

The system provides the Flatpak runtime declaratively, but applications are managed imperatively to keep the system configuration clean of user-specific software states.

### Find and Install Applications

Applications can also be found and installed via **COSMIC Store**, the graphical Flatpak store included with the desktop. To search and install via CLI:

```bash
flatpak search spotify
flatpak install flathub com.spotify.Client
```

### Update Applications

```bash
flatpak update
```

## 3. Restoring Backups via Restic

The system automatically backs up `/home` daily. Steam game installations (`steamapps/`) are excluded — games are large and can be redownloaded as needed. Game saves stored outside this directory are still backed up.

### List Snapshots

```bash
sudo restic -r /var/lib/restic/backups -p /run/secrets/restic/password snapshots
```

### Restore from a Snapshot

1. Identify the ID of the snapshot you wish to restore (e.g., `a1b2c3d4`).

2. Restore data to a specific location:

```bash
sudo restic -r /var/lib/restic/backups -p /run/secrets/restic/password restore a1b2c3d4 --target /tmp/restore_dir
```

> It is recommended to restore to a temporary directory first, then manually move the required files back into `/home`, rather than overwriting the live directory directly.

### Manually Trigger a Backup

Backups run daily on a timer, but you can trigger one immediately (e.g., before a major change):

```bash
sudo systemctl start restic-backup-daily-home
```

### Delete a Snapshot

To remove a specific snapshot and reclaim space:

```bash
sudo restic -r /var/lib/restic/backups -p /run/secrets/restic/password forget <snapshot-id> --prune
```

### View Repository Size

```bash
sudo restic -r /var/lib/restic/backups -p /run/secrets/restic/password stats
```

### Adding New Exclusions

To exclude additional directories from future backups, edit `services/restic.nix` and add patterns to `exclude`, then rebuild. New exclusions only apply to future snapshots — existing snapshots retain the data until they expire.

### Offsite Backup

One external drive isn't enough if the iMac and the drive are in the same location (fire, theft, drive failure). To copy backups to a second drive stored elsewhere:

```bash
rsync -av /var/lib/restic/backups/ /mnt/second-drive/restic-repo/
```

### Manual

For full reference, see the [restic manual](https://restic.readthedocs.io/).

## 4. Changing Passwords

### User Account Password

To change the login password for the user account:

```bash
passwd
```

### Restic Backup Password

Changing the repository password requires updating both the physical restic repository and the SOPS encrypted configuration.

1. Change the password on the repository:

```bash
sudo restic -r /var/lib/restic/backups -p /run/secrets/restic/password key add
```

Follow prompts to add new password, then optionally remove the old key.

2. Update the SOPS configuration:

Navigate to the flake directory and edit the secrets file:

```bash
nix-shell -p sops --run "sops secrets/secrets.yaml"
```

Update the password field, save, and exit. Rebuild the system to apply the new secret.

### LUKS Disk Encryption Passphrase

The root partition is LUKS-encrypted. You are prompted for this passphrase every time the iMac boots.

Back up the LUKS header before making any changes — if it is corrupted, all data on the partition is lost:

```bash
sudo cryptsetup luksHeaderBackup /dev/sda2 --header-backup-file /path/to/backup/header-backup.img
```

To change the passphrase:

```bash
sudo cryptsetup luksChangeKey /dev/sda2
```

Enter the current passphrase, then the new one. To add a backup passphrase to a second LUKS slot:

```bash
sudo cryptsetup luksAddKey /dev/sda2
```

## 5. System Architecture Overview (For Tinkering)

- **NixOS & Flakes:** The entire system state (excluding `/home`) is derived deterministically from the `flake.nix` in your configuration repository. If you break the system, you can reboot into the previous generation via the bootloader.

- **COSMIC Desktop:** The graphical environment is provided by the COSMIC desktop, configured declaratively via `services.desktopManager.cosmic`. **COSMIC Store** is included for browsing and installing Flatpak applications.

- **Modular Configuration:** The system configuration is split into single-responsibility files under `programs/` and `services/`, all imported by `configuration.nix`. This keeps each concern isolated and easy to modify.

- **Disko, LUKS & BTRFS:** The disk is partitioned using Disko with LUKS encryption on the root partition. BTRFS subvolumes (`@root`, `@home`, `@nix`) sit inside the encrypted container. Because `/nix` and `/home` are separate subvolumes from `/`, you have the infrastructure to implement stateless root filesystems (Impermanence) in the future if desired.

- **Hardware Abstractions:** The Broadcom Wi-Fi requires proprietary drivers, and the NVIDIA Kepler GPU uses the open-source Nouveau driver (required for Wayland/COSMIC support). If this configuration is ported to a modern machine, the specific `boot.extraModulePackages` and `boot.extraModprobeConfig` blocks must be removed.

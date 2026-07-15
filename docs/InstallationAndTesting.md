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

## Part 2: Creating the Installation USB

### Build the ISO

On any machine with Nix installed:

```bash
git clone https://github.com/busyboredom/nixos-config-imac.git
cd nixos-config-imac
nix build .#nixosConfigurations.imacIso.config.system.build.isoImage
```

### Flash to USB

Identify your USB drive with `lsblk` (e.g., `/dev/sdb`), then:

```bash
sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress conv=fdatasync
```

> **Warning:** Use the whole disk device (e.g., `/dev/sdb`), not a partition (e.g., `/dev/sdb1`). This will erase all data on the USB drive.

### Boot from the USB on the iMac

1. Shut down the iMac completely.
2. Plug in a **wired USB keyboard** (Bluetooth keyboards may not connect in time).
3. Plug in the NixOS USB drive.
4. Press the power button, then immediately hold the **Alt** key.
5. The Startup Manager will appear showing all available boot volumes.
6. Select the orange drive icon labeled **EFI Boot** and click the arrow.

> The 2013 iMac has no T2 chip, so there are no restrictions on booting from external media.

### Log In

The ISO has two accounts:

| User | Password |
|------|----------|
| `user` | `changeme` |
| `root` | *(none — just press Enter)* |

## Part 3: Bare-Metal Installation (2013 iMac)

### 1. Connect WiFi

WiFi works out of the box on the custom ISO. Connect via:

```bash
nmtui
```

### 2. Generate a Rage Key

This key will be used to encrypt and decrypt your system secrets.

```bash
sudo mkdir -p /var/lib/sops-nix
sudo rage-keygen -o /var/lib/sops-nix/key.txt
```

Copy the generated Public Key output — you will need it in the next step.

### 3. Update SOPS Config

The flake is already at `/etc/nixos`. Edit `.sops.yaml` — uncomment `imac` and replace the placeholder with your public key:

```bash
sudo vim /etc/nixos/.sops.yaml
```

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

Then re-encrypt the secrets so both your laptop and the iMac can decrypt them:

```bash
sops updatekeys secrets/secrets.yaml
```

Confirm when prompted. The secret values are unchanged — only the encryption metadata is updated.

### 4. Partition the Disk

Verify the physical disk identifier (`lsblk`, usually `/dev/sda` on this iMac) matches the `device` line in `disko.nix`.

```bash
sudo disko --mode disko /etc/nixos/disko.nix
```

You will be prompted to set a LUKS passphrase. This passphrase is required every time the iMac boots — choose something you can type comfortably on a wired keyboard at startup.

### 5. Stage Decryption Keys

Copy the generated rage key to the newly formatted root partition so the system can decrypt secrets on its first boot.

```bash
sudo mkdir -p /mnt/var/lib/sops-nix
sudo cp /var/lib/sops-nix/key.txt /mnt/var/lib/sops-nix/key.txt
sudo chmod 600 /mnt/var/lib/sops-nix/key.txt
```

### 6. Install NixOS

```bash
sudo nixos-install --flake /etc/nixos#imac
```

Once finished, safely reboot the machine.

The restic backup repository is initialized automatically on the first daily backup run.

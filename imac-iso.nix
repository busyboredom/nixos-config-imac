{ config, pkgs, lib, self, ... }:

{
  disabledModules = [
    ./services/sops.nix
    ./services/restic.nix
  ];

  services.btrfs.autoScrub.enable = lib.mkForce false;

  # Use NetworkManager instead of wpa_supplicant
  networking.wireless.enable = lib.mkForce false;
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  # Copy flake to live system
  system.activationScripts.copyFlake = {
    text = ''
      rm -rf /etc/nixos
      mkdir -p /etc/nixos
      cp -r --no-preserve=mode ${self}/* /etc/nixos/
    '';
  };

  # No password on ISO
  users.users.root.hashedPassword = lib.mkForce null;

  # ISO settings
  isoImage.squashfsCompression = "zstd";
  networking.hostName = lib.mkForce "imac-live";
  hardware.enableAllFirmware = true;

  environment.systemPackages = with pkgs; [
    disko git vim rage sops ssh-to-age pciutils usbutils cryptsetup
  ];

  nixpkgs.config.allowUnfree = true;
}

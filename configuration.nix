{ config, pkgs, lib, ... }:

{
  imports = [
    ./boot.nix
    ./programs/steam.nix
    ./programs/firefox.nix
    ./programs/flatpak.nix
    ./programs/programs.nix
    ./services/sops.nix
    ./services/restic.nix
    ./services/nix.nix
    ./services/printing.nix
    ./disko.nix
  ];

  nixpkgs.config.allowUnfree = true;

  hardware.bluetooth.enable = true;

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = false;
    modesetting.enable = true;
    # The GTX 700M series (Kepler architecture) was dropped from mainline NVIDIA drivers; 470 is the last supported branch that provides hardware acceleration for this specific iMac
    package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
  };

  # Xbox One / Series X|S wireless + wired controllers (via Xbox Wireless Adapter); Xbox 360 coexistence via xpad-noone
  hardware.xone.enable = true;

  networking = {
    hostName = "imac";
    networkmanager.enable = true;
  };

  users.users.user = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "changeme";
  };

  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;
  environment.cosmic.excludePackages = with pkgs; [
    cosmic-player
  ];

  system.stateVersion = "26.05";

  # Compressed swap in RAM — fast and invisible; disk swap is too slow on a spinning HDD to be useful
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # Prevents hard lockups under memory pressure by killing runaway processes before the system becomes unresponsive
  systemd.oomd.enable = true;

  # Monthly scrub catches silent data corruption (bit rot) without user intervention
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
  };

  # Isolates hardware-specific configurations from the ephemeral QEMU test environment to prevent driver initialization failures during `nix build ...vm`
  virtualisation.vmVariant = {
    services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];
    boot.extraModulePackages = lib.mkForce [ ];
    boot.kernelModules = lib.mkForce [ ];
    boot.blacklistedKernelModules = lib.mkForce [ ];
    services.btrfs.autoScrub.enable = lib.mkForce false;
    virtualisation = {
      memorySize = 8192;
      cores = 4;
      resolution = { x = 1920; y = 1080; };
      diskSize = 20 * 1024;
    };
  };
}

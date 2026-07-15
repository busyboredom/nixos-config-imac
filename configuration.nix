{ pkgs, lib, ... }:

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
  # broadcom-sta is flagged insecure (CVE-2019-9501, CVE-2019-9502) but is the only driver that supports the BCM4360
  nixpkgs.config.allowInsecurePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "broadcom-sta" ];

  hardware.bluetooth.enable = true;

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];
  # nouveau is the only driver that supports Wayland (required by COSMIC) on this Kepler GPU; NvClkMode=15 forces pstate 0f (max performance) at boot
  boot.extraModprobeConfig = ''
    options nouveau config=NvClkMode=15
    options btusb enable_autosuspend=0
  '';

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

  system.stateVersion = "26.11";

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

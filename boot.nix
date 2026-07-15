{ config, ... }:

{
  # Apple firmware from this era expects standard EFI handoffs, bypassing the need for legacy bootloader payloads
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd.kernelModules = [ "applesmc" "applespi" "intel_lpss_pci" "spi_pxa2xx_platform" "kvm-intel" ];

    # The BCM4360 chipset lacks functional open-source firmware; these modules ensure the proprietary Broadcom STA driver binds successfully by preventing conflicts
    extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
    kernelModules = [ "wl" ];
    blacklistedKernelModules = [ "b43" "bcma" "ssb" "brcmfmac" "brcmsmac" ];
  };
}

{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # This identifier is highly volatile across different deployment environments (VM vs physical hardware)
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "1G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  # Segregating state, user data, and the immutable store into subvolumes enables independent rollback strategies and prevents store corruption during home directory restorations
                  subvolumes = {
                    "/@root" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" "autodefrag" ];
                    };
                    "/@home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" "autodefrag" ];
                    };
                    "/@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
{ lib, ... }:
{
  networking.firewall.allowedTCPPorts = [ 22 ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = lib.mkForce "prohibit-password";
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.user.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFRmbuv1yjL6me0M7L5kgxIv4BANZMv4fsGtNxHnggVs charlie@busyboredom.com"
  ];

  services.tor = {
    enable = true;
    relay.onionServices."ssh" = {
      map = [
        {
          port = 22;
          target = {
            addr = "127.0.0.1";
            port = 22;
          };
        }
      ];
    };
  };
}

{ config, ... }:

{
  services.restic.backups = {
    daily-home = {
      repository = "/var/lib/restic/backups";
      # Sops-nix manages permissions and creates a symlink in the run directory to prevent the raw string from leaking into the Nix store
      passwordFile = config.sops.secrets."restic/password".path;
      initialize = true;
      paths = [ "/home" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
      exclude = [ "**/steamapps/" ];
      # Mitigates local storage failure while preventing the remote repository from growing unboundedly over decades
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 12"
        "--keep-yearly 100"
      ];
    };
  };
}

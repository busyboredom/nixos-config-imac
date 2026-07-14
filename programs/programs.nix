{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    vlc         # media player
    rage        # age-compatible file encryption (sops-nix secret management)
  ];
}

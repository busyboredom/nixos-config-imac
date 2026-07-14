{
  # Age minimizes the dependency footprint for secret decryption compared to full GPG suites
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/var/lib/sops-nix/key.txt";
    secrets."restic/password" = {};
  };
}

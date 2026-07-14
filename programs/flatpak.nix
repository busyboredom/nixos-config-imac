{
  # Provides the Flatpak runtime and Flathub repository declaratively; applications are managed imperatively by the user
  services.flatpak = {
    enable = true;
    remotes = [{
      name = "flathub";
      location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    }];
  };
}

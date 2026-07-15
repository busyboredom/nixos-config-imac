{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      sops-nix,
      nix-flatpak,
      ...
    }@inputs:
    {
      nixosConfigurations.imac = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          nix-flatpak.nixosModules.nix-flatpak
          ./configuration.nix
        ];
      };

      nixosConfigurations.imacIso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit (inputs) self; };
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          disko.nixosModules.disko
          nix-flatpak.nixosModules.nix-flatpak
          ./configuration.nix
          ./imac-iso.nix
        ];
      };
    };
}

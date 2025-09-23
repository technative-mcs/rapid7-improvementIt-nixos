# Intro

This repo builds the closed source package rapid7 and creates two Nix modules:
- Package
- Service



# installation

1. Install it in the flake
```nix
{
  description = "Rapid7 on NixOs";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    rapid7.url = "github:technative-mcs/rapid7-nixos";
  };

  outputs = { self, nixpkgs, rapid7 }:
  {
    nixosConfigurations = {

      mysystem = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          rapid7.packages.${system}.default
          rapid7.nixosModules.${system}.default
        ];
        specialArgs = { inherit inputs; };
      };
    };
  };
}
```

2. Download certificates:
```bash
sudo /opt/rapid7/ir_agent/components/insight_agent/4.0.18.46/configure_agent.sh --token=<specifiy-token-here> -v --start --no_version_check
```

3. Then enable the ir_agent service:
```nix
{ ... }:
{
  services.rapid7 = {
    enable = true;
  };
}
```

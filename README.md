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
    rapid7.url = "github:technative-mcs/rapid7-improvementIt-nixos";
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

2. Then enable the ir_agent service:
```nix
{ ... }:
{
  services.rapid7 = {
    enable = true;
  };
}
```
The service won't work, if you don't do step 3.

3. Download the certificates by running this command on the remote server:
```bash
sudo /opt/rapid7/ir_agent/components/insight_agent/4.0.18.46/configure_agent.sh --token=<specifiy-token-here> -v --start --no_version_check
```


## errors

There is an issue that the files are not copied over to `/opt/rapid7/ir_agent` and thus the command won't work.
To fix it, run the following:
```bash
find /nix/store -name "*ir_agent*"
```

There will be many results but you need the first one, which looks like this:
```
/nix/store/ax8gh1qz2cxh6kf4bcqx9y45fhdl0aad-rapid7-insight-agent-4.0.18.46/opt/rapid7/ir_agent
```

Then to copy the files run:
```bash
cd /nix/store/ax8gh1qz2cxh6kf4bcqx9y45fhdl0aad-rapid7-insight-agent-4.0.18.46/opt/rapid7/ir_agent
cp -r . /opt/rapid7/ir_agent/
```



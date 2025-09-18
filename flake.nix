{
  description = "Rapid7 on NixOs";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; config.allowUnfree = true; config.cudaSupport= true; overlays = [  ];  });

    in
      {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
          {
          default =
            pkgs.callPackage ./default.nix { };
        });

      nixosModules = forAllSystems (system:
        {
          default =  import ./service.nix;
        });
    };
}

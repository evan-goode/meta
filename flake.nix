{
  description = "Prism Launcher Metadata generation scripts";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, pre-commit-hooks, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pythonPackages = pkgs.python311Packages;
      in {
        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              black.enable = true;
              nixfmt.enable = true;
            };
          };
        };
        devShells.default = pkgs.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          packages = (with pkgs; [
            (poetry2nix.mkPoetryEnv {
              projectDir = self;
              overrides = pkgs.poetry2nix.overrides.withDefaults (self: super: {
                cachecontrol = super.cachecontrol.overridePythonAttrs (old: {
                  buildInputs = (old.buildInputs or [ ]) ++ [ self.flit-core ];
                });
                editables = super.editables.overridePythonAttrs (old: {
                  buildInputs = (old.buildInputs or [ ]) ++ [ self.flit-core ];
                });
              });
            })
            poetry
            nixfmt
            black
          ]);
        };
      });
}

{
  description = "Declarative Development Environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devshell.flakeModule
        inputs.treefmt-nix.flakeModule
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem =
        {
          config,
          pkgs,
          ...
        }:
        {
          treefmt = {
            projectRootFile = "flake.nix";

            programs = {
              nixfmt.enable = true;
              black.enable = true;
              prettier.enable = true;
            };
          };

          devshells =
            let
              common = {
                packages = [ config.treefmt.build.wrapper ];
                commands = [
                  {
                    name = "fmt";
                    category = "utils";
                    help = "Format the entire project";
                    command = "treefmt";
                  }
                ];
              };
            in
            {
              nix = {
                name = "nix";
                imports = [ common ];
                packages = [
                  pkgs.nil
                  pkgs.nixfmt
                ];
              };

              python = {
                name = "python";
                imports = [ common ];
                packages = [
                  (pkgs.python313.withPackages (
                    ps: with ps; [
                      pandas
                      polars
                      jupyterlab
                      # openpyxl
                    ]
                  ))
                ];
              };

              nodejs = {
                name = "nodejs";
                imports = [ common ];
              };

              bun = {
                name = "bun";
                imports = [ common ];
              };
            };

          devShells.default = config.devShells.nix;
        };

      flake = {
      };
    };
}

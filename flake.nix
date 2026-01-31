{
  description = "Declarative Development Environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # To import an internal flake module: ./other.nix
        # To import an external flake module:
        #   1. Add foo to inputs
        #   2. Add foo as a parameter to the outputs function
        #   3. Add here: foo.flakeModule
        inputs.devshell.flakeModule
        inputs.treefmt-nix.flakeModule
      ];

      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.
        treefmt = {
          projectRootFile = "flake.nix";

          programs = {
            nixfmt.enable = true;
            black.enable = true;
            prettier.enable =true;
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
          in {
          nix = {
            name = "nix";
            imports = [ common ];
            packages = [
              pkgs.nil
              pkgs.nixfmt-rfc-style
            ];
          };

          python = {
            name = "python";
            imports = [ common ];
              packages = [
                (pkgs.python313.withPackages (ps: with ps; [
                  ipykernel
                  notebook
                  jupyterlab
                  pandas
                  numpy
                  openpyxl
                ]))
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
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
      };
    };
}

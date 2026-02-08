{
  description = "Neotest adapter for nix-unit testing framework";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        neotest-nix-unit = pkgs.vimUtils.buildVimPlugin {
          pname = "neotest-nix-unit";
          version = "0.1.0";
          src = ./.;
          doCheck = false;
        };
      in {
        packages.default = neotest-nix-unit;
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nix-unit
            neovim
            stylua
            lua54Packages.luacheck
          ];
        };
      }
    ) // {
      overlays.default = final: prev: {
        vimPlugins = prev.vimPlugins // {
          neotest-nix-unit = final.vimUtils.buildVimPlugin {
            pname = "neotest-nix-unit";
            version = "0.1.0";
            src = self;
            doCheck = false;
          };
        };
      };
    };
}

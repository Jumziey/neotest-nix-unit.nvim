# Legacy nix-build support
# For flake users, prefer using the flake directly
{ pkgs ? import <nixpkgs> {} }:

pkgs.vimUtils.buildVimPlugin {
  pname = "neotest-nix-unit";
  version = "0.1.0";
  src = ./.;
  doCheck = false;
}

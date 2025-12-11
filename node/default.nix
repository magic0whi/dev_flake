{pkgs, ...}: let
  _pkgs = pkgs.extend (final: prev: rec {
    nodejs = prev.nodejs;
    yarn = prev.yarn.override {inherit nodejs;};
  });
in _pkgs.mkShell {
  packages = with pkgs; [ node2nix nodejs nodePackages.pnpm yarn ];
  shellHook = ''
    echo "node `node --version`"
    exec zsh
  '';
}

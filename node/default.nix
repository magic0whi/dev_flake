{pkgs, ...}: let
  _pkgs = pkgs.extend (final: prev: rec {
    nodejs = prev.nodejs;
    yarn = prev.yarn.override {inherit nodejs;};
  });
in _pkgs.mkShell {
  packages = with pkgs; [nodejs nodePackages.pnpm yarn bun];
  shellHook = ''
    echo "node `node --version`"
  '';
}

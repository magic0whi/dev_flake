{pkgs, ...}: let
  _pkgs = pkgs.extend (final: prev: rec {
    nodejs = prev.nodejs;
    yarn = prev.yarn.override {inherit nodejs;};
  });
in _pkgs.mkShell {
  buildInputs = with pkgs; [nodejs pnpm yarn bun typescript-language-server];
  shellHook = ''
    echo "node `node --version`"
  '';
}

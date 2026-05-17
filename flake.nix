{
  description = "My nix develops";
  inputs = {
    # Pinned as of 2026-05-04 17:55, branch: nixos-unstable
    nixpkgs.url = "github:NixOS/nixpkgs/15f4ee454b1dce334612fa6843b3e05cf546efab";
    # Pinned as of 2026-05-16 00:09
    treefmt-nix = {
      url = "github:numtide/treefmt-nix/790751ff7fd3801feeaf96d7dc416a8d581265ba";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    nixpkgs,
    self,
    treefmt-nix,
    ...
  }: let
    supported_systems = ["aarch64-darwin" "x86_64-linux"];
    for_each_system = f:
      nixpkgs.lib.genAttrs supported_systems (system:
        f (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }));
    treefmt_eval = for_each_system (pkgs:
      treefmt-nix.lib.evalModule pkgs (_: {
        projectRootFile = "flake.nix"; # Used to find the project root
        programs.alejandra.enable = true;
      }));
  in {
    formatter = for_each_system (pkgs: treefmt_eval.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper);
    devShells = for_each_system (pkgs: let
      import_shell = dir: pkgs.callPackage dir {};
      c-cpp = import_shell ./c-cpp;
      cuda_unwrapped = import_shell ./cuda;
    in {
      default = let
        get_system = "$(nix eval --impure --raw --expr 'builtins.currentSystem')";
        for_each_dir = exec: ''
          for dir in */; do (
            cd "''$dir"
            ${exec}
          )
          done
        '';
        script = name: runtimeInputs: text:
          pkgs.writeShellApplication {
            inherit name runtimeInputs text;
            bashOptions = ["errexit" "pipefail"];
          };
      in
        pkgs.mkShellNoCC {
          name = "dev-default";
          buildInputs =
            [
              (script "build" [] ''
                SYSTEM=${get_system}
                ${for_each_dir ''
                  echo "Building ''$dir"
                  nix build ".#devShells.''$SYSTEM.default"
                ''}
              '')
              (script "check" [pkgs.nixfmt] (for_each_dir ''
                echo "Checking ''$dir"
                nix flake check --all-systems --no-build
              ''))
              (script "format" [pkgs.nixfmt] ''
                git ls-files '*.nix' | xargs nix fmt
              '')
              (script "check-formatting" [pkgs.nixfmt] ''
                git ls-files '*.nix' | xargs nixfmt --check
              '')
            ]
            ++ [self.formatter.${pkgs.stdenv.hostPlatform.system}];
        };
      inherit c-cpp;
      c = c-cpp;
      cpp = c-cpp;
      latex = import_shell ./latex;
      node = import_shell ./node;
      python = import_shell ./python;
      cuda = cuda_unwrapped.shell;

      pythonCuda = pkgs.mkShell {
        inputsFrom = [
          cuda_unwrapped.shell
          (cuda_unwrapped.cudaPkgs.callPackage ./python {
            pythonVersion = "3.13";
            extraPackages = ps: [ps.vllm];
          })
        ];
      };
    });
  };
}

{
  description = "My nix develops";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/4c1018dae018162ec878d42fec712642d214fdfa";
  outputs = {self, ...}@inputs: let
    supported_systems = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
    for_each_supported_system = f: ( # Provides `system` and `pkgs`
      inputs.nixpkgs.lib.genAttrs supported_systems (system: f {
        inherit system;
        pkgs = import inputs.nixpkgs {inherit system; config.allowUnfree = true;};
      })
    );
  in {
    formatter = for_each_supported_system ({pkgs, ...}: pkgs.nixfmt);
    devShells = for_each_supported_system ({system, pkgs}: let
      import_shell = dir: (import ./${dir} {inherit pkgs system;});
      c-cpp = import_shell "c-cpp";
      cuda_unwrapped = import_shell "cuda";
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
        script = name: runtimeInputs: text: pkgs.writeShellApplication {
          inherit name runtimeInputs text;
          bashOptions = ["errexit" "pipefail"];
        };
      in pkgs.mkShellNoCC {
        packages = [
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
        ++ [self.formatter.${system}];
      };
      inherit c-cpp;
      c = c-cpp;
      cpp = c-cpp;
      latex = import_shell "latex";
      node = import_shell "node";
      python = import_shell "python";
      cuda = cuda_unwrapped.shell;
      pythonCuda = pkgs.mkShell {
        inputsFrom = [
          cuda_unwrapped.shell
          (import ./python {
            inherit system;
            pkgs = cuda_unwrapped.cuda_pkgs;
            pythonVersion = "3.13";
            extraPackages = ps: [ps.vllm];
          })
        ];
      };
    });
  };
}

{pkgs, ...}: let
  /* Change this value ({major}.{min}) to update the Python virtual-environment version. When you do this, make sure
  * to delete the `.venv` directory to have the hook rebuild it for the new version, since it won't overwrite an
  * existing one. After this, reload the development shell to rebuild it. You'll see a warning asking you to
  * do this when version mismatches are present. For safety, removal should be a manual step, even if trivial.
  */
  version = "3.13";
  py_package = let
    # Construct a function to concatenate marjor and minor versions
    # nixpkgs doesn't have patch version included for package naming suffix
    serialize_ver = ver: pkgs.lib.pipe ver [ # Pipe these three funcs
      pkgs.lib.versions.splitVersion # e.g. 3.13.1 -> ["3" "13" "1"]
      (pkgs.lib.sublist 0 2) # e.g. ["3" "13" "1"] -> ["3" "13"]
      pkgs.lib.concatStrings # e.g. ["3" "13"] -> "313"
    ];
  in pkgs."python${serialize_ver version}";
in pkgs.mkShell {
  shellHook = ''
    python --version
    exec zsh
  '';
  venvDir = ".venv";
  postShellHook = ''
    venvVersionWarn() {
    	local venvVersion
    	venvVersion="$("$venvDir/bin/python" -c 'import platform; print(platform.python_version())')"

    	[[ "$venvVersion" == "${py_package.version}" ]] && return

    	cat <<EOF
      Warning: Python version mismatch: [$venvVersion (venv)] != [${py_package.version}]
      Delete '$venvDir' and reload to rebuild for version ${py_package.version}
      EOF
    }
    venvVersionWarn
  '';
  packages = with py_package.pkgs; [
    venvShellHook
    pip

    /* Add whatever else you'd like here. */
    requests paramiko scp chardet pyyaml ruamel-yaml flask
    # (let version = "2.3.2";
    # in flask.overrideAttrs (_: prev: {
    #   inherit version;
    #   src = fetchPypi {
    #     inherit (prev) pname;
    #     inherit version;
    #     hash = "sha256-KEx7jy9Yy3N/DPHDD9fq8Mz83hlgmdJOzt4/wgBapZ4=";
    #   };
    # }))
    # pkgs.basedpyright

    # pkgs.black
    /* or */
    # python.pkgs.black

    # pkgs.ruff
    /* or */
    # python.pkgs.ruff
  ];
}

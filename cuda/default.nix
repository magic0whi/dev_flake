{pkgs, system, ...}: let
  nvidiaPackage = pkgs.linuxPackages.nvidiaPackages.stable;
  # NOTE: May move to flake.nix if there is any dev environment has cuda variant
  cuda_pkgs = import pkgs.path {
    inherit system;
    config = {
      allowUnfree = true;
      cudaSupport =true;
      # Highly recommended to set this to your specific GPU architecture to avoid
      # compiling CUDA code for every GPU ever made.
      # e.g., "8.6" for Ampere (RTX 3000 series), "8.9" for Ada (RTX 4000 series)
      cudaCapabilities = ["8.6"];
      cudaForwardCompat = false;
    };
  };
in {
  inherit cuda_pkgs; # Export for pythonCuda
  shell = pkgs.mkShell {
    # TIPS: to locate a missing lib, try
    # `nix run github:nix-community/nix-index-database#nix-locate -- "libX11.so.6"`
    buildInputs = with cuda_pkgs; [
      fmt.dev
      cudaPackages.cuda_nvcc
      # cudaPackages.cuda_cudart
      # cudatoolkit
      # nvidiaPackage
      # cudaPackages.cudnn
      # libGLU
      # libGL
      # freeglut
      # zlib
      # ncurses
      stdenv.cc.cc.lib
      libX11
      # stdenv.cc
      # binutils
      # uv
    ];
    shellHook = ''
      export LD_LIBRARY_PATH="${nvidiaPackage}/lib:${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.libx11}/lib:$LD_LIBRARY_PATH"
      export CUDA_PATH=${pkgs.cudatoolkit}
      export EXTRA_LDFLAGS="-L/lib -L${nvidiaPackage}/lib"
      export EXTRA_CCFLAGS="-I/usr/include"
      export CMAKE_PREFIX_PATH="${pkgs.fmt.dev}:$CMAKE_PREFIX_PATH"
      export PKG_CONFIG_PATH="${pkgs.fmt.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"
    '';
  };
}

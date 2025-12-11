{pkgs, ...}: (pkgs.mkShell.override {
  # Override stdenv in order to change compiler:
  # stdenv = pkgs.clangStdenv;
} {
  packages = with pkgs; [
    llvmPackages.clangUseLLVM
    llvmPackages.bintools
    clang-tools
    cmake
    ninja
    # codespell
    # conan
    # cppcheck
    # doxygen
    # gtest
    # lcov
    # vcpkg
    # vcpkg-tool
  ]
  ++ (if system == "aarch64-darwin" then [] else [gdb]);
  shellHook = ''
    echo "------ gcc -----";
    gcc --version
    echo "------ ld ------"
    ld -v
    exec zsh
  '';
})

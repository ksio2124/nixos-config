_: let
  # Quadro P400 (Pascal, compute capability 6.1). CUDA 13 dropped Pascal, so
  # this stays on the nixpkgs default (12.x) and only sets the capability.
  nixpkgsCuda = {
    nixpkgs.config.cudaSupport = true;
    nixpkgs.config.cudaCapabilities = ["6.1"];
    nixpkgs.overlays = [
      # CUDA onnxruntime pulls cuDNN >= 9.12, which requires capability 7.5+,
      # breaking firefox (and forcing it to build from source).
      (final: prev: {
        onnxruntime =
          (import prev.path {
            system = prev.stdenv.hostPlatform.system;
            config.allowUnfree = true;
          }).onnxruntime;
      })
    ];
  };
in {
  flake.nixosModules.cuda = {
    imports = [nixpkgsCuda];
    nix.settings = {
      extra-substituters = ["https://cache.nixos-cuda.org"];
      extra-trusted-public-keys = ["cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="];
    };
  };

  flake.homeModules.homeCuda = nixpkgsCuda;
}

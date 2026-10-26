_: let
  # Quadro P400 (Pascal, compute capability 6.1). CUDA 13 dropped Pascal, so
  # pin the toolkit to the last CUDA series supporting this GPU.
  nixpkgsCuda = {
    nixpkgs.config.cudaSupport = true;
    nixpkgs.config.cudaCapabilities = ["6.1"];
    nixpkgs.overlays = [
      (final: prev: {
        # Default for all packages using cudaPackages, in both NixOS and
        # Home Manager. Explicit versioned CUDA dependencies remain explicit.
        cudaPackages = final.cudaPackages_12_9;

        # CUDA onnxruntime pulls cuDNN >= 9.12, which requires capability 7.5+,
        # breaking firefox (and forcing it to build from source).
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

{inputs, pkgs}: let
  # The current patchelf corrupts the prebuilt Node fallback. Keep this
  # workaround local to OpenClaw and retain upstream's runtime install check.
  # TODO: Recheck after updating nixpkgs or nix-openclaw in flake.lock:
  # [ ] Check whether nixpkgs meets OpenClaw's Node version requirement and
  #     upstream has stopped selecting the prebuilt fallback (currently 24.22.1).
  # [ ] If the fallback is still selected, build it with the default patchelf
  #     and confirm upstream's Node/npm install check passes without this pin.
  # [ ] Build the unmodified upstream openclaw-gateway and run its --version
  #     command; then build Themis with that package selected.
  # [ ] Once those checks pass, restore inputs.nix-openclaw.packages in
  #     _openclaw-guest.nix and remove this helper and its patchelf pin.
  nodePatchelf = pkgs.patchelf.overrideAttrs {
    version = "0.15.2";
    src = pkgs.fetchurl {
      url = "https://github.com/NixOS/patchelf/releases/download/0.15.2/patchelf-0.15.2.tar.bz2";
      hash = "sha256-F3RfVkFZyOIo/EEtplogSLhGxLa0Igt3y/IkFuAvLXw=";
    };
  };
  upstreamNode = pkgs.callPackage "${inputs.nix-openclaw}/nix/packages/nodejs-24.nix" {};
  nodeRuntime =
    if upstreamNode.dontBuild or false
    then upstreamNode.overrideAttrs (old: {
      preFixup = (old.preFixup or "") + ''
        export PATH="${nodePatchelf}/bin:$PATH"
      '';
    })
    else upstreamNode;
in
  import "${inputs.nix-openclaw}/nix/packages" {
    pkgs = pkgs.extend (_final: _prev: {nodejs_24 = nodeRuntime;});
  }

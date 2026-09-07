{
  inputs,
  self,
  ...
}: {
  flake.homeConfigurations."jack@themis" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    modules = [
      self.homeModules."homeJack@themis"
    ];
  };

  flake.homeModules."homeJack@themis" = {
    pkgs,
    lib,
    ...
  }: {
    # pkgs
    imports = [
      self.homeModules.homeEditor
      self.homeModules.homeShell
      self.homeModules.homeSystem_tools
      self.homeModules.homeDevelopment
      self.homeModules.homeInternet_browsers
      self.homeModules.homeGnome
      self.homeModules.homeGames
      self.homeModules.homeOpencode
      inputs.sops-nix.homeManagerModules.sops
      # import homeModules here
    ];

    nixpkgs.overlays = [inputs.nur.overlays.default];

    sops.defaultSopsFile = ../../hosts/themis/secrets/config.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.age.sshKeyPaths = ["/home/jack/.ssh/themis"];
    sops.age.keyFile = "/home/jack/.config/sops/age/keys.txt";
    sops.age.generateKey = true;

    home = {
      username = "jack";
      homeDirectory = "/home/jack";
    };
    programs.zellij.enable = true;

    # services.sunshine (system module) registers its systemd *user* unit
    # globally — every user's systemd instance sees it, including
    # gdm-greeter's own graphical session on seat1, which was auto-starting
    # a second copy of this exact same primary sunshine.conf and colliding
    # on all its ports. autoStart is off system-wide; explicitly enable it
    # for jack only, here. Plain enable-symlink to the already-installed
    # system unit (/etc/systemd/user/sunshine.service), created at
    # activation time since the target path only exists on the real
    # machine (can't be a home.file source — that requires reading the
    # path during nix eval, which is impure). Home-manager's
    # systemd.user.services option was tried first and errors ("bad unit
    # file setting") when given only Install.WantedBy with no Service/Unit
    # sections of its own.
    home.activation.enableSunshineForJack = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "$HOME/.config/systemd/user/graphical-session.target.wants"
      ln -sf /etc/systemd/user/sunshine.service \
        "$HOME/.config/systemd/user/graphical-session.target.wants/sunshine.service"
    '';

    home.stateVersion = "25.05";
  };
}

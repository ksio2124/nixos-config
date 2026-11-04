{
  inputs,
  self,
  ...
}: {
  flake.homeConfigurations."jack@geodude" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.aarch64-linux;
    modules = [self.homeModules."homeJack@geodude"];
  };

  flake.homeModules."homeJack@geodude" = {...}: {
    imports = [
      self.homeModules.homeEditor
      self.homeModules.homeShell
      self.homeModules.homeDevelopment
      self.homeModules.homeSystem_tools
      self.homeModules.homeOpencode
    ];

    home.username = "jack";
    home.homeDirectory = "/home/jack";
    # The shared AI-tools module configures Codex/Claude; enable OpenCode too.
    programs.opencode.enable = true;

    home.stateVersion = "26.11";
  };
}

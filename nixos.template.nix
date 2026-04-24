{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.template = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.hostTemplate
    ];
  };
  flake.nixosModules.hostTemplate = {
    config,
    pkgs,
    ...
  }: {
    sops.secrets."nextcloud/adminpass" = {};
    containers.nextcloud = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.0.0.5";
      localAddress = "10.0.0.6";
      bindMounts."/run/secrets/nextcloud/adminpass" = {
        hostPath = config.sops.secrets."nextcloud/adminpass".path;
      };
      bindMounts."/mypool/nextcloud/" = {
        hostPath = "/mypool/nextcloud/";
        isReadOnly = false;
      };
      config = {
        config,
        pkgs,
        ...
      }: {
      };
    };
  };
}

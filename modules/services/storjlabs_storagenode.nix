{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.storjlabs_storagenode = {
    pkgs,
    config,
    ...
  }: {
    # sops.secrets."nextcloud/adminpass" = {};
    # sops.secrets."storjlabs_storagenode/identity/ca.key" = {};
    # 1. Enable Podman and set it as the backend
    virtualisation.podman.enable = true;
    virtualisation.oci-containers.backend = "podman";

    # 2. Define the Storj container
    virtualisation.oci-containers.containers."storjlabs_storagenode" = {
      image = "docker.io/storjlabs/storagenode:latest";
      autoStart = true;

      # Environment variables (equivalent to -e SETUP="true")
      # Note: Storj requires SETUP="true" only for the first run
      # Ports
      ports = [
        "28967:28967/tcp"
        "28967:28967/udp"
        "127.0.0.1:14002:14002"
      ];
      environment = {
        WALLET = "0x8ed60bdE294c119fEB7C03Bbb9b392C14696Ebde";
        EMAIL = "ksio2124@protonmail.ch";
        ADDRESS = "cowgoesmoopiggoesoink.com:28967";
        STORAGE = "2TB";
      };

      # Mounts (equivalent to --mount type=bind)
      # Replace /path/to/... with your actual host paths
      volumes = [
        # config.sops.secrets."storjlabs_storagenode/identity/ca.key".path
        "/mypool/storjlabs_storagenode/identity:/app/identity:z"
        "/mypool/storjlabs_storagenode/config:/app/config:z"
      ];

      # Equivalent to --user $(id -u):$(id -g)
      # On NixOS, services typically run as root, but you can specify
      # extra options to map the container user to your host user.
      extraOptions = [
        "--user=1000:100" # Replace with your actual UID/GID (run 'id' to check)
        "--userns=keep-id" # Keeps file ownership consistent with host user
      ];
    };
  };
}

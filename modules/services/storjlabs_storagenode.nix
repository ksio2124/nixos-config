{
  inputs,
  self,
  ...
}: {
  flake.homeModules.storjlabs_storagenode = {pkgs, ...}: {
    # 1. Enable Podman and set it as the backend
    virtualisation.podman.enable = true;
    virtualisation.oci-containers.backend = "podman";

    # 2. Define the Storj container
    virtualisation.oci-containers.containers."storagenode" = {
      image = "docker.io/storjlabs/storagenode:latest";
      autoStart = true;

      # Environment variables (equivalent to -e SETUP="true")
      # Note: Storj requires SETUP="true" only for the first run
      environment = {
        SETUP = "true";
      };

      # Mounts (equivalent to --mount type=bind)
      # Replace /path/to/... with your actual host paths
      volumes = [
        "/home/youruser/storj/identity:/app/identity"
        "/mnt/storj-data:/app/config"
      ];

      # Equivalent to --user $(id -u):$(id -g)
      # On NixOS, services typically run as root, but you can specify
      # extra options to map the container user to your host user.
      extraOptions = [
        "--user=1000:1000" # Replace with your actual UID/GID (run 'id' to check)
        "--userns=keep-id" # Keeps file ownership consistent with host user
      ];
    };
  };
}

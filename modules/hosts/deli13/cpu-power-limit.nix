_: {
  flake.nixosModules.hostDeli13 = {
    lib,
    pkgs,
    ...
  }: let
    controller = "${pkgs.python3}/bin/python3 ${./_cpu-power-limit.py}";
  in {
    systemd.services.dell-cpu-power-limit = {
      description = "XPS 9370 25 W sustained CPU package power";
      wantedBy = ["multi-user.target"];
      after = [
        "systemd-modules-load.service"
        "power-profiles-daemon.service"
        "dell-fan-control.service"
      ];
      # Stop the raised limit if the custom fan controller stops or fails.
      bindsTo = ["dell-fan-control.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${controller} --apply";
        ExecStopPost = "${controller} --restore";
        TimeoutStartSec = 40;
        TimeoutStopSec = 40;
      };
    };

    powerManagement.powerDownCommands = lib.mkBefore ''
      ${pkgs.systemd}/bin/systemctl stop dell-cpu-power-limit.service
    '';
    powerManagement.resumeCommands = lib.mkAfter ''
      ${pkgs.systemd}/bin/systemctl start dell-cpu-power-limit.service
    '';
  };
}

_: {
  flake.nixosModules.hostDeli13 = {pkgs, ...}: let
    controller = "${pkgs.python3}/bin/python3 ${./_fan-control.py}";
  in {
    boot.kernelModules = ["dell-smm-hwmon"];

    systemd.services.dell-fan-control = {
      description = "XPS 9370 CPU temperature fan curve";
      wantedBy = ["multi-user.target"];
      after = ["systemd-modules-load.service"];
      serviceConfig = {
        ExecStart = controller;
        # Also runs after crashes, watchdog kills, and failed startup.
        ExecStopPost = "${controller} --restore";
        Restart = "on-failure";
        RestartSec = 5;
        WatchdogSec = 15;
        TimeoutStopSec = 5;
      };
    };

    # Give firmware control during sleep, then discover sensors again on resume.
    powerManagement.powerDownCommands = ''
      ${pkgs.systemd}/bin/systemctl stop dell-fan-control.service
    '';
    powerManagement.resumeCommands = ''
      ${pkgs.systemd}/bin/systemctl start dell-fan-control.service
    '';
  };
}

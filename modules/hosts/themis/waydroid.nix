{...}: {
  flake.nixosModules.hostThemis = {pkgs, ...}: let
    mediaRoot = "/home/jack/.local/share/waydroid/data/media/0/Movies";
    folders = {
      VerifiedSplits = "/mypool/google-photos-split/upload-ready";
    };
    mountUnits = map (name: "home-jack-.local-share-waydroid-data-media-0-Movies-${name}.mount") (builtins.attrNames folders);
  in {
    virtualisation.waydroid.enable = true;

    systemd.mounts = map (name: {
      what = folders.${name};
      where = "${mediaRoot}/${name}";
      type = "none";
      options = "bind,ro";
      wantedBy = ["multi-user.target"];
      before = ["waydroid-container.service"];
      unitConfig.RequiresMountsFor = folders.${name};
    }) (builtins.attrNames folders);

    systemd.services.waydroid-container = {
      requires = mountUnits;
      after = mountUnits;
    };

    # Android's FUSE view needs the mounts made inside its namespace as well.
    systemd.services.waydroid-verified-media = {
      description = "Expose verified movie splits to Android and refresh MediaStore";
      after = ["waydroid-container.service"] ++ mountUnits;
      requisite = mountUnits;
      path = [pkgs.waydroid pkgs.gnugrep];
      serviceConfig = {
        Type = "oneshot";
        TimeoutStartSec = "15min";
        RuntimeDirectory = "waydroid-verified-media";
        RuntimeDirectoryPreserve = true;
      };
      script = ''
        if [ "$(waydroid shell getprop sys.boot_completed 2>/dev/null)" != 1 ]; then
          exit 0
        fi
        for folder in VerifiedSplits; do
          ready=$(waydroid shell -- sh -eu -c '
            source=/data/media/0/Movies/'"$folder"'
            target=/mnt/pass_through/0/emulated/0/Movies/'"$folder"'
            test -d "$source"
            test -d "$target"
            if ! grep -q " $target " /proc/mounts; then
              mount -o bind,ro "$source" "$target"
            fi
            test -n "$(find "$target" -type f -print -quit)"
            echo ready
          ')
          test "$ready" = ready
        done
        session=$(waydroid shell -- cut -d ' ' -f 22 /proc/1/stat)
        case "$session" in ""|*[!0-9]*) exit 1;; esac
        stamp=/run/waydroid-verified-media/scanned-session
        if [ -f "$stamp" ] && [ "$(cat "$stamp")" = "$session" ]; then
          exit 0
        fi
        result=$(waydroid shell -- content call --uri content://media --method scan_volume --arg external_primary 2>&1)
        printf '%s\n' "$result" | grep -q '^Result:'
        printf '%s\n' "$session" > "$stamp"
      '';
    };
    systemd.timers.waydroid-verified-media = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "10min";
        OnUnitActiveSec = "10min";
      };
    };
  };
}

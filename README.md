# nixos-config

My personal NixOS and Home Manager configurations for machines, development
environments, and self-hosted services. This repository keeps system settings,
applications, and user environments in version control so I can rebuild them,
share configuration between machines, and track how my setup changes over time.

It uses Nix flakes, flake-parts, and import-tree to organize reusable modules.
Nixpkgs follows `nixos-unstable`; `flake.lock` records the selected input revisions.
Home Manager also manages a standalone user environment on a non-NixOS machine.

## Configurations

| Flake output | Platform | Purpose |
| --- | --- | --- |
| `nixosConfigurations.deli13` | `x86_64-linux` | NixOS Plasma desktop for deli13 |
| `nixosConfigurations.themis` | `x86_64-linux` | NixOS host with routing, storage, and self-hosted services |
| `nixosConfigurations.xieshi` | `x86_64-linux` | NixOS host with desktop and device configuration |
| `homeConfigurations."jack@deli13"` | `x86_64-linux` | User applications and development environment for deli13 |
| `homeConfigurations."jack@themis"` | `x86_64-linux` | User applications and development environment for themis |
| `homeConfigurations."jack@xieshi"` | `x86_64-linux` | User applications and development environment for xieshi |
| `homeConfigurations."droid@pixy-vm"` | `aarch64-linux` | Standalone Home Manager environment for droid |

## Repository layout

- `flake.nix` and `flake.lock`: dependencies and flake output composition.
- `modules/hosts/`: machine-specific NixOS settings, hardware, networking, and storage.
- `modules/home/`: per-user Home Manager configurations.
- `modules/services/`: reusable service definitions, including Nextcloud, Immich,
  Garage, PostgreSQL, mail, and OpenClaw. See the
  [service networking notes](modules/services/README.md) for address allocations.
- `modules/*.nix`: shared configuration for shells, editors, development tools,
  browsers, desktop applications, and Nix itself.
- `home.template.nix` and `nixos.template.nix`: starting points for new configurations;
  review and adapt their contents before use.

Files under `modules/` are discovered by import-tree. They export named
`flake.nixosModules` or `flake.homeModules`, which host and user configurations
compose through their `imports` lists. Defining a service module does not by itself
enable that service on every host.

## Building and applying

Run these commands from the repository root with Nix flakes enabled. Choose the
configuration for the target machine and use a compatible builder for its platform.
These configurations contain machine-specific hardware, paths, and accounts.

Build a NixOS configuration before applying it:

```sh
nixos-rebuild build --flake .#themis
```

After reviewing the build, explicitly switch on the intended NixOS host:

```sh
sudo nixos-rebuild switch --flake .#themis
```

For a standalone Home Manager environment, with `home-manager` installed:

```sh
home-manager build --flake '.#droid@pixy-vm'
# Apply after reviewing the build:
home-manager switch --flake '.#droid@pixy-vm'
```

Substitute `xieshi`, `jack@themis`, or `jack@xieshi` as appropriate. Build commands
do not activate a generation; switch commands change the running system or user
environment. When working through an agent, switching requires explicit approval.
New files referenced by a Git-backed flake must be added to Git before building.

## Making changes

Inspect the relevant host or user configuration and shared module first. Put
machine-specific settings in that machine's configuration and reusable settings in
a shared module, following the existing structure and formatting. Build the affected
configuration before switching it.

Secrets are managed with sops-nix and age. Activation of secret-backed services
requires the appropriate decryption keys on the target machine. Never commit
plaintext credentials or private keys. Agent work must not read or expose
`modules/hosts/*/secrets/` or `.env` files.

## deli13 TODO

- [x] Set up Lanzaboote for Secure Boot.
- [x] Configure encrypted swap and zswap.
- [x] Move swap onto persistent storage when setting up Preservation.
- [x] Set up preservation.
- [x] Keep `/tmp` and `/var/tmp` on the encrypted SSD using persistent bind mounts, with mode `1777` and `boot.tmp.useTmpfs = false`.
- [x] Keep `/home` persistent, including `/home/jack/.cache`, and `/nix` on disk.
- [x] Configure age-based cleanup for persistent temporary directories.

See [deli13 Preservation setup and recovery](modules/hosts/deli13/PRESERVATION.md)
for the filesystem layout, validation commands, and recovery instructions.

### CPU performance profile and fan control — 2026-11-03

Target: Dell XPS 13 9370, Intel Core i5-8250U / UHD 620, BIOS 1.21.0.

- [x] Add and activate the Dell-specific [fan controller](modules/hosts/deli13/fan-control.nix), using CPU package temperature and both fans.
- [x] Configure fan hysteresis: low at 55°C, high at 70°C, back to low below 62°C, and off below 48°C. Observed speeds are approximately 4,400 / 7,000 RPM.
- [x] Add BIOS-control restoration on service stop/failure, a watchdog, stalled-fan detection, and suspend/resume hooks. Simulated failure tests and the NixOS build passed; live fan transitions were verified.
- [x] Record CPU/GPU benchmarks and diagnose the sustained CPU power cap: MSR PL1 reports 27 W, but the separate enabled MMIO PL1 is 15 W, with an approximately 28-second window. Both report a 51 W burst limit.
- [x] Test a temporary 18 W MMIO PL1 setting and restore 15 W afterward. The setting held during the test; settled power increased from 14.78 to 17.86 W, effective clocks from 2.65 to 2.83 GHz, and throughput from 2,212 to 2,364 events/s (about 7%). Settled peak temperature increased from 67°C to 73°C, with no active thermal/current-limit flags in that window. The initial burst peaked at 90°C during the 18 W trial.
- [x] Add a persistent [25 W MMIO sustained limit](modules/hosts/deli13/cpu-power-limit.nix), as requested on 2026-11-04 after testing fresh MX-4. Apply at boot and resume, verify readback, and restore 15 W on service stop/failure. Stop the raised limit if the custom fan controller stops. BIOS, voltage, MSR limits, and burst limits are unchanged.
- [ ] Add selectable 15 W / enhanced performance profiles coordinated with power-profiles-daemon. The current fixed 25 W configuration applies on both AC and battery, independently of the selected desktop power profile.
- [ ] Verify power-limit write/readback, firmware overrides, reboot and suspend/resume behavior, and restoration on service failure. Avoid repeatedly fighting firmware if it rejects a setting.
- [ ] Validate the fan controller's real suspend/resume, restart, and BIOS-fallback behavior; tune noise and temperature thresholds against sustained workloads if needed.
- [ ] Run longer CPU and combined CPU/GPU tests with temperatures, actual package watts, effective clocks, fan RPM, and active limit flags recorded. Compare repeated runs under matching conditions before choosing a persistent limit or testing a higher one.
- [ ] Build-check the profile configuration and obtain explicit approval before switching generations. Document profile selection, rollback, and benchmark results.

The declarative CPU setting is **25 W** and was activated on 2026-11-04.
The service applies it once at startup and resume; it does not
continuously override firmware changes. To return temporarily to 15 W after
activation, run `sudo systemctl stop dell-cpu-power-limit`; to reapply 25 W, run
`sudo systemctl start dell-cpu-power-limit`. Removing the module and rebuilding
returns to the factory baseline. The custom fan curve remains configured.

Benchmark scripts, raw results, and reports are saved locally under
`/home/jack/benchmarks/`, including `power-20261103-154106/REPORT.md` (15 W)
and `power-20261103-154731/REPORT.md` (18 W). These artifacts are outside this
repository. The 18 W result is a short CPU-only experiment, not a long stability
or battery-life validation. Fresh MX-4 results are in
`power25-alltemps-20261104-103904/REPORT.md` (25 W: 86.8°C final-minute CPU
average, 92°C overall peak) and `power22-alltemps-20261104-104839/REPORT.md`
(matched 22 W paste comparison). These short CPU-only tests do not validate
continuous motherboard regulator temperatures or battery operation.
The later stress run `stress25-hwthrottle-20261104-110241/` reached 99°C during
the initial load, recorded thermal throttling, and averaged 91.3°C in its final
minute before being stopped manually after about 222 seconds. The persistent
25 W setting remains selected; longer-load thermal behavior is not validated.
No custom BIOS is needed for the tested power-limit change.

## Inspiration

- [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs)
- [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config/tree/i3-kickstarter/users)

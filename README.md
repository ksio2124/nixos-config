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
| `nixosConfigurations.themis` | `x86_64-linux` | NixOS host with routing, storage, and self-hosted services |
| `nixosConfigurations.xieshi` | `x86_64-linux` | NixOS host with desktop and device configuration |
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

## Inspiration

- [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs)
- [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config/tree/i3-kickstarter/users)

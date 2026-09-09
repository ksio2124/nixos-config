# br-isolated IPv6 address allocations

Bridge `br-isolated` (defined in `modules/hosts/themis/router.nix`) uses the
`fdcf:4b47:cf30::/64` ULA prefix. Each container gets a static `localAddress6` on this
bridge. Allocated addresses:

| Address              | Container    | Module                                |
|-----------------------|--------------|----------------------------------------|
| `fdcf:4b47:cf30::10`  | postgresql   | `modules/services/postgresql.nix`     |
| `fdcf:4b47:cf30::11`  | nextcloud    | `modules/services/nextcloud.nix`      |
| `fdcf:4b47:cf30::12`  | onlyoffice   | `modules/services/onlyoffice.nix`     |
| `fdcf:4b47:cf30::13`  | immich       | `modules/services/immich.nix`         |
| `fdcf:4b47:cf30::17`  | garage       | `modules/services/garage.nix`         |
| `fdcf:4b47:cf30::18`  | mosquitto    | `modules/services/mosquitto.nix`      |
| `fdcf:4b47:cf30::19`  | headscale    | `modules/services/headscale.nix`      |

When adding a new container service, pick the next unused address and add a row here.

(`::14`-`::16` are not currently allocated to any container.)

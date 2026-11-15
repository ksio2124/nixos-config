#!/usr/bin/env bash
set -euo pipefail

# Temporary workaround for Savannah's old cgit endpoint failing downloads.
# Keep the filenames, revision and hashes identical to pinned nixpkgs so its
# fetchurl derivations can reuse these files without a package override.
# TODO: Remove this script once upstream downloads work reliably; see TODO.md.
rev=948ae97ca5703224bd3eada06b7a69f40dd15a02
mirror=https://cgit.git.savannah.gnu.org/cgit/config.git/plain
download_dir=$(mktemp -d)
trap 'rm -rf -- "$download_dir"' EXIT

for file in config.sub config.guess; do
  curl --fail --location --connect-timeout 15 --max-time 90 --retry 2 \
    --output "$download_dir/$file" "$mirror/$file?id=$rev"
done

nix store prefetch-file \
  --name "config.sub-${rev:0:7}" \
  --expected-hash 'sha256-/jovMvuv9XhIcyVJ9I2YP9ZSYCTsLw9ancdcL0NZo6Y=' \
  "file://$download_dir/config.sub"

nix store prefetch-file \
  --name "config.guess-${rev:0:7}" \
  --expected-hash 'sha256-ZByuPAx0xJNU0+3gCfP+vYD+vhUBp3wdn6yNQsxFtss=' \
  "file://$download_dir/config.guess"

#!/usr/bin/env bash
# Copy this repo into the Omarchy user plugin dir.
# Live bar instances do not pick this up until:
#   omarchy restart shell
# Do not restart the shell from this script.
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)"
dest="${HOME}/.config/omarchy/plugins/io.github.bonesgit.omarchy-plugin-mgr"

mkdir -p "$dest"
rsync -a --delete --exclude .git --exclude '.hermes' --exclude '*.png' "$src/" "$dest/"
chmod +x "$dest/bin/plugin-mgr"
omarchy plugin validate "$dest"
echo "Installed $dest"
echo "Then: omarchy restart shell"
echo "Enable once: omarchy plugin enable io.github.bonesgit.omarchy-plugin-mgr --section right --after work"

#!/bin/bash
# Push each plugin folder to its standalone repo (omarchy-living-<name>), which
# is what the Omarchy plugin marketplace lists. Run after changing a plugin.
set -euo pipefail
cd "$(dirname "$0")/.."
for name in background lock intro clicks; do
  git subtree split -q --prefix "plugins/io.github.prostratepossum.living-$name" -b "split-$name"
  git push "https://github.com/prostratepossum/omarchy-living-$name.git" "split-$name:main"
done

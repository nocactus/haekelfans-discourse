#!/usr/bin/env bash
# Synct het theme naar de dev-checkout en (her)importeert het in de dev-DB.
# Gebruik: bin/sync-theme.sh [--no-import]
set -euo pipefail
SRC="$(cd "$(dirname "$0")/../theme/haekelfans-theme" && pwd)"
DEV="${DISCOURSE_DEV:-$HOME/Developer/discourse-dev}"
DEST="$DEV/tmp/hf-theme"
mkdir -p "$DEST"
rsync -a --delete "$SRC/" "$DEST/"
echo "synced -> $DEST"

if [ "${1:-}" != "--no-import" ]; then
  docker exec -u discourse:discourse -w /src -e LOAD_PLUGINS=1 discourse_dev \
    bundle exec rails runner '
      name = "Häkelfans"
      Theme.where(name: name).destroy_all
      theme = RemoteTheme.import_theme_from_directory("/src/tmp/hf-theme")
      theme.update!(user_selectable: true)
      theme.set_default!
      puts "geimporteerd: theme id #{theme.id} (#{theme.name}), default gezet"
    '
fi

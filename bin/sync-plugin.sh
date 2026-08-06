#!/usr/bin/env bash
# Synct het plugin uit deze repo naar de Discourse dev-checkout.
# De dev-container mount alleen ~/Developer/discourse-dev, dus een symlink
# naar deze (iCloud-)map zou binnen de container niet resolven.
set -euo pipefail
SRC="$(cd "$(dirname "$0")/../plugin/haekelfans-timeline" && pwd)"
DEST="${DISCOURSE_DEV:-$HOME/Developer/discourse-dev}/plugins/haekelfans-timeline"
mkdir -p "$DEST"
rsync -a --delete "$SRC/" "$DEST/"
echo "synced -> $DEST"

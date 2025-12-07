#!/usr/bin/env bash
# ==============================================================================
# update_emoji.sh
#
# Description:
#   Downloads the latest emoji-test.txt from Unicode, parses it to extract
#   fully-qualified emojis (excluding the Component group), and generates
#   emoji-list.js in the assets directory.
#
# Requirements:
#   - curl
#   - jq
#   - GNU awk
#   - GNU sed
#   - date
#
# Usage:
#   bash update_emoji.sh
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

# ==============================================================================
# Configuration
# ==============================================================================
URL="https://unicode.org/Public/emoji/latest/emoji-test.txt"
SERVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$(cd "$SERVICE_DIR/../assets" && pwd)"

RAW_FILE_PATH="$ASSETS_DIR/emoji-test.txt"
JS_FILE_PATH="$ASSETS_DIR/emoji-list.js"
TMP_JSON="$ASSETS_DIR/emoji-list.json.tmp"

echo "SYNC_STARTED"

# ==============================================================================
# Dependency Checks
# ==============================================================================
if ! command -v curl >/dev/null; then
  echo "SYNC_NET_ERROR: curl not found"
  exit 1
fi

if ! command -v jq >/dev/null; then
  echo "Error: jq is required." >&2
  exit 1
fi

if ! command -v awk >/dev/null; then
  echo "Error: awk is required." >&2
  exit 1
fi

if [ ! -d "$ASSETS_DIR" ]; then
  echo "Error: assets directory does not exist: $ASSETS_DIR" >&2
  exit 1
fi

# ==============================================================================
# Download
# ==============================================================================
echo "Downloading $URL to $RAW_FILE_PATH ..."

if ! curl --compressed -fsSL "$URL" -o "$RAW_FILE_PATH"; then
  echo "SYNC_NET_ERROR: failed to download $URL"
  rm -f "$RAW_FILE_PATH" || true
  echo "Partial file (if any) removed."
  exit 2
fi

echo "Download complete."

# ==============================================================================
# Checksum Calculation
# ==============================================================================
checksum="unknown"

if command -v sha256sum >/dev/null; then
  checksum=$(sha256sum "$RAW_FILE_PATH" | awk '{print $1}')
elif command -v shasum >/dev/null; then
  checksum=$(shasum -a 256 "$RAW_FILE_PATH" | awk '{print $1}')
elif command -v openssl >/dev/null; then
  checksum=$(openssl dgst -sha256 "$RAW_FILE_PATH" | awk '{print $NF}')
fi

echo "SHA256 checksum: $checksum"

# ==============================================================================
# Parse and Generate JSON
# ==============================================================================
awk '
  BEGIN {
    group = "";
    skip = 0;
    first_group = 1;
    print "{";
  }

  # Handle Group Headers
  /^# group:/ {
    g = substr($0, index($0, ":") + 2);
    if (g == "Component") {
      skip = 1;
      group = "";
    } else {
      if (!first_group) print "] ,"; else first_group = 0;
      group = g;
      skip = 0;
      printf "\"%s\": [", group;
      first = 1;
    }
    next;
  }

  # Skip empty lines and comments
  /^$/ { next; }
  /^#/ { next; }

  # Process Emoji Lines
  {
    if (skip || group == "") next;

    if ($0 ~ /; fully-qualified/) {
      split($0, a, ";");
      code = a[1];
      rest = a[2];

      # Extract emoji char and name
      match(rest, /# ([^ ]+) E[0-9.]+ (.*)/, m);
      emoji = m[1];
      name = m[2];

      # Generate Alias
      alias = tolower(name);
      gsub(/ /, "_", alias);
      gsub(/-/, "_", alias);
      gsub(/:/, "", alias);
      gsub(/\./, "", alias);
      gsub(/^[^a-z0-9]+|[^a-z0-9]+$/, "", alias);

      if (!first) printf ",";
      first = 0;

      printf "\n  {\"emoji\": \"%s\", \"name\": \"%s\", \"aliases\": [\"%s\"], \"tags\": []}", emoji, name, alias;
    }
  }

  END {
    if (group != "") print "]";
    print "\n}"
  }
' "$RAW_FILE_PATH" > "$TMP_JSON"

# ==============================================================================
# Format and Finalize
# ==============================================================================

# Format JSON with jq
jq . "$TMP_JSON" > "$TMP_JSON.pretty"
mv "$TMP_JSON.pretty" "$TMP_JSON"

# Prepare JS Header
DATE_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
HEADER="// Generated from: $URL\n// Generated on: $DATE_ISO\n// SHA256: $checksum\n\nconst emojiList = "

# Write final JS file
printf "%b" "$HEADER" > "$JS_FILE_PATH"
cat "$TMP_JSON" >> "$JS_FILE_PATH"

# Cleanup
rm "$TMP_JSON"
rm -f "$RAW_FILE_PATH" || true

echo "Removed raw file."
echo "Write complete."
echo "SYNC_COMPLETE"
echo "Done."

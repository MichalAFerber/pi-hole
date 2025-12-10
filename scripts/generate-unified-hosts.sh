#!/usr/bin/env bash
set -euo pipefail

# Resolve repo root (scripts/..)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

HOSTS_DIR="$REPO_DIR/hosts"
ALLOWLISTS_DIR="$REPO_DIR/allowlists"
OUTPUT_FILE="$HOSTS_DIR/unified-hosts.txt"

mkdir -p "$HOSTS_DIR"

tmp_block="$(mktemp)"
tmp_allow="$(mktemp)"
tmp_block_sorted="${tmp_block}.sorted"
tmp_allow_sorted="${tmp_allow}.sorted"
tmp_final="${tmp_block}.final"

cleanup() {
  rm -f "$tmp_block" "$tmp_allow" "$tmp_block_sorted" "$tmp_allow_sorted" "$tmp_final" || true
}
trap cleanup EXIT

echo "🔧 Collecting host components from $HOSTS_DIR"

# Collect block components: all hosts/*.txt except unified-hosts.txt
if find "$HOSTS_DIR" -maxdepth 1 -type f -name '*.txt' ! -name 'unified-hosts.txt' | grep -q .; then
  find "$HOSTS_DIR" -maxdepth 1 -type f -name '*.txt' ! -name 'unified-hosts.txt' -print0 \
    | sort -z \
    | xargs -0 cat -- \
    | sed 's/\r$//' \
    | sed -E 's/#.*$//' \
    | tr -s ' \t' ' ' \
    | sed 's/^ //; s/ $//' \
    | awk '
        NF>0 {
          # Treat IPv4 in first column as IP, rest tokens as hostnames.
          # If no IP present, treat all tokens as hostnames.
          ip = $1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ ? $1 : ""
          start = ip == "" ? 1 : 2
          for (i = start; i <= NF; i++) {
            host = tolower($i)
            if (host != "" && host !~ /[^a-z0-9._-]/) {
              print host
            }
          }
        }
      ' > "$tmp_block"
else
  echo "⚠️ No host component .txt files found under $HOSTS_DIR (excluding unified-hosts.txt)."
  : > "$tmp_block"
fi

echo "🔧 Collecting allowlists from $ALLOWLISTS_DIR (if present)"

# Collect allowlists: all allowlists/**/*.txt
if [ -d "$ALLOWLISTS_DIR" ] && find "$ALLOWLISTS_DIR" -type f -name '*.txt' | grep -q .; then
  find "$ALLOWLISTS_DIR" -type f -name '*.txt' -print0 \
    | sort -z \
    | xargs -0 cat -- \
    | sed 's/\r$//' \
    | sed -E 's/#.*$//' \
    | tr -s ' \t' ' ' \
    | sed 's/^ //; s/ $//' \
    | awk '
        NF>0 {
          ip = $1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ ? $1 : ""
          start = ip == "" ? 1 : 2
          for (i = start; i <= NF; i++) {
            host = tolower($i)
            if (host != "" && host !~ /[^a-z0-9._-]/) {
              print host
            }
          }
        }
      ' > "$tmp_allow"
else
  : > "$tmp_allow"
fi

echo "🔧 Normalizing + de-duplicating + subtracting allowlists"

# Sort and de-duplicate
sort -u "$tmp_block" > "$tmp_block_sorted"
sort -u "$tmp_allow" > "$tmp_allow_sorted"

# comm -23 => in blocklist but not in allowlist
comm -23 "$tmp_block_sorted" "$tmp_allow_sorted" > "$tmp_final"

echo "📝 Writing $OUTPUT_FILE"

{
  echo "# unified hosts file for Pi-hole"
  echo "# generated: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "#"
  echo "# components (hosts/*.txt, excluding unified-hosts.txt):"
  find "$HOSTS_DIR" -maxdepth 1 -type f -name '*.txt' ! -name 'unified-hosts.txt' -printf "#   %f\n" 2>/dev/null | sort || true
  echo "#"
  echo "# allowlists (allowlists/**/*.txt):"
  if [ -d "$ALLOWLISTS_DIR" ]; then
    find "$ALLOWLISTS_DIR" -type f -name '*.txt' -printf "#   %P\n" 2>/dev/null | sort || true
  fi
  echo
  # Emit in hosts format
  awk '{ printf "0.0.0.0 %s\n", $1 }' "$tmp_final"
} > "$OUTPUT_FILE"

echo "✅ Done. Wrote $(wc -l < "$OUTPUT_FILE") lines to $OUTPUT_FILE"

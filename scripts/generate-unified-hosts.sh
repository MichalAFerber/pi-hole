
#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_FILE="$ROOT_DIR/hosts/unified-hosts.txt"

cat > "$OUT_FILE" <<'EOF'
# Unified hosts file for Michal’s network
# Generated automatically
EOF

grep -h -v '^#' "$ROOT_DIR"/hosts/*.txt | grep -v '^[[:space:]]*$' | sort -u >> "$OUT_FILE"
echo "Generated $OUT_FILE"

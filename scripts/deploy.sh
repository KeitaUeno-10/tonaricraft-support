#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_DIR="$(mktemp -d "${TMPDIR:-/tmp}/tonaricraft-deploy.XXXXXX")"
CONFIG_FILE="$(mktemp "${TMPDIR:-/tmp}/tonaricraft-wrangler.XXXXXX.jsonc")"

cleanup() {
  rm -rf "$DEPLOY_DIR"
  rm -f "$CONFIG_FILE"
}
trap cleanup EXIT

mkdir -p "$DEPLOY_DIR/assets" "$DEPLOY_DIR/atonankai" "$DEPLOY_DIR/sakinobase" "$DEPLOY_DIR/tsunagari"

cp "$ROOT_DIR/index.html" "$ROOT_DIR/support.html" "$ROOT_DIR/privacy.html" "$ROOT_DIR/robots.txt" "$ROOT_DIR/sitemap.xml" "$DEPLOY_DIR/"
cp "$ROOT_DIR/assets/gensotsu-preview.mp4" "$DEPLOY_DIR/assets/"
cp "$ROOT_DIR/atonankai/index.html" "$ROOT_DIR/atonankai/privacy.html" "$DEPLOY_DIR/atonankai/"
cp "$ROOT_DIR/sakinobase/index.html" "$ROOT_DIR/sakinobase/privacy.html" "$DEPLOY_DIR/sakinobase/"
cp "$ROOT_DIR/tsunagari/index.html" "$ROOT_DIR/tsunagari/privacy.html" "$DEPLOY_DIR/tsunagari/"

export CLOUDFLARE_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-c5bc561728a28224c3d673e6bd7ab8b2}"
export TONARICRAFT_D1_DATABASE_ID="${TONARICRAFT_D1_DATABASE_ID:-04ae736a-8657-49cc-845e-4ae7974064ad}"

if [[ -z "${TONARICRAFT_D1_DATABASE_ID:-}" ]]; then
  echo "TONARICRAFT_D1_DATABASE_ID is required. Create it with: npx wrangler d1 create tonaricraft-db" >&2
  exit 1
fi

cat > "$CONFIG_FILE" <<JSON
{
  "name": "${CLOUDFLARE_WORKER_NAME:-tonaricraft-support}",
  "main": "$ROOT_DIR/worker.js",
  "compatibility_date": "${CLOUDFLARE_COMPATIBILITY_DATE:-2026-07-09}",
  "assets": {
    "directory": "$DEPLOY_DIR",
    "binding": "ASSETS"
  },
  "send_email": [
    {
      "name": "SEB"
    }
  ],
  "d1_databases": [
    {
      "binding": "DB",
      "database_name": "tonaricraft-db",
      "database_id": "$TONARICRAFT_D1_DATABASE_ID"
    }
  ]
}
JSON

npx wrangler@4.107.1 deploy \
  --config "$CONFIG_FILE" \
  --message "${DEPLOY_MESSAGE:-Deploy TonariCraft contact form}" \
  "$@"

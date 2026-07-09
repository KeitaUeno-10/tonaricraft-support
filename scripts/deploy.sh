#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPLOY_DIR="$(mktemp -d "${TMPDIR:-/tmp}/tonaricraft-deploy.XXXXXX")"

cleanup() {
  rm -rf "$DEPLOY_DIR"
}
trap cleanup EXIT

mkdir -p "$DEPLOY_DIR/assets" "$DEPLOY_DIR/atonankai" "$DEPLOY_DIR/sakinobase" "$DEPLOY_DIR/tsunagari"

cp "$ROOT_DIR/index.html" "$ROOT_DIR/support.html" "$ROOT_DIR/robots.txt" "$ROOT_DIR/sitemap.xml" "$DEPLOY_DIR/"
cp "$ROOT_DIR/assets/gensotsu-preview.mp4" "$DEPLOY_DIR/assets/"
cp "$ROOT_DIR/atonankai/index.html" "$ROOT_DIR/atonankai/privacy.html" "$DEPLOY_DIR/atonankai/"
cp "$ROOT_DIR/sakinobase/index.html" "$ROOT_DIR/sakinobase/privacy.html" "$DEPLOY_DIR/sakinobase/"
cp "$ROOT_DIR/tsunagari/index.html" "$ROOT_DIR/tsunagari/privacy.html" "$DEPLOY_DIR/tsunagari/"

export CLOUDFLARE_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-c5bc561728a28224c3d673e6bd7ab8b2}"

npx wrangler@4.107.1 deploy "$DEPLOY_DIR" \
  --name "${CLOUDFLARE_WORKER_NAME:-tonaricraft-support}" \
  --compatibility-date "${CLOUDFLARE_COMPATIBILITY_DATE:-2026-07-09}" \
  --message "${DEPLOY_MESSAGE:-Deploy TonariCraft static site}" \
  "$@"

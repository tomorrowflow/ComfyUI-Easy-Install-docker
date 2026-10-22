#!/usr/bin/env bash
# update-pixaroma.sh - keep ComfyUI-Pixaroma on the newest GitLab version (git pull),
# because the Comfy Registry / ComfyUI-Manager lags a few versions behind.
#
# Usage (on the ComfyUI host):
#   ./update-pixaroma.sh                      # ComfyUI runs directly on this machine
#   CONTAINER=comfyui ./update-pixaroma.sh    # ComfyUI runs in a Docker container
#
# First run: replaces the registry copy (no .git) with a git clone, keeps a backup.
# Later runs: git pull, reinstall requirements only if they changed, restart ComfyUI.

set -euo pipefail

COMFY_DIR="${COMFY_DIR:-/app/ComfyUI}"             # ComfyUI root (inside the container if CONTAINER is set)
COMFY_URL="${COMFY_URL:-http://192.168.2.17:8188}" # used for restart + health check
CONTAINER="${CONTAINER:-}"                         # docker container name, empty = run locally
PYTHON="${PYTHON:-python3}"                        # python of the ComfyUI environment
NO_RESTART="${NO_RESTART:-}"                       # set to 1 to skip the restart (caller restarts)
REPO="https://gitlab.com/pixaroma/comfyui-pixaroma.git"
NODE_DIR="$COMFY_DIR/custom_nodes/ComfyUI-Pixaroma"

run() {  # run a shell snippet locally or inside the container
  if [ -n "$CONTAINER" ]; then docker exec -i "$CONTAINER" bash -lc "$1"; else bash -lc "$1"; fi
}
version() { run "grep -m1 '^version' '$NODE_DIR/pyproject.toml' 2>/dev/null | cut -d'\"' -f2" || true; }

echo "==> ComfyUI-Pixaroma in $NODE_DIR ${CONTAINER:+(container: $CONTAINER)}"
BEFORE="$(version)"; echo "    installed: ${BEFORE:-none}"

if run "[ -d '$NODE_DIR/.git' ]"; then
  echo "==> git pull"
  OLD_REQ="$(run "sha1sum '$NODE_DIR/requirements.txt' 2>/dev/null || true")"
  run "cd '$NODE_DIR' && git fetch --quiet origin && git reset --hard --quiet '@{u}'"
  NEW_REQ="$(run "sha1sum '$NODE_DIR/requirements.txt' 2>/dev/null || true")"
else
  echo "==> first run: replacing registry copy with a git clone"
  # backup OUTSIDE custom_nodes, otherwise ComfyUI loads it as a second pack
  BACKUP="$COMFY_DIR/custom_nodes_backup/ComfyUI-Pixaroma.registry-$(date +%Y%m%d-%H%M%S)"
  run "mkdir -p '$COMFY_DIR/custom_nodes_backup' && [ -d '$NODE_DIR' ] && mv '$NODE_DIR' '$BACKUP' || true"
  run "git clone --quiet '$REPO' '$NODE_DIR'"
  echo "    old folder kept as: $BACKUP (delete once all is fine)"
  OLD_REQ=""; NEW_REQ="x"
fi

if [ "$OLD_REQ" != "$NEW_REQ" ] && run "[ -f '$NODE_DIR/requirements.txt' ]"; then
  echo "==> requirements changed, installing"
  run "$PYTHON -m pip install -q -r '$NODE_DIR/requirements.txt'"
fi

AFTER="$(version)"; echo "    now:       ${AFTER:-?}"
if [ "$BEFORE" = "$AFTER" ]; then echo "==> already up to date, no restart needed"; exit 0; fi
if [ -n "$NO_RESTART" ]; then echo "==> done: $BEFORE -> $AFTER (restart skipped)"; exit 0; fi

echo "==> restarting ComfyUI"
curl -s -m 10 -X POST "$COMFY_URL/v2/manager/reboot" >/dev/null 2>&1 || true
sleep 15
for i in $(seq 1 60); do curl -s -m 5 "$COMFY_URL/system_stats" >/dev/null && break; sleep 3; done
if curl -s -m 10 "$COMFY_URL/system_stats" >/dev/null; then echo "    ComfyUI is back"
else echo "    ComfyUI not reachable - restart it manually${CONTAINER:+ (docker restart $CONTAINER)}"; fi
echo "==> done: $BEFORE -> $AFTER. Hard-refresh the browser (Ctrl/Cmd+Shift+R)."


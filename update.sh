#!/bin/bash

# ComfyUI Update Script
# Updates ComfyUI core and all custom nodes

set -e

echo "==================================="
echo "ComfyUI Update Script"
echo "==================================="
echo ""

# Check if docker compose is running
if ! docker compose ps | grep -q "comfyui.*Up"; then
    echo "⚠️  ComfyUI container is not running"
    echo "Starting container..."
    docker compose up -d
    sleep 5
fi

echo "Updating ComfyUI and custom nodes..."
echo ""

# Update ComfyUI core. Release tags live on release/* branches, not master,
# so stable checks out the newest vX.Y.Z tag. Set COMFYUI_CHANNEL=nightly to
# follow master instead.
COMFYUI_CHANNEL=${COMFYUI_CHANNEL:-stable}
echo "→ Updating ComfyUI core ($COMFYUI_CHANNEL)..."
docker compose exec -e COMFYUI_CHANNEL="$COMFYUI_CHANNEL" comfyui bash -c '
    set -e
    cd /app/ComfyUI
    git fetch --tags --force origin
    if [ "$COMFYUI_CHANNEL" = nightly ]; then
        git checkout master
        git pull --ff-only
    else
        tag=$(git tag --list "v[0-9]*" --sort=-v:refname | grep -E "^v[0-9]+\.[0-9]+\.[0-9]+$" | head -1)
        git checkout "$tag"
    fi
    echo "  ComfyUI $(git describe --tags)"
'

# Install core requirements immediately after git pull — new ComfyUI versions
# can add required packages (e.g. comfy-aimdo) that must exist before restart.
echo "→ Installing ComfyUI core requirements..."
docker compose exec comfyui bash -c "cd /app/ComfyUI && pip3 install --no-cache-dir -r requirements.txt"

# ComfyUI-Manager v4 is a pip package pinned by ComfyUI core
echo "→ Updating ComfyUI Manager..."
docker compose exec comfyui bash -c "cd /app/ComfyUI && pip3 install --no-cache-dir -r manager_requirements.txt"

# ComfyUI-Pixaroma: the Comfy Registry lags behind, so pull it straight from
# git. The first run swaps the registry copy for a git clone.
echo "→ Updating ComfyUI-Pixaroma..."
CONTAINER="$(docker compose ps -q comfyui)" NO_RESTART=1 \
    "$(dirname "$0")/update-pixorama.sh" || echo "  ⚠️  Failed to update ComfyUI-Pixaroma"

# Update all custom nodes
echo "→ Updating custom nodes..."
docker compose exec comfyui bash -c '
    cd /app/ComfyUI/custom_nodes
    for dir in */; do
        if [ -d "${dir}.git" ]; then
            echo "  Updating ${dir%/}..."
            (cd "$dir" && git pull) || echo "  ⚠️  Failed to update ${dir%/}"
        fi
    done
'

# Reinstall requirements for updated nodes
echo "→ Updating custom node dependencies..."
docker compose exec comfyui bash -c '
    cd /app/ComfyUI/custom_nodes
    for dir in */; do
        if [ -f "${dir}requirements.txt" ]; then
            echo "  Installing requirements for ${dir%/}..."
            pip3 install --no-cache-dir -r "${dir}requirements.txt" 2>/dev/null || true
        fi
    done
'

# Re-apply core requirements last — custom node requirements can downgrade
# packages ComfyUI core depends on (e.g. aiortc pulling av below 17).
echo "→ Re-applying ComfyUI core requirements..."
docker compose exec comfyui bash -c "cd /app/ComfyUI && pip3 install --no-cache-dir -r requirements.txt"

# Commit the updated container state so pip installs survive docker compose
# recreates (e.g. --force-recreate or image rebuilds).
echo "→ Persisting changes to image..."
CONTAINER_ID=$(docker compose ps -q comfyui)
docker commit \
    --change 'CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--enable-manager"]' \
    "$CONTAINER_ID" comfyui:easy-install
echo "  ✓ Image updated"

echo ""
echo "==================================="
echo "Update Complete!"
echo "==================================="
echo ""
echo "Restart ComfyUI for changes to take effect:"
echo "   docker compose restart"
echo ""

# Ask if user wants to restart
read -p "Restart ComfyUI now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Restarting ComfyUI..."
    docker compose restart
    echo "✓ ComfyUI restarted successfully"
    echo "Access it at: http://localhost:8188"
fi

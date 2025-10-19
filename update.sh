#!/bin/bash

# ComfyUI Update Script
# Updates ComfyUI core and all custom nodes

set -e

echo "==================================="
echo "ComfyUI Update Script"
echo "==================================="
echo ""

# Check if docker-compose is running
if ! docker-compose ps | grep -q "comfyui.*Up"; then
    echo "⚠️  ComfyUI container is not running"
    echo "Starting container..."
    docker-compose up -d
    sleep 5
fi

echo "Updating ComfyUI and custom nodes..."
echo ""

# Update ComfyUI core
echo "→ Updating ComfyUI core..."
docker-compose exec comfyui bash -c "cd /app/ComfyUI && git pull"

# Update ComfyUI Manager
echo "→ Updating ComfyUI Manager..."
docker-compose exec comfyui bash -c "cd /app/ComfyUI/custom_nodes/ComfyUI-Manager && git pull" || echo "  ⚠️  Failed to update Manager (may not exist yet)"

# Update all custom nodes
echo "→ Updating custom nodes..."
docker-compose exec comfyui bash -c '
    cd /app/ComfyUI/custom_nodes
    for dir in */; do
        if [ -d "${dir}.git" ]; then
            echo "  Updating ${dir%/}..."
            (cd "$dir" && git pull) || echo "  ⚠️  Failed to update ${dir%/}"
        fi
    done
'

# Reinstall requirements for updated nodes
echo "→ Updating dependencies..."
docker-compose exec comfyui bash -c '
    cd /app/ComfyUI/custom_nodes
    for dir in */; do
        if [ -f "${dir}requirements.txt" ]; then
            echo "  Installing requirements for ${dir%/}..."
            pip3 install --no-cache-dir -r "${dir}requirements.txt" 2>/dev/null || true
        fi
    done
'

# Update core requirements
echo "→ Updating ComfyUI core dependencies..."
docker-compose exec comfyui bash -c "cd /app/ComfyUI && pip3 install --no-cache-dir -r requirements.txt"

echo ""
echo "==================================="
echo "Update Complete!"
echo "==================================="
echo ""
echo "Restart ComfyUI for changes to take effect:"
echo "   docker-compose restart"
echo ""

# Ask if user wants to restart
read -p "Restart ComfyUI now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Restarting ComfyUI..."
    docker-compose restart
    echo "✓ ComfyUI restarted successfully"
    echo "Access it at: http://localhost:8188"
fi
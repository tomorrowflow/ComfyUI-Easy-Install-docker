#!/bin/bash

# ComfyUI Update Script
# Uses Easy Install's update mechanisms

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

# Method 1: Use Easy Install's update script if it exists
echo "→ Checking for Easy Install update scripts..."
if docker-compose exec comfyui test -f /app/ComfyUI-Easy-Install/update.sh 2>/dev/null; then
    echo "✓ Found Easy Install update script, running it..."
    docker-compose exec comfyui bash -c "cd /app/ComfyUI-Easy-Install && ./update.sh"
    echo "✓ Update complete via Easy Install script"
elif docker-compose exec comfyui test -f /app/ComfyUI-Easy-Install/UpdateComfyUI-Linux.sh 2>/dev/null; then
    echo "✓ Found UpdateComfyUI-Linux.sh script, running it..."
    docker-compose exec comfyui bash -c "cd /app/ComfyUI-Easy-Install && ./UpdateComfyUI-Linux.sh"
    echo "✓ Update complete via Easy Install script"
else
    # Method 2: Manual update via git
    echo "→ No Easy Install update script found, updating manually..."
    
    # Update ComfyUI core
    echo "→ Updating ComfyUI core..."
    docker-compose exec comfyui bash -c "cd /app/ComfyUI-Easy-Install/ComfyUI && git pull"
    
    # Update ComfyUI Manager
    echo "→ Updating ComfyUI Manager..."
    docker-compose exec comfyui bash -c "cd /app/ComfyUI-Easy-Install/ComfyUI/custom_nodes/ComfyUI-Manager && git pull" || true
    
    # Update all custom nodes
    echo "→ Updating custom nodes..."
    docker-compose exec comfyui bash -c '
        cd /app/ComfyUI-Easy-Install/ComfyUI/custom_nodes
        for dir in */; do
            if [ -d "${dir}.git" ]; then
                echo "  Updating ${dir%/}..."
                (cd "$dir" && git pull) || echo "  ⚠️  Failed to update ${dir%/}"
            fi
        done
    '
    
    # Reinstall requirements
    echo "→ Updating dependencies..."
    docker-compose exec comfyui bash -c '
        cd /app/ComfyUI-Easy-Install/ComfyUI/custom_nodes
        for dir in */; do
            if [ -f "${dir}requirements.txt" ]; then
                echo "  Installing requirements for ${dir%/}..."
                pip3 install --no-cache-dir -r "${dir}requirements.txt" 2>/dev/null || true
            fi
        done
    '
    
    echo "✓ Manual update complete"
fi

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
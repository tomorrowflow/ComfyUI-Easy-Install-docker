#!/bin/bash

# ComfyUI Docker Setup Script
# This script initializes the directory structure for ComfyUI Docker

set -e

echo "==================================="
echo "ComfyUI Docker Setup Script"
echo "==================================="
echo ""

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Create directory structure
echo "Creating directory structure..."

# Main data directories
mkdir -p data/{models,output,input,custom_nodes,user/default/workflows}

# Model subdirectories
mkdir -p data/models/{checkpoints,vae,loras,embeddings,controlnet,clip,clip_vision,upscale_models,diffusion_models,style_models,unet}

# Config directory
mkdir -p config

echo "✓ Directory structure created"
echo ""

# Create extra_model_paths.yaml.example if it doesn't exist
if [ ! -f config/extra_model_paths.yaml.example ]; then
    echo "Creating example extra_model_paths.yaml configuration..."
    cat > config/extra_model_paths.yaml.example << 'EOF'
# ComfyUI Extra Model Paths Configuration
# Copy this file to extra_model_paths.yaml and uncomment/modify as needed
# This allows you to use models from other locations without copying them

# Example: Use models from another directory
# my_models:
#   base_path: /path/to/your/model/directory
#   
#   checkpoints: models/checkpoints/
#   vae: models/vae/
#   loras: models/loras/
#   embeddings: models/embeddings/
#   controlnet: models/controlnet/
#   clip: models/clip/
#   clip_vision: models/clip_vision/
#   upscale_models: models/upscale_models/
#   diffusion_models: models/diffusion_models/

# Example: A1111/Stable Diffusion WebUI compatibility
# webui:
#   base_path: /path/to/stable-diffusion-webui/
#   
#   checkpoints: models/Stable-diffusion
#   vae: models/VAE
#   loras: |
#     models/Lora
#     models/LyCORIS
#   embeddings: embeddings
#   hypernetworks: models/hypernetworks
#   controlnet: models/ControlNet
#   upscale_models: |
#     models/ESRGAN
#     models/RealESRGAN
#     models/SwinIR
EOF
    echo "✓ Example extra_model_paths.yaml.example created in config/"
    echo "  Edit this file if you want to use models from external directories"
else
    echo "✓ extra_model_paths.yaml.example already exists"
fi
echo ""

# Create README for data directory
if [ ! -f data/README.md ]; then
    cat > data/README.md << 'EOF'
# ComfyUI Data Directory

This directory contains all persistent data for your ComfyUI installation.

## Directory Structure

- **models/**: All AI models organized by type
  - checkpoints/: Stable Diffusion checkpoints
  - vae/: VAE models
  - loras/: LoRA models
  - controlnet/: ControlNet models
  - etc.

- **output/**: Generated images and videos
- **input/**: Input files for processing
- **custom_nodes/**: Custom node extensions (mounted from container)
- **user/**: User settings and workflows
  - default/workflows/: Your saved workflows

## Getting Models

You can download models from:
- Hugging Face: https://huggingface.co/
- CivitAI: https://civitai.com/
- ComfyUI Manager (available in the web interface)

Place models in the appropriate subdirectory under models/.

## Sharing Models

If you have models in another location (e.g., Stable Diffusion WebUI), 
copy config/extra_model_paths.yaml.example to config/extra_model_paths.yaml
and edit it to point to those directories.
EOF
fi

echo "==================================="
echo "Setup Complete!"
echo "==================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Build the Docker image (10-15 minutes):"
echo "   docker-compose build"
echo ""
echo "2. Start ComfyUI:"
echo "   docker-compose up -d"
echo ""
echo "3. Check logs:"
echo "   docker-compose logs -f"
echo ""
echo "4. Access ComfyUI (wait ~30 seconds after start):"
echo "   http://localhost:8188"
echo ""
echo "5. Download models:"
echo "   - Use ComfyUI Manager in the web interface"
echo "   - Or manually place models in data/models/"
echo ""
echo "To update ComfyUI and nodes:"
echo "   ./update.sh"
echo ""
echo "To stop ComfyUI:"
echo "   docker-compose down"
echo ""
echo "Optional: Edit config/extra_model_paths.yaml to use models from other locations"
echo ""
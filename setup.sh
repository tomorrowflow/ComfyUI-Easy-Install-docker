#!/bin/bash

# ComfyUI Easy Install Docker Setup Script
# This script initializes the directory structure for ComfyUI Docker

set -e

echo "==================================="
echo "ComfyUI Docker Setup Script"
echo "Using Easy Install Repository"
echo "==================================="
echo ""

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Create directory structure
echo "Creating directory structure..."

# Main data directory - will hold the entire Easy Install repo
mkdir -p data

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
else
    echo "✓ extra_model_paths.yaml.example already exists"
fi
echo ""

# Create .gitkeep in data directory
touch data/.gitkeep

# Create README for data directory
cat > data/README.md << 'EOF'
# ComfyUI Easy Install Data Directory

This directory will contain the entire ComfyUI-Easy-Install repository after the first build/run.

## Structure (after first run)

```
ComfyUI-Easy-Install/
├── ComfyUI/                  # Main ComfyUI installation
│   ├── models/              # All AI models
│   │   ├── checkpoints/
│   │   ├── vae/
│   │   ├── loras/
│   │   ├── controlnet/
│   │   └── ...
│   ├── output/              # Generated images
│   ├── input/               # Input files
│   ├── custom_nodes/        # All custom nodes from Easy Install
│   └── user/                # User settings and workflows
├── update.sh                # Update script (if provided)
└── ... (other Easy Install files)
```

## Benefits

1. **Easy Updates**: Run update scripts from Easy Install
2. **Maintained Nodes**: All nodes managed by Easy Install team
3. **No Manual Maintenance**: Let Easy Install handle compatibility

## Accessing Files

- **Models**: `data/ComfyUI-Easy-Install/ComfyUI/models/`
- **Output**: `data/ComfyUI-Easy-Install/ComfyUI/output/`
- **Workflows**: `data/ComfyUI-Easy-Install/ComfyUI/user/default/workflows/`
- **Custom Nodes**: `data/ComfyUI-Easy-Install/ComfyUI/custom_nodes/`
EOF

echo "==================================="
echo "Setup Complete!"
echo "==================================="
echo ""
echo "This setup uses the Easy Install repository's maintained scripts."
echo "All custom nodes and updates are handled by the Easy Install team!"
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
echo "4. Access ComfyUI:"
echo "   http://localhost:8188"
echo ""
echo "5. Download models:"
echo "   Use ComfyUI Manager in the web interface"
echo ""
echo "To update ComfyUI and all nodes:"
echo "   ./update.sh"
echo ""
echo "To stop ComfyUI:"
echo "   docker-compose down"
echo ""
# ComfyUI-Easy-Install-docker Implementation Plan

## Project Overview

**Repository**: https://github.com/tomorrowflow/ComfyUI-Easy-Install-docker  
**Branch**: main  
**Purpose**: Docker Compose setup for ComfyUI using the Easy Install repository's maintained scripts  
**Target Environment**: Linux with Nvidia GPU support  

## Core Principle

Instead of manually maintaining 27+ custom node installations in the Dockerfile, leverage the ComfyUI-Easy-Install repository's maintained installation and update scripts. This reduces maintenance burden and ensures compatibility.

---

## Directory Structure to Create

```
ComfyUI-Easy-Install-docker/
├── .github/
│   └── workflows/
│       └── docker-build.yml          # CI/CD workflow (optional)
├── config/
│   └── extra_model_paths.yaml.example
├── data/
│   └── .gitkeep                      # Placeholder for git
├── docs/
│   └── TROUBLESHOOTING.md
├── .dockerignore
├── .gitignore
├── docker-compose.yml
├── Dockerfile
├── LICENSE
├── README.md
├── setup.sh
└── update.sh
```

---

## Implementation Steps

### Step 1: Create .gitignore

**File**: `.gitignore`  
**Purpose**: Prevent committing large data files and local configurations  

**Content**:
```gitignore
# Data directory - contains large models and generated images
data/ComfyUI-Easy-Install/

# Local configuration - user-specific paths
config/extra_model_paths.yaml

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
*.egg-info/
dist/
build/

# Virtual environments
venv/
env/
ENV/

# IDEs
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
*.log

# Docker
.docker/

# Temporary files
*.tmp
temp/

# Keep example files
!config/extra_model_paths.yaml.example
!data/.gitkeep
```

---

### Step 2: Create .dockerignore

**File**: `.dockerignore`  
**Purpose**: Exclude files from Docker build context to speed up builds  

**Content**:
```dockerignore
# Exclude data directory from build context
data/
config/

# Git
.git/
.gitignore
.github/

# Documentation
README.md
*.md
docs/

# Scripts not needed in image
docker-compose.yml
setup.sh
update.sh

# IDE
.vscode/
.idea/

# Temp files
*.log
*.tmp
```

---

### Step 3: Create Dockerfile

**File**: `Dockerfile`  
**Purpose**: Build ComfyUI image using Easy Install scripts  

**Key Requirements**:
- Base image: nvidia/cuda:12.1.0-runtime-ubuntu22.04
- Clone Easy Install repo from MAC-Linux branch
- Install PyTorch with CUDA 12.1 support
- Run Easy Install's installation script
- Install all custom node dependencies
- Expose port 8188

**Content**:
```dockerfile
FROM nvidia/cuda:12.1.0-runtime-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    python3-venv \
    git \
    wget \
    curl \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /app

# Clone the Easy Install repository
RUN git clone --single-branch --branch MAC-Linux \
    https://github.com/Tavris1/ComfyUI-Easy-Install.git /app/ComfyUI-Easy-Install

WORKDIR /app/ComfyUI-Easy-Install

# Make installation script executable
RUN chmod +x ComfyUI-Easy-Install-Linux.sh || true

# Install PyTorch with CUDA support first
RUN pip3 install --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Run the Easy Install script (may fail gracefully, we handle it)
RUN ./ComfyUI-Easy-Install-Linux.sh --non-interactive 2>/dev/null || true

# Ensure ComfyUI is cloned
RUN if [ ! -d "ComfyUI" ]; then \
        git clone https://github.com/comfyanonymous/ComfyUI.git; \
    fi

WORKDIR /app/ComfyUI-Easy-Install/ComfyUI

# Install ComfyUI requirements
RUN pip3 install --no-cache-dir -r requirements.txt || true

# Install ComfyUI Manager if not already installed
RUN if [ ! -d "custom_nodes/ComfyUI-Manager" ]; then \
        mkdir -p custom_nodes && \
        git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager; \
    fi

# Install dependencies for all custom nodes
RUN for dir in custom_nodes/*/; do \
        if [ -f "${dir}requirements.txt" ]; then \
            echo "Installing requirements for ${dir}"; \
            pip3 install --no-cache-dir -r "${dir}requirements.txt" 2>/dev/null || true; \
        fi; \
    done

# Create necessary model directories
RUN mkdir -p \
    models/checkpoints \
    models/vae \
    models/loras \
    models/embeddings \
    models/controlnet \
    models/clip \
    models/clip_vision \
    models/upscale_models \
    models/diffusion_models \
    output \
    input \
    user/default/workflows

# Expose port
EXPOSE 8188

# Start ComfyUI
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
```

---

### Step 4: Create docker-compose.yml

**File**: `docker-compose.yml`  
**Purpose**: Orchestrate ComfyUI container with GPU support and persistent storage  

**Key Requirements**:
- Service name: comfyui
- GPU support via Nvidia runtime
- Volume mount for entire Easy Install directory
- Health check
- Port mapping 8188:8188

**Content**:
```yaml
services:
  comfyui:
    build:
      context: .
      dockerfile: Dockerfile
    image: comfyui:easy-install
    container_name: comfyui
    ports:
      - "8188:8188"
    
    volumes:
      # Persist the entire Easy Install directory to keep updates
      - ./data/ComfyUI-Easy-Install:/app/ComfyUI-Easy-Install:rw
      
      # Optional: extra model paths configuration
      - ./config/extra_model_paths.yaml:/app/ComfyUI-Easy-Install/ComfyUI/extra_model_paths.yaml:ro
    
    # Nvidia GPU Configuration
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,utility
      # Optional: Adjust these for your GPU memory
      # - PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
      
    stdin_open: true
    tty: true
    restart: unless-stopped
    
    # Health check to ensure ComfyUI is running
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8188"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

---

### Step 5: Create setup.sh

**File**: `setup.sh`  
**Purpose**: Initialize directory structure and create example configurations  
**Make executable**: chmod +x setup.sh

**Content**:
```bash
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
```

---

### Step 6: Create update.sh

**File**: `update.sh`  
**Purpose**: Update ComfyUI and all custom nodes using Easy Install's scripts  
**Make executable**: chmod +x update.sh

**Content**:
```bash
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
```

---

### Step 7: Create README.md

**File**: `README.md`  
**Purpose**: Comprehensive documentation for the project  

**Content** (see full README in artifacts - too long to include here inline):
- Project description
- Key advantages over manual setup
- Prerequisites and installation steps
- Usage instructions
- Troubleshooting guide
- Model management
- Update procedures
- Contributing guidelines

**Structure**:
1. Title and badges
2. Overview and key features
3. Why this approach?
4. Prerequisites
5. Quick Start
6. Usage (models, nodes, workflows)
7. Updating
8. Troubleshooting
9. Performance tips
10. Resources and links

---

### Step 8: Create TROUBLESHOOTING.md

**File**: `docs/TROUBLESHOOTING.md`  
**Purpose**: Dedicated troubleshooting guide  

**Content**:
```markdown
# Troubleshooting Guide

## Common Issues and Solutions

### GPU Not Detected

**Symptoms**: ComfyUI runs but doesn't use GPU, slow generation

**Solutions**:

1. Verify Nvidia Container Toolkit is installed:
```bash
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

2. If the above fails, reinstall:
```bash
# Ubuntu/Debian
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

3. Verify GPU is visible in container:
```bash
docker-compose exec comfyui nvidia-smi
```

---

### Out of Memory Errors

**Symptoms**: CUDA out of memory, generation fails

**Solutions**:

1. Edit `docker-compose.yml`, add under `environment:`:
```yaml
- PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
```

2. Restart:
```bash
docker-compose restart
```

3. Use lower resolution/batch size in workflows
4. Use GGUF or quantized models

---

### Custom Node Import Errors

**Symptoms**: Red nodes, missing dependencies

**Solutions**:

1. Check logs:
```bash
docker-compose logs | grep -i error
```

2. Most errors are warnings and don't affect functionality

3. To reinstall dependencies:
```bash
docker-compose exec comfyui bash
cd /app/ComfyUI-Easy-Install/ComfyUI/custom_nodes/[node_name]
pip3 install -r requirements.txt
exit
docker-compose restart
```

---

### Port Already in Use

**Symptoms**: Cannot start, port 8188 in use

**Solution**: Edit `docker-compose.yml`:
```yaml
ports:
  - "8189:8188"  # Change 8189 to any free port
```

---

### Permission Denied Errors

**Symptoms**: Cannot write files, permission errors

**Solution**:
```bash
sudo chown -R $USER:$USER data/
docker-compose restart
```

---

### Container Won't Start

**Symptoms**: docker-compose up fails

**Steps**:

1. Check logs:
```bash
docker-compose logs
```

2. Verify Docker is running:
```bash
sudo systemctl status docker
```

3. Rebuild from scratch:
```bash
docker-compose down
docker system prune -a
docker-compose build --no-cache
docker-compose up -d
```

---

### Slow Performance

**Symptoms**: Generation takes too long

**Solutions**:

1. Verify GPU is being used:
```bash
watch -n 1 nvidia-smi
```

2. Use optimized models (GGUF, FP16)
3. Reduce resolution/batch size
4. Check CPU usage - if high, may indicate CPU bottleneck

---

### Models Not Loading

**Symptoms**: Models folder empty or not recognized

**Solutions**:

1. Verify volume mount in `docker-compose.yml`
2. Place models in correct directory:
```bash
data/ComfyUI-Easy-Install/ComfyUI/models/checkpoints/
```

3. Check external model paths:
```bash
cat config/extra_model_paths.yaml
```

4. Restart container:
```bash
docker-compose restart
```

---

### Update Script Fails

**Symptoms**: ./update.sh errors

**Solutions**:

1. Ensure container is running:
```bash
docker-compose ps
docker-compose up -d
```

2. Manual update:
```bash
docker-compose exec comfyui bash
cd /app/ComfyUI-Easy-Install/ComfyUI
git pull
cd custom_nodes/ComfyUI-Manager
git pull
exit
docker-compose restart
```

---

### Network Access Issues

**Symptoms**: Cannot access from other devices

**Solutions**:

1. Verify firewall:
```bash
sudo ufw allow 8188/tcp
```

2. Check container is listening on 0.0.0.0:
```bash
docker-compose exec comfyui netstat -tlnp | grep 8188
```

3. Access via: `http://SERVER_IP:8188`

---

### Build Takes Too Long

**Symptoms**: docker-compose build > 30 minutes

**Solutions**:

1. This is normal for first build (10-15 min typical)
2. Use build cache for subsequent builds
3. Check internet speed - downloads PyTorch and clones repos

---

### Workflows Not Saving

**Symptoms**: Workflows disappear after restart

**Solutions**:

1. Verify volume mount exists:
```bash
ls -la data/ComfyUI-Easy-Install/ComfyUI/user/default/workflows/
```

2. Check permissions:
```bash
sudo chown -R $USER:$USER data/
```

3. Save workflows via ComfyUI interface, not just in browser

---

## Getting Help

If none of these solutions work:

1. Check ComfyUI logs:
```bash
docker-compose logs -f comfyui
```

2. Check GitHub issues:
   - [This repo](https://github.com/tomorrowflow/ComfyUI-Easy-Install-docker/issues)
   - [ComfyUI](https://github.com/comfyanonymous/ComfyUI/issues)
   - [Easy Install](https://github.com/Tavris1/ComfyUI-Easy-Install/issues)

3. Provide these details when asking for help:
   - OS and version
   - GPU model and driver version
   - Docker and docker-compose version
   - Full error logs
   - Steps to reproduce
```

---

### Step 9: Create LICENSE

**File**: `LICENSE`  
**Purpose**: License for the repository  
**Recommendation**: MIT License (matches ComfyUI spirit)

**Content**:
```
MIT License

Copyright (c) 2025 tomorrowflow

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

### Step 10: Create .github/workflows/docker-build.yml (Optional)

**File**: `.github/workflows/docker-build.yml`  
**Purpose**: CI/CD to test Docker builds  

**Content**:
```yaml
name: Docker Build Test

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Build Docker image
      uses: docker/build-push-action@v4
      with:
        context: .
        push: false
        tags: comfyui:easy-install-test
        cache-from: type=gha
        cache-to: type=gha,mode=max
    
    - name: Test docker-compose config
      run: |
        docker-compose config
```

---

## Implementation Order

Execute in this order:

1. **Create directory structure**
   - Create `config/`, `data/`, `docs/` directories
   - Add `.gitkeep` to `data/`

2. **Create configuration files**
   - `.gitignore`
   - `.dockerignore`
   - `LICENSE`

3. **Create Docker files**
   - `Dockerfile`
   - `docker-compose.yml`

4. **Create scripts**
   - `setup.sh` (make executable)
   - `update.sh` (make executable)

5. **Create documentation**
   - `README.md`
   - `docs/TROUBLESHOOTING.md`
   - `data/README.md`
   - `config/extra_model_paths.yaml.example`

6. **Create CI/CD** (optional)
   - `.github/workflows/docker-build.yml`

7. **Test locally**
   ```bash
   ./setup.sh
   docker-compose build
   docker-compose up -d
   docker-compose logs -f
   ```

8. **Commit and push to repository**

---

## Testing Checklist

After implementation, verify:

- [ ] `./setup.sh` runs without errors
- [ ] `docker-compose build` completes successfully
- [ ] `docker-compose up -d` starts container
- [ ] http://localhost:8188 is accessible
- [ ] GPU is detected (`docker-compose exec comfyui nvidia-smi`)
- [ ] ComfyUI Manager is available in interface
- [ ] Custom nodes are loaded
- [ ] Models can be downloaded via Manager
- [ ] Workflows can be saved and loaded
- [ ] `./update.sh` executes without errors
- [ ] Container restarts preserve data
- [ ] `docker-compose down` and `up` works

---

## Dependencies

### System Requirements
- Docker 20.10+ with Compose V2
- Nvidia GPU with CUDA support
- Nvidia Container Toolkit
- 20GB+ disk space for Docker image
- Additional space for models (varies)

### Network Requirements
- Access to GitHub for cloning repositories
- Access to PyPI for pip packages
- Access to Docker Hub for base images

---

## Key Design Decisions

### Why Easy Install?
- **Maintained node list**: Easy Install team keeps custom nodes updated
- **Tested compatibility**: Nodes are tested together
- **Update scripts**: Built-in update mechanisms
- **Reduced maintenance**: No need to track 27+ repos individually

### Volume Strategy
- Mount entire Easy Install directory for easy updates
- Keeps all data persistent across container restarts
- Allows direct file access from host
- Supports external model paths via YAML config

### Update Mechanism
- Prefer Easy Install's update scripts when available
- Fallback to manual git pull for all repos
- Always update dependencies after pulling code
- Prompt user to restart for changes to take effect

---

## Success Criteria

Implementation is complete when:

1. ✅ All files are created in repository
2. ✅ Setup script initializes environment
3. ✅ Docker build completes successfully
4. ✅ ComfyUI accessible at localhost:8188
5. ✅ GPU is utilized for generation
6. ✅ All Easy Install nodes are available
7. ✅ Models can be managed via ComfyUI Manager
8. ✅ Workflows persist across restarts
9. ✅ Update script successfully updates components
10. ✅ Documentation is comprehensive and clear

---

## Post-Implementation

After successful implementation:

1. Tag initial release (v1.0.0)
2. Add GitHub badges to README
3. Create example workflows in `examples/` directory
4. Consider adding Docker Hub automated builds
5. Monitor issues and improve based on feedback

---

## File Permissions

Ensure executable permissions:
```bash
chmod +x setup.sh
chmod +x update.sh
```

---

## Notes for Implementation

- All bash scripts should use `#!/bin/bash` shebang
- Use `set -e` in scripts to exit on error
- Add comprehensive error messages
- Make scripts idempotent (safe to run multiple times)
- Follow shellcheck best practices for bash scripts
- Use YAML syntax checking for compose files
- Validate Dockerfile with hadolint if possible

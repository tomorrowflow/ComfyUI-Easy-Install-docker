# ComfyUI-Easy-Install-docker

[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com)
[![NVIDIA](https://img.shields.io/badge/NVIDIA-%2376B900.svg?style=for-the-badge&logo=nvidia&logoColor=white)](https://nvidia.com)
[![ComfyUI](https://img.shields.io/badge/ComfyUI-%23FF6B35.svg?style=for-the-badge&logo=github&logoColor=white)](https://github.com/comfyanonymous/ComfyUI)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Docker Compose setup for ComfyUI using the ComfyUI-Easy-Install repository's maintained scripts. This approach eliminates manual maintenance of 27+ custom nodes by leveraging the Easy Install team's tested and maintained node collection.

## 🚀 Overview

ComfyUI-Easy-Install-docker provides a **production-ready, containerized ComfyUI environment** that:

- **Leverages maintained scripts** from the ComfyUI-Easy-Install repository
- **Includes 27+ pre-configured custom nodes** with tested compatibility
- **Supports Nvidia GPU acceleration** with CUDA 12.1
- **Provides persistent storage** for models, workflows, and outputs
- **Offers automated update mechanisms** for ComfyUI and all nodes
- **Reduces maintenance burden** by delegating node management to experts

### Key Features

- ✅ **One-command setup**: `./setup.sh` initializes everything
- ✅ **GPU-accelerated**: Full Nvidia CUDA support
- ✅ **Pre-installed nodes**: All Easy Install nodes ready to use
- ✅ **Persistent data**: Models and workflows survive container restarts
- ✅ **Easy updates**: `./update.sh` keeps everything current
- ✅ **Manager integration**: ComfyUI Manager for additional model/node management
- ✅ **External model support**: Configure paths to existing model collections
- ✅ **Production ready**: Health checks, proper logging, restart policies

## 🤔 Why This Approach?

### The Problem with Manual Setup
Traditional ComfyUI Docker setups require manually tracking and installing 27+ custom nodes, each with their own dependencies, compatibility issues, and update cycles. This creates significant maintenance overhead and compatibility risks.

### The Easy Install Solution
The [ComfyUI-Easy-Install](https://github.com/Tavris1/ComfyUI-Easy-Install) repository provides:

- **Curated node collection**: Hand-picked nodes that work together
- **Tested compatibility**: Nodes are tested as a complete ecosystem
- **Maintained update scripts**: Automated update mechanisms
- **Active community**: Regular updates and bug fixes
- **Reduced complexity**: No need to track individual node repositories

### Benefits Over Manual Docker Setup

| Aspect | Manual Docker | Easy Install Docker |
|--------|---------------|-------------------|
| **Node Management** | Track 27+ repos manually | Single maintained collection |
| **Updates** | Manual git pulls for each node | Automated update scripts |
| **Compatibility** | Risk of version conflicts | Tested node combinations |
| **Maintenance** | High - track breaking changes | Low - delegated to experts |
| **Setup Time** | Hours of research and testing | Minutes with proven setup |

## 📋 Prerequisites

### System Requirements
- **OS**: Linux (Ubuntu 20.04+, Debian 11+, CentOS 8+)
- **CPU**: Multi-core processor (4+ cores recommended)
- **RAM**: 16GB+ (32GB+ recommended for SDXL models)
- **GPU**: Nvidia GPU with CUDA support (RTX 30-series or newer recommended)
- **Storage**: 50GB+ free space (20GB for Docker image + models)

### Software Requirements
- **Docker**: 20.10+ with Docker Compose V2
- **Nvidia Drivers**: Latest drivers for your GPU
- **Nvidia Container Toolkit**: For GPU passthrough

### Installation Commands

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y docker.io docker-compose-plugin nvidia-docker2
sudo systemctl enable docker
sudo systemctl start docker

# Add user to docker group (logout/login required)
sudo usermod -aG docker $USER

# Verify installation
docker --version
docker compose version
nvidia-smi
```

## 🏃 Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/tomorrowflow/ComfyUI-Easy-Install-docker.git
cd ComfyUI-Easy-Install-docker
```

### 2. Initialize Environment
```bash
./setup.sh
```
This creates the directory structure and configuration files.

### 3. Build and Start
```bash
# Build Docker image (10-15 minutes first time)
docker-compose build

# Start ComfyUI
docker-compose up -d

# Check logs
docker-compose logs -f
```

### 4. Access ComfyUI
Open your browser and navigate to: **http://localhost:8188**

### 5. Download Models
Use the **ComfyUI Manager** in the web interface to download models, or place them manually in `data/ComfyUI-Easy-Install/ComfyUI/models/`.

## 📖 Usage Guide

### Directory Structure
```
ComfyUI-Easy-Install-docker/
├── data/                          # Persistent ComfyUI data
│   └── ComfyUI-Easy-Install/      # Easy Install repository
│       └── ComfyUI/
│           ├── models/            # AI models
│           │   ├── checkpoints/   # Base models
│           │   ├── vae/          # VAE models
│           │   ├── loras/        # LoRA adapters
│           │   ├── controlnet/   # ControlNet models
│           │   └── ...
│           ├── output/            # Generated images
│           ├── input/             # Input files
│           ├── custom_nodes/      # All custom nodes
│           └── user/              # Workflows and settings
├── config/                        # Configuration files
│   └── extra_model_paths.yaml     # External model paths
├── docker-compose.yml             # Container orchestration
├── Dockerfile                     # Container build
└── setup.sh & update.sh           # Management scripts
```

### Managing Models

#### Option 1: Via ComfyUI Manager (Recommended)
1. Open ComfyUI at http://localhost:8188
2. Click **Manager** button in the top menu
3. Browse and install models from Civitai, HuggingFace, etc.
4. Models are automatically placed in correct directories

#### Option 2: Manual Placement
Place model files in these directories:
```bash
# Base models (Stable Diffusion checkpoints)
data/ComfyUI-Easy-Install/ComfyUI/models/checkpoints/

# LoRA adapters
data/ComfyUI-Easy-Install/ComfyUI/models/loras/

# ControlNet models
data/ComfyUI-Easy-Install/ComfyUI/models/controlnet/

# VAE models
data/ComfyUI-Easy-Install/ComfyUI/models/vae/
```

#### Option 3: External Model Paths
For large existing model collections, create `config/extra_model_paths.yaml`:
```yaml
my_models:
  base_path: /path/to/your/model/directory
  checkpoints: models/checkpoints/
  vae: models/vae/
  loras: models/loras/
  embeddings: models/embeddings/
  controlnet: models/controlnet/
```

### Working with Nodes

All Easy Install nodes are pre-installed and ready to use. Popular nodes include:

- **ComfyUI-Manager**: Model and node management
- **ControlNet**: Image-to-image control
- **IPAdapter**: Reference image conditioning
- **ReActor**: Face swapping
- **UltimateSDUpscale**: High-quality upscaling
- **Inpaint**: Precise image editing
- **AnimateDiff**: Video generation
- And 20+ more...

### Managing Workflows

#### Saving Workflows
1. Create your workflow in ComfyUI
2. Click **Save** (disk icon) in the menu
3. Choose filename and location
4. Workflows are saved to `data/ComfyUI-Easy-Install/ComfyUI/user/default/workflows/`

#### Loading Workflows
1. Click **Load** (folder icon) in the menu
2. Browse and select your workflow file
3. Workflows persist across container restarts

#### Sharing Workflows
- Export workflows as JSON files
- Share with the community on [ComfyUI subreddit](https://reddit.com/r/ComfyUI) or [Discord](https://discord.gg/comfyui)

## 🔄 Updating ComfyUI

### Automated Updates
```bash
./update.sh
```
This script:
- Updates ComfyUI core
- Updates ComfyUI Manager
- Updates all custom nodes
- Reinstalls dependencies
- Prompts to restart the container

### Manual Updates
```bash
# Update ComfyUI core
docker-compose exec comfyui bash -c "cd /app/ComfyUI-Easy-Install/ComfyUI && git pull"

# Update ComfyUI Manager
docker-compose exec comfyui bash -c "cd /app/ComfyUI-Easy-Install/ComfyUI/custom_nodes/ComfyUI-Manager && git pull"

# Restart to apply changes
docker-compose restart
```

## 🔧 Troubleshooting

### Common Issues

#### GPU Not Detected
```bash
# Verify Nvidia Container Toolkit
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi

# If fails, reinstall toolkit
sudo apt install -y nvidia-container-toolkit
sudo systemctl restart docker

# Check GPU in container
docker-compose exec comfyui nvidia-smi
```

#### Out of Memory Errors
Add to `docker-compose.yml` under `environment:`:
```yaml
- PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
```
Then restart: `docker-compose restart`

#### Port Already in Use
Edit `docker-compose.yml`:
```yaml
ports:
  - "8189:8188"  # Change 8189 to any free port
```

#### Permission Errors
```bash
sudo chown -R $USER:$USER data/
docker-compose restart
```

#### Container Won't Start
```bash
# Check logs
docker-compose logs

# Rebuild from scratch
docker-compose down
docker system prune -a
docker-compose build --no-cache
docker-compose up -d
```

### Getting Help
1. Check logs: `docker-compose logs -f`
2. Visit troubleshooting guide: `docs/TROUBLESHOOTING.md`
3. Check GitHub issues for this repo, ComfyUI, or Easy Install
4. Provide: OS, GPU model, Docker version, full error logs

## ⚡ Performance Tips

### GPU Optimization
- Use **GGUF quantized models** for faster inference
- Enable **FP16 precision** in workflows when possible
- Monitor GPU usage: `watch -n 1 nvidia-smi`

### Memory Management
- Reduce batch size for large generations
- Use lower resolutions for testing
- Clear GPU cache between large generations

### Storage Optimization
- Use SSD storage for models and outputs
- Consider external model paths for large collections
- Regularly clean Docker: `docker system prune`

### Network Optimization
- Use wired connection for model downloads
- Consider local model caching for repeated downloads

## 📚 Resources & Links

### Official Documentation
- [ComfyUI GitHub](https://github.com/comfyanonymous/ComfyUI) - Main repository
- [ComfyUI Wiki](https://github.com/comfyanonymous/ComfyUI/wiki) - Usage guides
- [ComfyUI Examples](https://comfyanonymous.github.io/ComfyUI_examples/) - Workflow examples

### Easy Install Resources
- [ComfyUI-Easy-Install](https://github.com/Tavris1/ComfyUI-Easy-Install) - Source repository
- [Easy Install Discord](https://discord.gg/comfyui) - Community support

### Model Sources
- [Civitai](https://civitai.com/) - Largest model repository
- [HuggingFace](https://huggingface.co/) - Open source models
- [Stability AI](https://stability.ai/) - Official SD models

### Community
- [ComfyUI Subreddit](https://reddit.com/r/ComfyUI) - User community
- [ComfyUI Discord](https://discord.gg/comfyui) - Real-time help
- [ComfyUI YouTube](https://youtube.com/results?search_query=comfyui+tutorial) - Video tutorials

### Related Projects
- [Automatic1111 WebUI](https://github.com/AUTOMATIC1111/stable-diffusion-webui) - Alternative interface
- [InvokeAI](https://github.com/invoke-ai/InvokeAI) - Node-based SD interface
- [DiffusionBee](https://diffusionbee.com/) - Mac-native SD app

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Development Setup
```bash
git clone https://github.com/yourusername/ComfyUI-Easy-Install-docker.git
cd ComfyUI-Easy-Install-docker
./setup.sh
# Make changes to Dockerfile, docker-compose.yml, etc.
docker-compose build --no-cache
docker-compose up -d
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [ComfyUI](https://github.com/comfyanonymous/ComfyUI) - The amazing interface
- [ComfyUI-Easy-Install](https://github.com/Tavris1/ComfyUI-Easy-Install) - Maintained node collection
- [Nvidia](https://nvidia.com) - GPU acceleration technology
- [Docker](https://docker.com) - Containerization platform

---

**Happy generating! 🎨**
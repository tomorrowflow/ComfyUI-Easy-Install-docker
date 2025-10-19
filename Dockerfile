# Use newer CUDA base image (12.4 is more recent and not deprecated)
FROM nvidia/cuda:12.4.0-runtime-ubuntu22.04

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

# Install PyTorch with CUDA support FIRST (required by many custom nodes)
RUN pip3 install --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# Clone the Easy Install repository
RUN echo "Cloning ComfyUI Easy Install..." && \
    git clone --single-branch --branch MAC-Linux \
    https://github.com/Tavris1/ComfyUI-Easy-Install.git /app/ComfyUI-Easy-Install

WORKDIR /app/ComfyUI-Easy-Install

# Make the installation script executable
RUN chmod +x ComfyUI-Easy-Install-Linux.sh || \
    chmod +x *.sh

# Run the Easy Install script
# The script should handle everything: ComfyUI clone, custom nodes, dependencies
RUN echo "Running Easy Install script..." && \
    bash -c './ComfyUI-Easy-Install-Linux.sh || echo "Script completed with warnings"'

# Verify ComfyUI was installed
RUN if [ ! -f "ComfyUI/main.py" ]; then \
        echo "ERROR: ComfyUI not installed by Easy Install script!"; \
        echo "Falling back to manual installation..."; \
        git clone https://github.com/comfyanonymous/ComfyUI.git; \
        cd ComfyUI && pip3 install -r requirements.txt; \
    else \
        echo "SUCCESS: ComfyUI installed by Easy Install script"; \
    fi

# Switch to ComfyUI directory
WORKDIR /app/ComfyUI-Easy-Install/ComfyUI

# Ensure requirements are installed (in case script skipped them)
RUN pip3 install --no-cache-dir -r requirements.txt || true

# Ensure ComfyUI Manager is installed
RUN if [ ! -d "custom_nodes/ComfyUI-Manager" ]; then \
        echo "Installing ComfyUI-Manager..."; \
        mkdir -p custom_nodes; \
        git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager; \
    fi

# Install requirements for all custom nodes that were installed by Easy Install
RUN echo "Installing custom node dependencies..." && \
    for dir in custom_nodes/*/; do \
        if [ -f "${dir}requirements.txt" ]; then \
            echo "  Installing requirements for ${dir}"; \
            pip3 install --no-cache-dir -r "${dir}requirements.txt" 2>/dev/null || \
            echo "  Warning: Some dependencies for ${dir} failed to install (non-critical)"; \
        fi; \
    done

# Create necessary model directories if they don't exist
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
    models/style_models \
    models/unet \
    output \
    input \
    user/default/workflows

# Install some common additional dependencies that nodes might need
RUN pip3 install --no-cache-dir \
    opencv-python \
    scikit-image \
    imageio \
    imageio-ffmpeg \
    scipy \
    numba \
    2>/dev/null || echo "Some optional dependencies failed (non-critical)"

# Expose port
EXPOSE 8188

# Start ComfyUI from the Easy Install directory
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
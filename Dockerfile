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
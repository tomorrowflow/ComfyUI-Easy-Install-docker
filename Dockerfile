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

# Install PyTorch with CUDA support first (CUDA 12.1 compatible)
RUN pip3 install --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Clone ComfyUI directly
RUN echo "Installing ComfyUI..." && \
    git clone https://github.com/comfyanonymous/ComfyUI.git /app/ComfyUI && \
    cd /app/ComfyUI && \
    pip3 install --no-cache-dir -r requirements.txt

WORKDIR /app/ComfyUI

# Install ComfyUI Manager
RUN echo "Installing ComfyUI Manager..." && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager

# Now clone Easy Install repo to get the custom nodes list
WORKDIR /tmp
RUN echo "Cloning Easy Install for custom nodes..." && \
    git clone --single-branch --branch MAC-Linux \
    https://github.com/Tavris1/ComfyUI-Easy-Install.git

# Install all custom nodes from Easy Install
WORKDIR /app/ComfyUI/custom_nodes

# WAS Node Suite
RUN echo "Installing WAS Node Suite..." && \
    git clone https://github.com/WASasquatch/was-node-suite-comfyui.git && \
    pip3 install --no-cache-dir -r was-node-suite-comfyui/requirements.txt 2>/dev/null || true

# Easy Use
RUN echo "Installing Easy-Use..." && \
    git clone https://github.com/yolain/ComfyUI-Easy-Use.git && \
    pip3 install --no-cache-dir -r ComfyUI-Easy-Use/requirements.txt 2>/dev/null || true

# ControlNet Auxiliary
RUN echo "Installing ControlNet Aux..." && \
    git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git && \
    pip3 install --no-cache-dir -r comfyui_controlnet_aux/requirements.txt 2>/dev/null || true

# Comfyroll Studio
RUN echo "Installing Comfyroll Studio..." && \
    git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git && \
    pip3 install --no-cache-dir -r ComfyUI_Comfyroll_CustomNodes/requirements.txt 2>/dev/null || true

# Crystools
RUN echo "Installing Crystools..." && \
    git clone https://github.com/crystian/ComfyUI-Crystools.git && \
    pip3 install --no-cache-dir -r ComfyUI-Crystools/requirements.txt 2>/dev/null || true

# rgthree
RUN echo "Installing rgthree..." && \
    git clone https://github.com/rgthree/rgthree-comfy.git

# GGUF
RUN echo "Installing GGUF..." && \
    git clone https://github.com/city96/ComfyUI-GGUF.git && \
    pip3 install --no-cache-dir -r ComfyUI-GGUF/requirements.txt 2>/dev/null || true

# Florence2
RUN echo "Installing Florence2..." && \
    git clone https://github.com/kijai/ComfyUI-Florence2.git && \
    pip3 install --no-cache-dir -r ComfyUI-Florence2/requirements.txt 2>/dev/null || true

# Video Helper Suite
RUN echo "Installing VideoHelperSuite..." && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    pip3 install --no-cache-dir -r ComfyUI-VideoHelperSuite/requirements.txt 2>/dev/null || true

# KJNodes
RUN echo "Installing KJNodes..." && \
    git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    pip3 install --no-cache-dir -r ComfyUI-KJNodes/requirements.txt 2>/dev/null || true

# Additional popular nodes (add more as needed)
RUN echo "Installing additional nodes..." && \
    git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git 2>/dev/null || true && \
    git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git 2>/dev/null || true

# Go back to ComfyUI directory
WORKDIR /app/ComfyUI

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
    models/style_models \
    models/unet \
    output \
    input \
    user/default/workflows

# Install additional common dependencies
RUN pip3 install --no-cache-dir \
    opencv-python \
    scikit-image \
    imageio \
    imageio-ffmpeg \
    scipy \
    numba

# Expose port
EXPOSE 8188

# Start ComfyUI
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
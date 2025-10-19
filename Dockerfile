# Use CUDA 12.4 base image
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

# Install PyTorch with CUDA 12.4 support first
RUN pip3 install --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# Install pygit2 for ComfyUI Manager git operations (missing from original!)
RUN pip3 install --no-cache-dir pygit2

# Clone ComfyUI directly
RUN echo "Installing ComfyUI..." && \
    git clone https://github.com/comfyanonymous/ComfyUI.git /app/ComfyUI

WORKDIR /app/ComfyUI

# Install ComfyUI requirements
RUN pip3 install --no-cache-dir -r requirements.txt

# Create custom_nodes directory
RUN mkdir -p custom_nodes

WORKDIR /app/ComfyUI/custom_nodes

# Install ALL custom nodes from Easy Install list (in correct order)
# Core Management
RUN echo "Installing ComfyUI-Manager..." && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# Essential Node Suites
RUN echo "Installing WAS Node Suite..." && \
    git clone https://github.com/WASasquatch/was-node-suite-comfyui.git && \
    pip3 install --no-cache-dir -r was-node-suite-comfyui/requirements.txt || true

RUN echo "Installing Easy-Use..." && \
    git clone https://github.com/yolain/ComfyUI-Easy-Use.git && \
    pip3 install --no-cache-dir -r ComfyUI-Easy-Use/requirements.txt || true

# ControlNet and Image Processing
RUN echo "Installing ControlNet Aux..." && \
    git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git && \
    pip3 install --no-cache-dir -r comfyui_controlnet_aux/requirements.txt || true

# Workflow Utilities
RUN echo "Installing Comfyroll Studio..." && \
    git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git && \
    pip3 install --no-cache-dir -r ComfyUI_Comfyroll_CustomNodes/requirements.txt || true

RUN echo "Installing Crystools..." && \
    git clone https://github.com/crystian/ComfyUI-Crystools.git && \
    pip3 install --no-cache-dir -r ComfyUI-Crystools/requirements.txt || true

RUN echo "Installing rgthree..." && \
    git clone https://github.com/rgthree/rgthree-comfy.git

RUN echo "Installing KJNodes..." && \
    git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    pip3 install --no-cache-dir -r ComfyUI-KJNodes/requirements.txt || true

# Model Format Support
RUN echo "Installing GGUF support..." && \
    git clone https://github.com/city96/ComfyUI-GGUF.git && \
    pip3 install --no-cache-dir -r ComfyUI-GGUF/requirements.txt || true

# Vision and Language Models
RUN echo "Installing Florence2..." && \
    git clone https://github.com/kijai/ComfyUI-Florence2.git && \
    pip3 install --no-cache-dir -r ComfyUI-Florence2/requirements.txt || true

RUN echo "Installing Searge LLM..." && \
    git clone https://github.com/SeargeDP/ComfyUI_Searge_LLM.git && \
    pip3 install --no-cache-dir -r ComfyUI_Searge_LLM/requirements.txt || true

RUN echo "Installing ControlAltAI Nodes..." && \
    git clone https://github.com/gseth/ControlAltAI-Nodes.git && \
    pip3 install --no-cache-dir -r ControlAltAI-Nodes/requirements.txt || true

RUN echo "Installing Ollama..." && \
    git clone https://github.com/stavsap/comfyui-ollama.git && \
    pip3 install --no-cache-dir -r comfyui-ollama/requirements.txt || true

# Tools and Utilities
RUN echo "Installing iTools..." && \
    git clone https://github.com/MohammadAboulEla/ComfyUI-iTools.git && \
    pip3 install --no-cache-dir -r ComfyUI-iTools/requirements.txt || true

RUN echo "Installing Seamless Tiling..." && \
    git clone https://github.com/spinagon/ComfyUI-seamless-tiling.git

RUN echo "Installing Inpaint CropAndStitch..." && \
    git clone https://github.com/lquesada/ComfyUI-Inpaint-CropAndStitch.git

RUN echo "Installing Canvas Tab..." && \
    git clone https://github.com/Lerc/canvas_tab.git

# Advanced Generation
RUN echo "Installing OmniGen..." && \
    git clone https://github.com/1038lab/ComfyUI-OmniGen.git && \
    pip3 install --no-cache-dir -r ComfyUI-OmniGen/requirements.txt || true

RUN echo "Installing Inspyrenet Rembg..." && \
    git clone https://github.com/john-mnz/ComfyUI-Inspyrenet-Rembg.git && \
    pip3 install --no-cache-dir -r ComfyUI-Inspyrenet-Rembg/requirements.txt || true

RUN echo "Installing Advanced Redux Control..." && \
    git clone https://github.com/kaibioinfo/ComfyUI_AdvancedRefluxControl.git && \
    pip3 install --no-cache-dir -r ComfyUI_AdvancedRefluxControl/requirements.txt || true

# Video Processing
RUN echo "Installing VideoHelperSuite..." && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git && \
    pip3 install --no-cache-dir -r ComfyUI-VideoHelperSuite/requirements.txt || true

RUN echo "Installing AdvancedLivePortrait..." && \
    git clone https://github.com/PowerHouseMan/ComfyUI-AdvancedLivePortrait.git && \
    pip3 install --no-cache-dir -r ComfyUI-AdvancedLivePortrait/requirements.txt || true

RUN echo "Installing LTXVideo..." && \
    git clone https://github.com/Lightricks/ComfyUI-LTXVideo.git && \
    pip3 install --no-cache-dir -r ComfyUI-LTXVideo/requirements.txt || true

# Graphics and Export
RUN echo "Installing ToSVG..." && \
    git clone https://github.com/Yanick112/ComfyUI-ToSVG.git && \
    pip3 install --no-cache-dir -r ComfyUI-ToSVG/requirements.txt || true

# Audio and Voice
RUN echo "Installing Kokoro..." && \
    git clone https://github.com/stavsap/comfyui-kokoro.git && \
    pip3 install --no-cache-dir -r comfyui-kokoro/requirements.txt || true

# Additional Models
RUN echo "Installing Janus Pro..." && \
    git clone https://github.com/CY-CHENYUE/ComfyUI-Janus-Pro.git && \
    pip3 install --no-cache-dir -r ComfyUI-Janus-Pro/requirements.txt || true

RUN echo "Installing Sonic..." && \
    git clone https://github.com/smthemex/ComfyUI_Sonic.git && \
    pip3 install --no-cache-dir -r ComfyUI_Sonic/requirements.txt || true

RUN echo "Installing TeaCache..." && \
    git clone https://github.com/welltop-cn/ComfyUI-TeaCache.git && \
    pip3 install --no-cache-dir -r ComfyUI-TeaCache/requirements.txt || true

RUN echo "Installing KayTool..." && \
    git clone https://github.com/kk8bit/KayTool.git && \
    pip3 install --no-cache-dir -r KayTool/requirements.txt || true

RUN echo "Installing Tiled Diffusion & VAE..." && \
    git clone https://github.com/shiimizu/ComfyUI-TiledDiffusion.git && \
    pip3 install --no-cache-dir -r ComfyUI-TiledDiffusion/requirements.txt || true

# Audio and Voice (existing)
RUN echo "Installing Kokoro..." && \
    git clone https://github.com/stavsap/comfyui-kokoro.git && \
    pip3 install --no-cache-dir -r comfyui-kokoro/requirements.txt || true

# Add VibeVoice here
RUN echo "Installing VibeVoice..." && \
    git clone https://github.com/Enemyx-net/VibeVoice-ComfyUI.git && \
    pip3 install --no-cache-dir -r VibeVoice-ComfyUI/requirements.txt || true

# Additional Models (continue with rest)
RUN echo "Installing Janus Pro..." && \
    git clone https://github.com/CY-CHENYUE/ComfyUI-Janus-Pro.git && \
    pip3 install --no-cache-dir -r ComfyUI-Janus-Pro/requirements.txt || true

# Additional helpful nodes
RUN echo "Installing Impact Pack..." && \
    git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && \
    pip3 install --no-cache-dir -r ComfyUI-Impact-Pack/requirements.txt || true

# Go back to ComfyUI root directory
WORKDIR /app/ComfyUI

# Install onnxruntime-gpu for ONNX model support (missing from original!)
RUN pip3 install --no-cache-dir onnxruntime-gpu || \
    echo "Warning: onnxruntime-gpu installation failed (non-critical)"

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
    models/gligen \
    models/photomaker \
    models/insightface \
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
    numba \
    insightface \
    || echo "Some optional dependencies failed (non-critical)"

# Expose port
EXPOSE 8188

# Start ComfyUI
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
# ========= BASE IMAGE (Blackwell-Compatible CUDA 12.8) =========
FROM nvidia/cuda:12.8.0-runtime-ubuntu22.04

ARG BUILDKIT_INLINE_CACHE=1

ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_NO_CACHE_DIR=1

# ========= SYSTEM DEPS =========
RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv \
    git git-lfs wget curl ffmpeg \
    bash zsh procps openssh-client ncurses-term locales \
    libgl1 libglib2.0-0 nano ttyd \
    build-essential ninja-build \
    libsndfile1 sqlite3 \
    && git lfs install \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/python3 /usr/bin/python || true
RUN ln -s /usr/bin/pip3 /usr/bin/pip || true

# ========= PYTORCH (Blackwell / 5090 native) =========
RUN pip install --upgrade pip && \
    pip install --no-cache-dir \
        torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 && \
    rm -rf /root/.cache /tmp/*

# ========= COMFYUI =========
WORKDIR /app
RUN git clone https://github.com/comfyanonymous/ComfyUI.git

WORKDIR /app/ComfyUI

# Prevent requirements.txt from downgrading torch
RUN sed -i '/torch/d' requirements.txt && \
    sed -i '/torchvision/d' requirements.txt && \
    sed -i '/torchaudio/d' requirements.txt

# ========= COMFY CORE DEPS =========
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir torchsde

# ========= WORKSPACE =========
RUN mkdir -p \
    /workspace/ComfyUI/models \
    /workspace/ComfyUI/input \
    /workspace/ComfyUI/output \
    /workspace/ComfyUI/user/default/workflows \
    /workspace/ComfyUI/db

RUN chmod -R 777 /workspace || true

RUN rm -rf /app/ComfyUI/models
RUN ln -s /workspace/ComfyUI/models /app/ComfyUI/models

# ========= DIFFUSERS / ACCELERATE =========
RUN pip install --no-cache-dir \
    accelerate==1.10.1 \
    diffusers==0.35.1 \
    huggingface-hub \
    numpy \
    Pillow \
    pyyaml \
    psutil \
    regex \
    requests \
    safetensors

# ========= SAGEATTENTION =========
ENV TORCH_CUDA_ARCH_LIST="8.9+PTX"
ENV SAGE_ATTENTION=1

RUN pip install --no-cache-dir ninja && \
    pip install --no-cache-dir sageattention==1.0.6

# ========= IMAGE / VIDEO / AUDIO CORE =========
RUN pip install --no-cache-dir \
    av \
    ffmpeg-python \
    imageio \
    imageio-ffmpeg \
    matplotlib \
    onnx \
    onnxruntime \
    onnxruntime-gpu \
    opencv-python \
    opencv-python-headless \
    pycocotools \
    scikit-image \
    transformers

# ========= GENERAL EXTRA DEPS =========
RUN pip install --no-cache-dir \
    aiohttp \
    ftfy \
    moviepy \
    numba \
    pydub \
    pytz \
    scipy \
    shapely \
    soundfile \
    mediapipe

# ========= JUPYTER =========
RUN pip install --no-cache-dir jupyterlab
RUN ln -sf /bin/bash /usr/bin/bash || true

# ========= CORE NODE FIXES =========
RUN pip install --no-cache-dir \
    clip-interrogator==0.6.0 \
    gguf \
    ollama \
    surrealist \
    timm \
    websockets

# ========= FAST LLAMA-CPP =========
RUN pip install --no-cache-dir \
    llama-cpp-python==0.2.82 \
    --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cu124

# ========= CUSTOM NODE DEPENDENCIES (ALL CLEANED & VERIFIED) =========
RUN pip install --no-cache-dir \
    absl-py \
    accelerate>=0.20.0 \
    addict \
    albumentations>=1.4.16 \
    argostranslate \
    boto3 \
    cachetools \
    civitai \
    cmake \
    colour-science \
    conformer \
    diffusers>=0.31.0 \
    einops \
    evalidate \
    fairscale>=0.4.4 \
    fal-client \
    gdown \
    git+https://github.com/WASasquatch/ffmpy.git \
    git+https://github.com/WASasquatch/img2texture.git \
    git+https://github.com/WASasquatch/cstr \
    gitpython \
    imageio \
    joblib \
    json-repair \
    kornia \
    langdetect \
    librosa \
    lark \
    loguru \
    matplotlib \
    ml-collections \
    moderngl \
    moviepy==1.0.3 \
    mss \
    numba \
    numpy \
    ollama \
    onnxruntime-gpu \
    "opencv-contrib-python>=4.7.0.72" \
    "opencv-python-headless[ffmpeg]" \
    openai \
    OpenImageIO \
    open_clip_torch \
    opensimplex \
    opencv-python \
    packaging \
    pandas \
    peft>=0.15.0 \
    piexif \
    pilgram \
    pillow \
    plyfile \
    protobuf \
    psutil \
    pydub>=0.25.1 \
    PyGithub \
    pyOpenSSL \
    pypdf2 \
    pymatting \
    pyyaml \
    qrcode[pil] \
    rembg \
    reportlab \
    requests \
    retina-face \
    rich \
    rich_argparse \
    rotary_embedding_torch \
    runpod \
    scenedetect[opencv-headless] \
    scikit-image>=0.20.0 \
    scikit-learn \
    sentencepiece \
    simpleeval \
    sounddevice \
    soundfile \
    spacy \
    spandrel \
    tifffile \
    timm>=0.4.12 \
    tokenizers \
    torchaudio \
    tqdm \
    transformers \
    trimesh \
    transparent-background \
    typer \
    ultralytics \
    webcolors \
    yapf \
    zhipuai

# ========= CUSTOM NODES =========
RUN set -eux; \
    clone() { for i in 1 2 3 4 5; do git clone --depth 1 "$1" "$2" && break || { echo "Retrying $1"; sleep 5; }; done; }; \
    \
    clone https://github.com/ltdrdata/ComfyUI-Impact-Pack           /app/ComfyUI/custom_nodes/ComfyUI-Impact-Pack; \
    clone https://github.com/city96/ComfyUI-GGUF                    /app/ComfyUI/custom_nodes/ComfyUI-GGUF; \
    clone https://github.com/cubiq/ComfyUI_essentials               /app/ComfyUI/custom_nodes/ComfyUI_essentials; \
    clone https://github.com/justUmen/Bjornulf_custom_nodes         /app/ComfyUI/custom_nodes/Bjornulf_custom_nodes; \
    clone https://github.com/MohammadAboulEla/ComfyUI-iTools        /app/ComfyUI/custom_nodes/ComfyUI-iTools; \
    clone https://github.com/WaveSpeedAI/wavespeed-comfyui          /app/ComfyUI/custom_nodes/wavespeed-comfyui; \
    clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts   /app/ComfyUI/custom_nodes/ComfyUI-Custom-Scripts; \
    clone https://github.com/rgthree/rgthree-comfy                  /app/ComfyUI/custom_nodes/rgthree-comfy; \
    clone https://github.com/yolain/ComfyUI-Easy-Use                /app/ComfyUI/custom_nodes/ComfyUI-Easy-Use; \
    clone https://github.com/kijai/ComfyUI-KJNodes                  /app/ComfyUI/custom_nodes/ComfyUI-KJNodes; \
    clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite   /app/ComfyUI/custom_nodes/ComfyUI-VideoHelperSuite; \
    clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation /app/ComfyUI/custom_nodes/ComfyUI-Frame-Interpolation; \
    clone https://github.com/1038lab/ComfyUI-MiniCPM                /app/ComfyUI/custom_nodes/ComfyUI-MiniCPM; \
    clone https://github.com/ServiceStack/comfy-asset-downloader    /app/ComfyUI/custom_nodes/comfy-asset-downloader; \
    clone https://github.com/ltdrdata/ComfyUI-Manager               /app/ComfyUI/custom_nodes/ComfyUI-Manager; \
    clone https://github.com/kijai/ComfyUI-WanVideoWrapper          /app/ComfyUI/custom_nodes/ComfyUI-WanVideoWrapper; \
    clone https://github.com/kijai/ComfyUI-segment-anything-2       /app/ComfyUI/custom_nodes/ComfyUI-segment-anything-2; \
    clone https://github.com/un-seen/comfyui-tensorops              /app/ComfyUI/custom_nodes/comfyui-tensorops

# ========= START SCRIPT =========
WORKDIR /app
RUN bash -c "cat > /start.sh" << 'EOF'
#!/bin/bash
echo "[START] Ensuring workspace permissions..."
chmod -R 777 /workspace || true

echo "[START] Checking GPU..."
if ! command -v nvidia-smi &> /dev/null; then
  echo "❌ NVIDIA driver not found!"
else
  echo "✅ GPU detected:"
  nvidia-smi
fi

echo "[START] Launching ComfyUI..."
cd /app/ComfyUI
python main.py --listen 0.0.0.0 --port=3000 --user-directory /workspace/ComfyUI/user &

sleep 3

echo "[START] Launching JupyterLab..."
jupyter lab \
  --no-browser \
  --ServerApp.ip=0.0.0.0 \
  --ServerApp.port=8888 \
  --ServerApp.root_dir=/workspace \
  --ServerApp.token='' \
  --ServerApp.password='' \
  --ServerApp.disable_check_xsrf=True \
  --allow-root \
  > /workspace/jupyter.log 2>&1 &

echo "[START] Launching ttyd..."
ttyd -p 9090 bash >> /workspace/ttyd.log 2>&1 &

echo "[START] All services running."
tail -f /dev/null
EOF

RUN chmod +x /start.sh

EXPOSE 3000 8888 9090
ENTRYPOINT ["/start.sh"]

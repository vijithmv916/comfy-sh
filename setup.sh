%%bash
# Clone ComfyUI repository
git clone https://github.com/comfyanonymous/ComfyUI.git

# Install ComfyUI dependencies
pip install xformers!=0.0.18 -r ComfyUI/requirements.txt --extra-index-url https://download.pytorch.org/whl/cu121 --extra-index-url https://download.pytorch.org/whl/cu118 --extra-index-url https://download.pytorch.org/whl/cu117

# Clone ComfyUI-Manager into the custom_nodes directory
git clone https://github.com/ltdrdata/ComfyUI-Manager.git ComfyUI/custom_nodes/ComfyUI-Manager

# Install ComfyUI-Manager dependencies
pip install -r ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt

# Create directory for models
mkdir -p ComfyUI/models/checkpoints

# Download the SD1.5 model
wget -c https://huggingface.co/Comfy-Org/stable-diffusion-v1-5-archive/resolve/main/v1-5-pruned-emaonly-fp16.safetensors -P ComfyUI/models/checkpoints/

# Install cloudflared for tunneling
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared
chmod +x /usr/local/bin/cloudflared

# Start ComfyUI in the background
python ComfyUI/main.py --dont-print-server &

# Wait for ComfyUI to start
echo "Waiting for ComfyUI to start..."
sleep 30

# Start cloudflared tunnel to expose ComfyUI publicly
echo "Starting cloudflared tunnel..."
cloudflared tunnel --url http://localhost:8188

#!/bin/sh

# Clone ComfyUI repository
git clone https://github.com/comfyanonymous/ComfyUI.git

# Change to ComfyUI directory
cd ComfyUI || { echo "Failed to cd to ComfyUI"; exit 1; }

# Install dependencies
pip install xformers!=0.0.18 -r requirements.txt \
    --extra-index-url https://download.pytorch.org/whl/cu121 \
    --extra-index-url https://download.pytorch.org/whl/cu118 \
    --extra-index-url https://download.pytorch.org/whl/cu117

# Change to custom_nodes directory
cd custom_nodes || { echo "Failed to cd to custom_nodes"; exit 1; }

# Clone ComfyUI-Manager into custom_nodes
git clone https://github.com/Comfy-Org/ComfyUI-Manager.git

# Return to ComfyUI directory
cd .. || { echo "Failed to cd to ComfyUI"; exit 1; }

# Download and install cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# Start cloudflared tunnel in the background
echo "Starting cloudflared tunnel..."
cloudflared tunnel --url http://127.0.0.1:8188 > cloudflared.log 2>&1 &
CLOUDFLARED_PID=$!

# Wait for cloudflared to initialize and extract URL
echo "Waiting for cloudflared URL..."
i=0
while [ "$i" -lt 30 ]; do
    sleep 2
    if grep -q "trycloudflare.com" cloudflared.log; then
        URL=$(grep "trycloudflare.com" cloudflared.log | awk '{print $NF}' | head -1)
        echo "This is the URL to access ComfyUI: $URL"
        break
    fi
    i=$((i + 1))
done

# Start ComfyUI
python main.py --dont-print-server

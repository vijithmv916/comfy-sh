#!/bin/bash

# Clone ComfyUI repository
git clone https://github.com/comfyanonymous/ComfyUI.git

# Change to ComfyUI directory
cd ComfyUI

# Install dependencies
pip install xformers!=0.0.18 -r requirements.txt \
    --extra-index-url https://download.pytorch.org/whl/cu121 \
    --extra-index-url https://download.pytorch.org/whl/cu118 \
    --extra-index-url https://download.pytorch.org/whl/cu117

# Change to custom_nodes directory
cd custom_nodes

# Clone ComfyUI-Manager into custom_nodes
git clone https://github.com/Comfy-Org/ComfyUI-Manager.git

# Return to ComfyUI directory
cd ..

# Download and install cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
dpkg -i cloudflared-linux-amd64.deb

# Start cloudflared tunnel in the background
echo "Starting cloudflared tunnel..."
cloudflared tunnel --url http://127.0.0.1:8188 > cloudflared.log 2>&1 &
CLOUDFLARED_PID=$!

# Wait for cloudflared to initialize and extract URL
echo "Waiting for cloudflared URL..."
for ((i=0; i<30; i++)); do
    sleep 2
    if grep -q "trycloudflare.com" cloudflared.log; then
        URL=$(grep "trycloudflare.com" cloudflared.log | awk '{print $NF}' | head -1)
        echo "This is the URL to access ComfyUI: $URL"
        break
    fi
done

# Start ComfyUI
python main.py --dont-print-server

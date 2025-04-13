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

# Download and set up ngrok
echo "Downloading ngrok..."
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar -xzf ngrok-v3-stable-linux-amd64.tgz
chmod +x ngrok

# Start ngrok tunnel in the background
echo "Starting ngrok tunnel..."
./ngrok http 8188 > ngrok.log 2>&1 &
NGROK_PID=$!

# Wait for ngrok to initialize and extract URL
echo "Waiting for ngrok URL..."
i=0
while [ "$i" -lt 30 ]; do
    sleep 2
    if grep -q "https://.*.ngrok-free.app" ngrok.log; then
        URL=$(grep "https://.*.ngrok-free.app" ngrok.log | awk '{print $NF}' | head -1)
        echo "This is the URL to access ComfyUI: $URL"
        break
    fi
    i=$((i + 1))
done

# Start ComfyUI
python main.py --dont-print-server

#!/bin/sh

# Configuration for reverse SSH (CUSTOMIZE THESE)
SERVER="YOUR_SERVER"          # Public server IP or hostname (e.g., 203.0.113.1)
USER="YOUR_USER"              # SSH user on public server (e.g., ubuntu)
PUBLIC_PORT="8080"            # Port on public server to forward (e.g., 8080)
LOCAL_PORT="8188"             # Local ComfyUI port (default: 8188)
SSH_KEY="~/.ssh/id_rsa"       # Path to SSH private key (or leave empty if using password)

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

# Start reverse SSH tunnel in the background
echo "Starting reverse SSH tunnel to $SERVER..."
if [ -n "$SSH_KEY" ]; then
    ssh -f -N -R "$PUBLIC_PORT:localhost:$LOCAL_PORT" "$USER@$SERVER" -i "$SSH_KEY" || {
        echo "Failed to start SSH tunnel"; exit 1;
    }
else
    ssh -f -N -R "$PUBLIC_PORT:localhost:$LOCAL_PORT" "$USER@$SERVER" || {
        echo "Failed to start SSH tunnel"; exit 1;
    }
fi
SSH_PID=$!

# Verify tunnel is running
echo "Verifying SSH tunnel..."
i=0
while [ "$i" -lt 10 ]; do
    sleep 1
    if ps | grep "$SSH_PID" | grep -q ssh; then
        echo "SSH tunnel established."
        echo "Access ComfyUI at: http://$SERVER:$PUBLIC_PORT"
        break
    fi
    i=$((i + 1))
done
if [ "$i" -eq 10 ]; then
    echo "SSH tunnel failed to start. Check SSH configuration."
    exit 1
fi

# Start ComfyUI
echo "Starting ComfyUI..."
python main.py --dont-print-server

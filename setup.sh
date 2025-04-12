#!/bin/bash

# Exit on any error
set -e

# Configuration variables
WORKSPACE="ComfyUI"
COMFYUI_PORT=8188

echo "Starting ComfyUI setup..."

# Step 1: Install system dependencies
echo "Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y python3-venv python3-pip git nodejs npm

# Step 2: Clone ComfyUI repository if not already present
if [ ! -d "$WORKSPACE" ]; then
    echo "Cloning ComfyUI repository..."
    git clone https://github.com/comfyanonymous/ComfyUI.git $WORKSPACE
fi

cd $WORKSPACE

# Step 3: Update ComfyUI
echo "Updating ComfyUI..."
git pull

# Step 4: Create and activate virtual environment
echo "Setting up virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Step 5: Install Python dependencies
echo "Installing Python dependencies..."
pip install --upgrade pip
pip install xformers -r requirements.txt --extra-index-url https://download.pytorch.org/whl/cu121

# Step 6: Install ComfyUI Manager
echo "Installing ComfyUI Manager..."
cd custom_nodes
if [ ! -d "ComfyUI-Manager" ]; then
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git
else
    cd ComfyUI-Manager
    git pull
    cd ..
fi
cd ..

# Step 7: Install a default checkpoint model (SD1.5, as in the notebook)
echo "Downloading a default checkpoint model..."
mkdir -p models/checkpoints
CHECKPOINT_URL="https://huggingface.co/Comfy-Org/stable-diffusion-v1-5-archive/resolve/main/v1-5-pruned-emaonly-fp16.safetensors"
CHECKPOINT_FILE="models/checkpoints/v1-5-pruned-emaonly-fp16.safetensors"
if [ ! -f "$CHECKPOINT_FILE" ]; then
    wget -c $CHECKPOINT_URL -P models/checkpoints/
fi

# Step 8: Install localtunnel
echo "Installing localtunnel..."
sudo npm install -g localtunnel

# Step 9: Start ComfyUI with localtunnel
echo "Starting ComfyUI with localtunnel..."

# Function to run localtunnel and capture the URL
run_localtunnel() {
    while true; do
        sleep 0.5
        if nc -z 127.0.0.1 $COMFYUI_PORT > /dev/null 2>&1; then
            break
        fi
    done
    echo "ComfyUI is running, launching localtunnel..."
    IP=$(curl -s https://ipv4.icanhazip.com)
    echo "The password/endpoint IP for localtunnel is: $IP"
    lt --port $COMFYUI_PORT
}

# Run localtunnel in the background
run_localtunnel &

# Start ComfyUI
python main.py --dont-print-server --port $COMFYUI_PORT

echo "ComfyUI setup complete. Access it via the localtunnel URL provided above."

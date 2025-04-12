#!/bin/bash

# install_comfyui.sh
# Installs ComfyUI, ComfyUI-Manager, and sets up a public link with cloudflared
# Usage: curl -sSf <raw-url> | sh -s run

set -e  # Exit on error

# Print usage information
usage() {
  echo "Usage: $0 run"
  echo "Example: curl -sSf <raw-url> | sh -s run"
  echo "Installs ComfyUI and ComfyUI-Manager in ~/comfyui and starts with a public link"
  exit 1
}

# Check if argument is provided
[ -z "$1" ] && usage
[ "$1" != "run" ] && usage

# Variables
INSTALL_DIR="$HOME/comfyui"
COMFYUI_REPO="https://github.com/comfyanonymous/ComfyUI.git"
MANAGER_REPO="https://github.com/ltdrdata/ComfyUI-Manager.git"
MODEL_URL="https://huggingface.co/Comfy-Org/stable-diffusion-v1-5-archive/resolve/main/v1-5-pruned-emaonly-fp16.safetensors"
MODEL_DIR="$INSTALL_DIR/models/checkpoints"
PYTHON_MIN_VERSION="3.10"
VENV_DIR="$INSTALL_DIR/venv"
CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check for prerequisites
check_prerequisites() {
  echo "Checking prerequisites..."

  # Check for git
  if ! command -v git >/dev/null 2>&1; then
    echo -e "${RED}Error: git is not installed. Please install git.${NC}"
    exit 1
  fi

  # Check for python
  if ! command -v python3 >/dev/null 2>&1; then
    echo -e "${RED}Error: python3 is not installed. Please install Python $PYTHON_MIN_VERSION or higher.${NC}"
    exit 1
  fi

  # Check Python version
  PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
  if [ "$(printf '%s\n' "$PYTHON_VERSION" "$PYTHON_MIN_VERSION" | sort -V | head -n1)" != "$PYTHON_MIN_VERSION" ]; then
    echo -e "${RED}Error: Python $PYTHON_MIN_VERSION or higher is required. Found Python $PYTHON_VERSION.${NC}"
    exit 1
  fi

  # Check for pip
  if ! python3 -m pip --version >/dev/null 2>&1; then
    echo -e "${RED}Error: pip is not installed. Please install pip for Python3.${NC}"
    exit 1
  fi

  # Check for wget
  if ! command -v wget >/dev/null 2>&1; then
    echo -e "${RED}Error: wget is not installed. Please install wget.${NC}"
    exit 1
  fi
}

# Install ComfyUI
install_comfyui() {
  echo "Installing ComfyUI in $INSTALL_DIR..."

  # Create install directory
  if [ -d "$INSTALL_DIR" ]; then
    echo "Directory $INSTALL_DIR already exists. Updating..."
    cd "$INSTALL_DIR"
    git pull || {
      echo -e "${RED}Error: Failed to update ComfyUI repository.${NC}"
      exit 1
    }
  else
    git clone "$COMFYUI_REPO" "$INSTALL_DIR" || {
      echo -e "${RED}Error: Failed to clone ComfyUI repository.${NC}"
      exit 1
    }
    cd "$INSTALL_DIR"
  fi

  # Set up virtual environment
  if [ -d "$VENV_DIR" ]; then
    echo "Virtual environment already exists in $VENV_DIR."
  else
    python3 -m venv "$VENV_DIR" || {
      echo -e "${RED}Error: Failed to create virtual environment.${NC}"
      exit 1
    }
  fi

  # Activate virtual environment
  source "$VENV_DIR/bin/activate" || {
    echo -e "${RED}Error: Failed to activate virtual environment.${NC}"
    exit 1
  }

  # Upgrade pip
  pip install --upgrade pip || {
    echo -e "${RED}Error: Failed to upgrade pip.${NC}"
    exit 1
  }

  # Install PyTorch (CPU version for portability; GPU needs manual setup)
  pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu || {
    echo -e "${RED}Error: Failed to install PyTorch.${NC}"
    exit 1
  }

  # Install ComfyUI dependencies
  pip install -r requirements.txt || {
    echo -e "${RED}Error: Failed to install ComfyUI dependencies.${NC}"
    exit 1
  }
}

# Install ComfyUI-Manager
install_manager() {
  echo "Installing ComfyUI-Manager..."

  MANAGER_DIR="$INSTALL_DIR/custom_nodes/ComfyUI-Manager"
  if [ -d "$MANAGER_DIR" ]; then
    echo "ComfyUI-Manager already installed in $MANAGER_DIR. Updating..."
    cd "$MANAGER_DIR"
    git pull || {
      echo -e "${RED}Error: Failed to update ComfyUI-Manager repository.${NC}"
      exit 1
    }
  else
    git clone "$MANAGER_REPO" "$MANAGER_DIR" || {
      echo -e "${RED}Error: Failed to clone ComfyUI-Manager repository.${NC}"
      exit 1
    }
  fi

  # Install Manager dependencies
  cd "$MANAGER_DIR"
  pip install -r requirements.txt || {
    echo -e "${RED}Error: Failed to install ComfyUI-Manager dependencies.${NC}"
    exit 1
  }
}

# Download a model (SD1.5 as per notebook)
download_model() {
  echo "Downloading Stable Diffusion 1.5 model..."

  mkdir -p "$MODEL_DIR"
  MODEL_FILE="$MODEL_DIR/v1-5-pruned-emaonly-fp16.safetensors"
  if [ -f "$MODEL_FILE" ]; then
    echo "Model already exists in $MODEL_FILE. Skipping download."
  else
    wget -c "$MODEL_URL" -P "$MODEL_DIR" || {
      echo -e "${RED}Error: Failed to download SD1.5 model.${NC}"
      exit 1
    }
  fi
}

# Install cloudflared
install_cloudflared() {
  echo "Installing cloudflared..."

  if command -v cloudflared >/dev/null 2>&1; then
    echo "cloudflared already installed."
  else
    wget "$CLOUDFLARED_URL" -O /tmp/cloudflared || {
      echo -e "${RED}Error: Failed to download cloudflared.${NC}"
      exit 1
    }
    chmod +x /tmp/cloudflared
    sudo mv /tmp/cloudflared /usr/local/bin/cloudflared || {
      echo -e "${RED}Error: Failed to install cloudflared.${NC}"
      exit 1
    }
  fi
}

# Start ComfyUI with cloudflared
start_comfyui() {
  echo "Starting ComfyUI with cloudflared..."

  # Activate virtual environment
  source "$VENV_DIR/bin/activate" || {
    echo -e "${RED}Error: Failed to activate virtual environment.${NC}"
    exit 1
  }

  cd "$INSTALL_DIR"

  # Start ComfyUI in the background
  python main.py --dont-print-server &
  COMFYUI_PID=$!

  # Wait for ComfyUI to start
  echo "Waiting for ComfyUI to start..."
  for i in {1..30}; do
    if curl -s http://127.0.0.1:8188 >/dev/null; then
      echo "ComfyUI is running."
      break
    fi
    sleep 1
  done

  # Start cloudflared
  echo "Starting cloudflared tunnel..."
  cloudflared tunnel --url http://127.0.0.1:8188 | grep -o 'https://.*trycloudflare.com' || {
    echo -e "${RED}Error: Failed to start cloudflared tunnel.${NC}"
    kill $COMFYUI_PID
    exit 1
  }

  # Keep script running to maintain ComfyUI process
  wait $COMFYUI_PID
}

# Provide post-installation instructions
post_install() {
  echo -e "${GREEN}Setup complete!${NC}"
  echo "ComfyUI is running with a public URL (check above for the trycloudflare.com link)."
  echo "To restart manually:"
  echo "  cd $INSTALL_DIR"
  echo "  source $VENV_DIR/bin/activate"
  echo "  python main.py"
  echo "ComfyUI-Manager is accessible in the ComfyUI interface."
  echo "Note: For GPU support, manually install PyTorch with CUDA."
}

# Main function
main() {
  check_prerequisites
  install_comfyui
  install_manager
  download_model
  install_cloudflared
  start_comfyui
  post_install
}

# Run main function
main

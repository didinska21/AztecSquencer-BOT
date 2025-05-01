#!/usr/bin/env bash
set -euo pipefail

CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Teks Banner yang sudah diubah
BANNER_TEXT="AZTEC NODE"
SUB_TEXT="Squencer"
OWNER_TEXT="owner: t.me/didinska"

# Banner
echo -e "${CYAN}${BOLD}"
cat << EOF
██████╗ ███████╗████████╗███████╗███████╗██████╗ 
██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔════╝██╔══██╗
██║  ██║█████╗     ██║   █████╗  █████╗  ██████╔╝
██║  ██║██╔══╝     ██║   ██╔══╝  ██╔══╝  ██╔══██╗
██████╔╝███████╗   ██║   ███████╗███████╗██║  ██║
╚═════╝ ╚══════╝   ╚═╝   ╚══════╝╚══════╝╚═╝  ╚═╝
EOF
echo -e "${RESET}"
echo -e "${CYAN}${BOLD}${BANNER_TEXT}${RESET}"
echo -e "${CYAN}${BOLD}${SUB_TEXT}${RESET}"
echo -e "${CYAN}${BOLD}${OWNER_TEXT}${RESET}\n"

# ====================================================
# Aztec alpha-testnet full node automated installation & startup script
# Version: v0.85.0-alpha-testnet.5
# For Ubuntu/Debian only, requires sudo privileges
# ====================================================

if [ "$(id -u)" -ne 0 ]; then
  echo "⚠️ Script ini harus dijalankan dengan akses root (sudo)."
  exit 1
fi

if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
  echo "🐋 Docker atau Docker Compose belum ditemukan. Menginstal..."
  apt-get update
  apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable"
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io
  curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
else
  echo "🐋 Docker dan Docker Compose sudah terinstal."
fi

if ! command -v node &> /dev/null; then
  echo "🟢 Node.js belum ditemukan. Menginstal versi terbaru..."
  curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
  apt-get install -y nodejs
else
  echo "🟢 Node.js sudah terinstal."
fi

echo "⚙️  Menginstal Aztec CLI dan menyiapkan alpha-testnet..."
curl -sL https://install.aztec.network | bash

export PATH="$HOME/.aztec/bin:$PATH"

if ! command -v aztec-up &> /dev/null; then
  echo "❌ Instalasi Aztec CLI gagal."
  exit 1
fi

aztec-up alpha-testnet

echo -e "\n${CYAN}Silakan siapkan URL RPC berikut:${RESET}"
echo "  - L1 Execution (EL) RPC:"
echo "    https://dashboard.alchemy.com (buat app untuk Sepolia)"
echo "  - L1 Consensus (CL) RPC:"
echo "    https://drpc.org (buat key untuk Sepolia)"
echo ""

read -p "▶️  Masukkan EL RPC URL: " ETH_RPC
read -p "▶️  Masukkan CL RPC URL: " CONS_RPC
read -p "▶️  Masukkan Blob Sink URL (opsional): " BLOB_URL
read -p "▶️  Masukkan Validator Private Key: " VALIDATOR_PRIVATE_KEY

echo "🌐 Mengambil IP publik..."
PUBLIC_IP=$(curl -s ifconfig.me || echo "127.0.0.1")
echo "    → $PUBLIC_IP"

cat > .env <<EOF
ETHEREUM_HOSTS="$ETH_RPC"
L1_CONSENSUS_HOST_URLS="$CONS_RPC"
P2P_IP="$PUBLIC_IP"
VALIDATOR_PRIVATE_KEY="$VALIDATOR_PRIVATE_KEY"
DATA_DIRECTORY="/data"
LOG_LEVEL="debug"
EOF

if [ -n "$BLOB_URL" ]; then
  echo "BLOB_SINK_URL=\"$BLOB_URL\"" >> .env
fi

BLOB_FLAG=""
if [ -n "$BLOB_URL" ]; then
  BLOB_FLAG="--sequencer.blobSinkUrl \$BLOB_SINK_URL"
fi

cat > docker-compose.yml <<EOF
version: "3.8"
services:
  node:
    image: aztecprotocol/aztec:0.85.0-alpha-testnet.5
    network_mode: host
    environment:
      - ETHEREUM_HOSTS=\${ETHEREUM_HOSTS}
      - L1_CONSENSUS_HOST_URLS=\${L1_CONSENSUS_HOST_URLS}
      - P2P_IP=\${P2P_IP}
      - VALIDATOR_PRIVATE_KEY=\${VALIDATOR_PRIVATE_KEY}
      - DATA_DIRECTORY=\${DATA_DIRECTORY}
      - LOG_LEVEL=\${LOG_LEVEL}
      - BLOB_SINK_URL=\${BLOB_SINK_URL:-}
    entrypoint: >
      sh -c 'node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network alpha-testnet --node --archiver --sequencer $BLOB_FLAG'
    volumes:
      - $(pwd)/data:/data
EOF

mkdir -p data

echo -e "\n🚀 Menjalankan node Aztec (docker-compose up -d)..."
docker-compose up -d

echo -e "\n${CYAN}${BOLD}✅ Instalasi selesai!${RESET}"
echo "   - Cek log: docker-compose logs -f"
echo "   - Direktori data: $(pwd)/data"

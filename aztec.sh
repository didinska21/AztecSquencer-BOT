#!/usr/bin/env bash
set -euo pipefail

CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Banner
BANNER_TEXT="AZTEC NODE"
SUB_TEXT="Sequencer"
OWNER_TEXT="owner: t.me/didinska"

echo -e "${CYAN}${BOLD}"
cat << EOF
â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•— â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•— 
â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•—â–ˆâ–ˆâ•”â•â•â•â•â•â•šâ•â•â–ˆâ–ˆâ•”â•â•â•â–ˆâ–ˆâ•”â•â•â•â•â•â–ˆâ–ˆâ•”â•â•â•â•â•â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•—
â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—     â–ˆâ–ˆâ•‘   â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—  â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—  â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•”â•
â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘â–ˆâ–ˆâ•”â•â•â•     â–ˆâ–ˆâ•‘   â–ˆâ–ˆâ•”â•â•â•  â–ˆâ–ˆâ•”â•â•â•  â–ˆâ–ˆâ•”â•â•â–ˆâ–ˆâ•—
â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•”â•â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—   â–ˆâ–ˆâ•‘   â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ–ˆâ•—â–ˆâ–ˆâ•‘  â–ˆâ–ˆâ•‘
â•šâ•â•â•â•â•â• â•šâ•â•â•â•â•â•â•   â•šâ•â•   â•šâ•â•â•â•â•â•â•â•šâ•â•â•â•â•â•â•â•šâ•â•  â•šâ•â•
EOF
echo -e "${RESET}"
echo -e "${CYAN}${BOLD}${BANNER_TEXT}${RESET}"
echo -e "${CYAN}${BOLD}${SUB_TEXT}${RESET}"
echo -e "${CYAN}${BOLD}${OWNER_TEXT}${RESET}\n"

# ====================================================
# Aztec alpha-testnet full node installation & startup
# Version: v0.85.0-alpha-testnet.5
# ====================================================

if [ "$(id -u)" -ne 0 ]; then
  echo "âš ï¸ Script ini harus dijalankan dengan akses root (sudo)."
  exit 1
fi

# Install Docker & Docker Compose
if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
  echo "ðŸ‹ Menginstal Docker dan Docker Compose..."
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
  echo "ðŸ‹ Docker dan Docker Compose sudah tersedia."
fi

# Install Node.js
if ! command -v node &> /dev/null; then
  echo "ðŸŸ¢ Menginstal Node.js..."
  curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
  apt-get install -y nodejs
else
  echo "ðŸŸ¢ Node.js sudah tersedia."
fi

echo "âš™ï¸  Menginstal Aztec CLI..."
curl -sL https://install.aztec.network | bash
export PATH="$HOME/.aztec/bin:$PATH"

if ! command -v aztec-up &> /dev/null; then
  echo "âŒ Instalasi Aztec CLI gagal."
  exit 1
fi

aztec-up alpha-testnet

# Input dari user
echo -e "\n${CYAN}Silakan isi data berikut:${RESET}"
read -p "â–¶ï¸  Masukkan EL RPC URL: " ETH_RPC
read -p "â–¶ï¸  Masukkan CL RPC URL: " CONS_RPC
read -p "â–¶ï¸  Masukkan Validator Private Key: " VALIDATOR_PRIVATE_KEY
read -p "â–¶ï¸  Masukkan Coinbase Address: " COINBASE_ADDRESS

echo "ðŸŒ Mengambil IP publik..."
PUBLIC_IP=$(curl -s ifconfig.me || echo "127.0.0.1")
echo "    â†’ $PUBLIC_IP"

# Tulis file .env
cat > .env <<EOF
ETHEREUM_HOSTS="$ETH_RPC"
L1_CONSENSUS_HOST_URLS="$CONS_RPC"
P2P_IP="$PUBLIC_IP"
VALIDATOR_PRIVATE_KEY="$VALIDATOR_PRIVATE_KEY"
COINBASE_ADDRESS="$COINBASE_ADDRESS"
DATA_DIRECTORY="/data"
LOG_LEVEL="debug"
EOF

# Buat docker-compose.yml
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
      - COINBASE_ADDRESS=\${COINBASE_ADDRESS}
    entrypoint: >
      sh -c 'aztec start --node --archiver --sequencer \
        --network alpha-testnet \
        --l1-rpc-urls \$ETHEREUM_HOSTS \
        --l1-consensus-host-urls \$L1_CONSENSUS_HOST_URLS \
        --sequencer.validatorPrivateKey \$VALIDATOR_PRIVATE_KEY \
        --sequencer.coinbase \$COINBASE_ADDRESS \
        --p2p.p2pIp \$P2P_IP \
        --p2p.maxTxPoolSize 1000000000'
    volumes:
      - $(pwd)/data:/data
EOF

mkdir -p data

echo -e "\nðŸš€ Menjalankan node Aztec (docker-compose up -d)..."
docker-compose up -d

echo -e "\n${CYAN}${BOLD}âœ… Instalasi selesai!${RESET}"
echo "   - Cek log: docker-compose logs -f"
echo "   - Direktori data: $(pwd)/data"

#!/bin/bash

CYAN='\033[0;36m'
LIGHTBLUE='\033[1;34m'
RED='\033[1;31m'
GREEN='\033[1;32m'
PURPLE='\033[1;35m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${PURPLE}${BOLD}"
echo "=========================================="
echo "                 A  Z  T  E  C             "
echo "=========================================="
echo "                by : didinska             "
echo "          telegram : t.me/didinska        "
echo "         github : github.com/didinska21   "
echo "=========================================="
echo -e "${RESET}"
sleep 3

echo -e "\n${CYAN}${BOLD}---- MEMERIKSA INSTALASI DOCKER ----${RESET}\n"
if ! command -v docker &> /dev/null; then
  echo -e "${LIGHTBLUE}${BOLD}Docker belum terpasang. Memasang Docker...${RESET}"
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  sudo usermod -aG docker $USER
  rm get-docker.sh
  echo -e "${GREEN}${BOLD}Docker berhasil dipasang!${RESET}"
fi

echo -e "${LIGHTBLUE}${BOLD}Mengatur Docker agar bisa dijalankan tanpa sudo untuk sesi ini...${RESET}"
if ! getent group docker > /dev/null; then
  sudo groupadd docker
fi

sudo usermod -aG docker $USER

if [ -S /var/run/docker.sock ]; then
  sudo chmod 666 /var/run/docker.sock
  echo -e "${GREEN}${BOLD}Izin akses Docker socket telah diperbarui.${RESET}"
else
  echo -e "${RED}${BOLD}Docker socket tidak ditemukan. Mungkin Docker daemon belum berjalan.${RESET}"
  echo -e "${LIGHTBLUE}${BOLD}Menjalankan Docker daemon...${RESET}"
  sudo systemctl start docker
  sudo chmod 666 /var/run/docker.sock
fi

if docker info &>/dev/null; then
  echo -e "${GREEN}${BOLD}Docker sekarang dapat dijalankan tanpa sudo.${RESET}"
else
  echo -e "${RED}${BOLD}Gagal mengatur Docker tanpa sudo. Akan menggunakan sudo untuk perintah Docker.${RESET}"
  DOCKER_CMD="sudo docker"
fi

echo -e "\n${CYAN}${BOLD}---- MENGINSTAL DEPENDENSI YANG DIBUTUHKAN ----${RESET}\n"
sudo apt-get update
sudo apt-get install -y curl screen net-tools psmisc jq

[ -d /root/.aztec/alpha-testnet ] && rm -r /root/.aztec/alpha-testnet

AZTEC_PATH=$HOME/.aztec
BIN_PATH=$AZTEC_PATH/bin
mkdir -p $BIN_PATH

echo -e "\n${CYAN}${BOLD}---- MENGINSTAL AZTEC TOOLKIT ----${RESET}\n"

if [ -n "$DOCKER_CMD" ]; then
  export DOCKER_CMD="$DOCKER_CMD"
fi

curl -fsSL https://install.aztec.network | bash

if ! command -v aztec >/dev/null 2>&1; then
    echo -e "${LIGHTBLUE}${BOLD}Perintah aztec belum tersedia. Menambahkan ke PATH sesi ini...${RESET}"
    export PATH="$PATH:$HOME/.aztec/bin"
    
    if ! grep -Fxq 'export PATH=$PATH:$HOME/.aztec/bin' "$HOME/.bashrc"; then
        echo 'export PATH=$PATH:$HOME/.aztec/bin' >> "$HOME/.bashrc"
        echo -e "${GREEN}${BOLD}Aztec ditambahkan ke PATH di .bashrc${RESET}"
    fi
fi

if [ -f "$HOME/.bash_profile" ]; then
    source "$HOME/.bash_profile"
elif [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi

export PATH="$PATH:$HOME/.aztec/bin"

if ! command -v aztec &> /dev/null; then
  echo -e "${RED}${BOLD}ERROR: Instalasi Aztec gagal. Silakan cek log di atas.${RESET}"
  exit 1
fi

echo -e "\n${CYAN}${BOLD}---- MEMPERBARUI KE JARINGAN ALPHA-TESTNET ----${RESET}\n"
aztec-up alpha-testnet

echo -e "\n${CYAN}${BOLD}---- KONFIGURASI NODE ----${RESET}\n"
IP=$(curl -s https://api.ipify.org)
if [ -z "$IP" ]; then
    IP=$(curl -s http://checkip.amazonaws.com)
fi
if [ -z "$IP" ]; then
    IP=$(curl -s https://ifconfig.me)
fi
if [ -z "$IP" ]; then
    echo -e "${LIGHTBLUE}${BOLD}Gagal mendapatkan IP publik secara otomatis.${RESET}"
    read -p "Masukkan IP address VPS/WSL Anda: " IP
fi

echo -e "${LIGHTBLUE}${BOLD}Silakan buka ${PURPLE}https://dashboard.alchemy.com/apps${RESET}${LIGHTBLUE}${BOLD} atau ${PURPLE}https://developer.metamask.io/register${RESET}${LIGHTBLUE}${BOLD} untuk membuat akun dan mendapatkan Sepolia RPC URL.${RESET}"
read -p "Masukkan Sepolia Ethereum RPC URL Anda: " L1_RPC_URL

echo -e "\n${LIGHTBLUE}${BOLD}Silakan buka ${PURPLE}https://chainstack.com/global-nodes${RESET}${LIGHTBLUE}${BOLD} untuk mendapatkan BEACON RPC URL.${RESET}"
read -p "Masukkan Sepolia Ethereum BEACON URL Anda: " L1_CONSENSUS_URL

echo -e "\n${LIGHTBLUE}${BOLD}Silakan buat wallet EVM baru, isi dengan faucet Sepolia, lalu masukkan private key-nya.${RESET}"
read -p "Masukkan private key wallet EVM Anda (pakai awalan 0x): " VALIDATOR_PRIVATE_KEY
read -p "Masukkan alamat wallet (coinbase address) dari private key di atas: " COINBASE_ADDRESS

echo -e "\n${CYAN}${BOLD}---- MEMERIKSA PORT 8080 ----${RESET}\n"
if netstat -tuln | grep -q ":8080 "; then
    echo -e "${LIGHTBLUE}${BOLD}Port 8080 sedang digunakan. Mencoba menutupnya...${RESET}"
    sudo fuser -k 8080/tcp
    sleep 2
    echo -e "${GREEN}${BOLD}Port 8080 berhasil dibebaskan.${RESET}"
else
    echo -e "${GREEN}${BOLD}Port 8080 sudah tersedia.${RESET}"
fi

echo -e "\n${CYAN}${BOLD}---- MENJALANKAN NODE AZTEC ----${RESET}\n"
cat > $HOME/start_aztec_node.sh << EOL
#!/bin/bash
export PATH=\$PATH:\$HOME/.aztec/bin
aztec start --node --archiver --sequencer \\
  --network alpha-testnet \\
  --port 8080 \\
  --l1-rpc-urls $L1_RPC_URL \\
  --l1-consensus-host-urls $L1_CONSENSUS_URL \\
  --sequencer.validatorPrivateKey $VALIDATOR_PRIVATE_KEY \\
  --sequencer.coinbase $COINBASE_ADDRESS \\
  --p2p.p2pIp $IP \\
  --p2p.maxTxPoolSize 1000000000
EOL

chmod +x $HOME/start_aztec_node.sh
screen -dmS aztec $HOME/start_aztec_node.sh

echo -e "${GREEN}${BOLD}Node Aztec berhasil dijalankan di dalam session screen.${RESET}\n"

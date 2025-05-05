const readline = require('readline');
const { execSync } = require('child_process');
const chalk = require('chalk');
const gradient = require('gradient-string');
const figlet = require('figlet');

// Banner
const banner = figlet.textSync("AZTEC", {
  font: 'Standard',
  horizontalLayout: 'default',
  verticalLayout: 'default'
});
console.log(gradient(['#A020F0', '#FFFFFF'])(banner));

console.log(chalk.green("Install Node Aztec"));
console.log("by : didinska");
console.log("GitHub : https://github.com/didinska21");
console.log("Telegram : t.me/didinska\n");

// Install Aztec CLI
console.log(chalk.yellow("[*] Menginstall Aztec CLI..."));
execSync(`bash -c "yes | bash -i <(curl -s https://install.aztec.network)"`, {
  stdio: 'inherit',
  shell: '/bin/bash',
});

// Cek dan install Docker
console.log(chalk.yellow("[*] Mengecek Docker..."));
try {
  execSync("docker --version", { stdio: 'ignore' });
  console.log(chalk.green("[+] Docker sudah terinstal."));
} catch {
  console.log(chalk.red("[!] Docker belum ada. Menginstall Docker..."));
  execSync(`curl -fsSL https://get.docker.com | bash`, { stdio: 'inherit' });
  execSync(`systemctl start docker && systemctl enable docker`, {
    stdio: 'inherit',
  });
}

// Input data
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

const ask = (q) =>
  new Promise((res) => rl.question(chalk.cyan(q), (ans) => res(ans.trim())));

const findAvailablePort = async (start) => {
  for (let port = start; port < start + 20; port++) {
    try {
      execSync(`lsof -i :${port}`, { stdio: 'ignore' });
      continue;
    } catch {
      try {
        execSync(`nc -z 127.0.0.1 ${port}`, { stdio: 'ignore' });
        continue;
      } catch {
        return port;
      }
    }
  }
  throw new Error("Tidak ada port kosong antara 8080 - 8100.");
};

(async () => {
  const rpc = await ask("Masukkan RPC Alchemy (https://...): ");
  const beacon = await ask("Masukkan Beacon (https://...): ");
  const privKey = await ask("Masukkan Private Key (0x...): ");
  const coinbase = await ask("Masukkan Coinbase Address (0x...): ");
  const ip = await ask("Masukkan IP VPS: ");
  rl.close();

  console.log(chalk.yellow("\n[*] Mencari port kosong..."));
  const port = await findAvailablePort(8080);
  console.log(chalk.green(`[✓] Port ${port} tersedia.`));

  const cmd = `aztec start --node --archiver --sequencer \
--network alpha-testnet \
--l1-rpc-urls "${rpc}" \
--l1-consensus-host-urls "${beacon}" \
--sequencer.validatorPrivateKey "${privKey}" \
--sequencer.coinbase "${coinbase}" \
--p2p.p2pIp "${ip}" \
--p2p.maxTxPoolSize 1000000000 \
--http-port ${port}`;

  console.log(chalk.cyan("\n[*] Menjalankan Aztec Node...\n"));

  try {
    execSync(cmd, { stdio: 'inherit', shell: '/bin/bash' });
    console.log(chalk.green(`\n[✓] Aztec Node berjalan di port ${port}.`));
  } catch (err) {
    console.error(chalk.red("\n[!] Gagal menjalankan Aztec Node:"));
    console.error(err.message);
  }
})();

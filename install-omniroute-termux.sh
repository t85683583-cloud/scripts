#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Instalador nativo do OmniRoute para Termux.
# Baseado no guia oficial do OmniRoute para Android/Termux.

PREFIX_DIR="${PREFIX:-}"
BIN_DIR="${PREFIX_DIR:-/data/data/com.termux/files/usr}/bin"

info() { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok() { printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[AVISO]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[ERRO]\033[0m %s\n' "$*" >&2; exit 1; }

if ! command -v pkg >/dev/null 2>&1 || [ -z "$PREFIX_DIR" ]; then
  die "Execute este script dentro do Termux."
fi

if [ "$PREFIX_DIR" != "/data/data/com.termux/files/usr" ]; then
  warn "PREFIX detectado como: $PREFIX_DIR"
  warn "O script continuará, mas foi projetado para o Termux padrão."
fi

info "Atualizando os pacotes do Termux..."
pkg update -y
pkg upgrade -y

info "Instalando Node.js atual e ferramentas necessárias..."
# O guia oficial usa nodejs atual. Evite nodejs-lts antigo.
pkg install -y nodejs python build-essential git curl

command -v node >/dev/null 2>&1 || die "Node.js não foi instalado."
command -v npm >/dev/null 2>&1 || die "npm não foi instalado."

NODE_VERSION="$(node -p 'process.versions.node')"
NODE_MAJOR="${NODE_VERSION%%.*}"
if [ "$NODE_MAJOR" -lt 22 ]; then
  die "Node.js $NODE_VERSION detectado. O OmniRoute requer Node.js 22 ou superior."
fi
ok "Node.js $NODE_VERSION detectado."

info "Criando o cache necessário para o runtime Android..."
mkdir -p "$HOME/.cache"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

info "Instalando o OmniRoute globalmente pelo npm..."
npm install -g omniroute

command -v omniroute >/dev/null 2>&1 || die "O comando omniroute não foi encontrado após a instalação."
ok "OmniRoute instalado: $(npm list -g omniroute --depth=0 2>/dev/null | tail -1 || true)"

# Atalho de inicialização em segundo plano.
cat > "$BIN_DIR/omniroute-start" <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
set -eu
mkdir -p "$HOME/.cache"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export DATA_DIR="${DATA_DIR:-$HOME/.omniroute}"

if curl -fsS --max-time 2 http://127.0.0.1:20128 >/dev/null 2>&1; then
  echo "OmniRoute já está respondendo em http://127.0.0.1:20128"
  exit 0
fi

nohup omniroute > "$HOME/omniroute.log" 2>&1 &
echo "OmniRoute iniciado em segundo plano. PID: $!"
echo "Painel: http://127.0.0.1:20128"
echo "Log:    $HOME/omniroute.log"
EOF
chmod +x "$BIN_DIR/omniroute-start"

# Atalho para encerrar o servidor.
cat > "$BIN_DIR/omniroute-stop" <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
pkill -f '[o]mniroute' 2>/dev/null || true
echo "OmniRoute encerrado."
EOF
chmod +x "$BIN_DIR/omniroute-stop"

# Atalho para verificar a API/painel.
cat > "$BIN_DIR/omniroute-status" <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
if curl -fsS --max-time 3 http://127.0.0.1:20128 >/dev/null 2>&1; then
  echo "OmniRoute está respondendo em http://127.0.0.1:20128"
else
  echo "OmniRoute não está respondendo em http://127.0.0.1:20128"
  echo "Inicie com: omniroute-start"
  exit 1
fi
EOF
chmod +x "$BIN_DIR/omniroute-status"

printf '\n'
ok "Instalação concluída."
printf '\nComandos disponíveis:\n'
printf '  omniroute          # inicia diretamente no terminal\n'
printf '  omniroute-start    # inicia em segundo plano\n'
printf '  omniroute-status   # verifica o painel/API\n'
printf '  omniroute-stop     # encerra o servidor\n'
printf '\nPainel local: http://127.0.0.1:20128\n'
printf 'Log:          ~/omniroute.log\n'
printf '\nPara iniciar agora, execute: omniroute-start\n'

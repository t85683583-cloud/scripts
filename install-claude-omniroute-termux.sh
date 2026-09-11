#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail

# Instalador de Claude Code + OmniRoute para Termux.
# Uso: bash install-claude-omniroute-termux.sh

readonly SCRIPT_NAME="Claude Code + OmniRoute para Termux"
readonly PREFIX_DIR="${PREFIX:-/data/data/com.termux/files/usr}"
readonly BIN_DIR="$PREFIX_DIR/bin"
readonly NPM_ROOT_FILE="${TMPDIR:-/tmp}/claude-npm-root.$$"

cleanup() { rm -f "$NPM_ROOT_FILE"; }
trap cleanup EXIT

log()  { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m[OK]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[AVISO]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[ERRO]\033[0m %s\n' "$*" >&2; exit 1; }

command -v pkg >/dev/null 2>&1 || die "Este script precisa ser executado dentro do Termux."

log "Atualizando os pacotes do Termux..."
pkg update -y
pkg upgrade -y

log "Instalando Node.js, npm e ferramentas de compilação..."
# nodejs (e não nodejs-lts) é necessário para OmniRoute atual.
pkg install -y nodejs npm git python build-essential curl

command -v node >/dev/null 2>&1 || die "Node.js não foi instalado."
command -v npm  >/dev/null 2>&1 || die "npm não foi instalado."

NODE_VERSION="$(node -p 'process.versions.node')"
NODE_MAJOR="${NODE_VERSION%%.*}"
if [ "${NODE_MAJOR:-0}" -lt 22 ]; then
  die "Node.js $NODE_VERSION detectado. OmniRoute requer Node.js 22 ou superior; use 'pkg install nodejs' e tente novamente."
fi
ok "Node.js $NODE_VERSION detectado."

log "Instalando Claude Code pelo npm..."
# O instalador nativo oficial não é compatível com o ABI Android do Termux.
# O pacote npm continua fornecendo o cli.js, que é executado pelo Node.
npm install -g @anthropic-ai/claude-code

NPM_ROOT="$(npm root -g)"
printf '%s\n' "$NPM_ROOT" > "$NPM_ROOT_FILE"
CLAUDE_CLI=""
for candidate in \
  "$NPM_ROOT/@anthropic-ai/claude-code/cli.js" \
  "$NPM_ROOT/@anthropic-ai/claude-code/cli.mjs"; do
  if [ -f "$candidate" ]; then
    CLAUDE_CLI="$candidate"
    break
  fi
done

if [ -z "$CLAUDE_CLI" ]; then
  CLAUDE_CLI="$(find "$NPM_ROOT/@anthropic-ai/claude-code" -maxdepth 2 -type f \( -name 'cli.js' -o -name 'cli.mjs' \) -print -quit 2>/dev/null || true)"
fi

[ -n "$CLAUDE_CLI" ] && [ -f "$CLAUDE_CLI" ] || die "Não encontrei o cli.js do Claude Code em $NPM_ROOT."

cat > "$BIN_DIR/claude" <<EOF
#!/data/data/com.termux/files/usr/bin/sh
exec node "$CLAUDE_CLI" "\$@"
EOF
chmod +x "$BIN_DIR/claude"
ok "Claude Code instalado: $(claude --version 2>/dev/null || printf 'wrapper criado')"

log "Instalando OmniRoute..."
# O fallback JS evita bloquear a instalação quando better-sqlite3 não tiver
# binário pré-compilado para a combinação Android/arquitetura do aparelho.
export OMNIROUTE_SKIP_POSTINSTALL=1
if npm install -g omniroute; then
  ok "OmniRoute instalado globalmente."
else
  warn "A instalação global falhou; o comando 'omniroute' usará npx quando possível."
  cat > "$BIN_DIR/omniroute" <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
exec npx -y omniroute@latest "$@"
EOF
  chmod +x "$BIN_DIR/omniroute"
fi

# Corrige o caso conhecido em que o runtime Android precisa de um cache existente.
mkdir -p "$HOME/.cache"
if [ -z "${XDG_CACHE_HOME:-}" ]; then
  printf '\nexport XDG_CACHE_HOME="$HOME/.cache"\n' >> "$HOME/.bashrc"
  export XDG_CACHE_HOME="$HOME/.cache"
fi

# Comandos auxiliares para iniciar/parar o servidor sem bloquear o terminal.
cat > "$BIN_DIR/omniroute-start" <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
mkdir -p "$HOME/.cache"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export DATA_DIR="${DATA_DIR:-$HOME/.omniroute}"
nohup omniroute > "$HOME/omniroute.log" 2>&1 &
echo "OmniRoute iniciado em http://localhost:20128 (PID $!)"
echo "Log: $HOME/omniroute.log"
EOF
chmod +x "$BIN_DIR/omniroute-start"

cat > "$BIN_DIR/omniroute-stop" <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
pkill -f 'omniroute' 2>/dev/null || true
echo "Processos OmniRoute encerrados."
EOF
chmod +x "$BIN_DIR/omniroute-stop"

cat > "$BIN_DIR/omniroute-status" <<'EOF'
#!/data/data/com.termux/files/usr/bin/sh
if curl -fsS --max-time 3 http://localhost:20128 >/dev/null 2>&1; then
  echo "OmniRoute está respondendo em http://localhost:20128"
else
  echo "OmniRoute não está respondendo em http://localhost:20128"
  exit 1
fi
EOF
chmod +x "$BIN_DIR/omniroute-status"

ok "OmniRoute configurado."
printf '\n\033[1;32mInstalação concluída.\033[0m\n\n'
printf 'Próximos passos:\n'
printf '  1. Verifique:  claude --version\n'
printf '  2. Autentique:  claude\n'
printf '  3. Inicie:     omniroute-start\n'
printf '  4. Painel:      http://localhost:20128\n'
printf '  5. Pare:        omniroute-stop\n'
printf '\nO OmniRoute é um gateway: configure seus provedores e chaves no painel.\n'
printf 'Não exponha a porta 20128 à internet sem autenticação e uma rede confiável.\n'

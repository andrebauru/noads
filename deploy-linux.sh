#!/bin/bash

# ============================================================================
# DEPLOY COMPLETO - NOADS v3.1 para you.andretsc.dev
# ============================================================================
set -e

# CONFIGURAÇÕES UNIFICADAS
REPO_URL="https://github.com/andrebauru/noads.git"
PROJECT_DIR="/var/www/you.andretsc.dev"
VENV_DIR="$PROJECT_DIR/venv"
SERVICE_NAME="noads"
SERVICE_USER="www-data"
SERVICE_GROUP="www-data"
PORT=8001

# Cores para o terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}✅${NC} $1"; }
info() { echo -e "${BLUE}ℹ️${NC} $1"; }
warn() { echo -e "${YELLOW}⚠️${NC} $1"; }
error() { echo -e "${RED}❌${NC} $1"; exit 1; }

# Verificar root
if [ "$EUID" -ne 0 ]; then error "Execute com sudo"; fi

clear
echo -e "${BLUE}🚀 INICIANDO DEPLOY: you.andretsc.dev${NC}\n"

# 1. PREPARAÇÃO DE DIRETÓRIO
info "Configurando diretórios..."
if [ -d "$PROJECT_DIR" ]; then
    warn "Diretório já existe, atualizando via Git..."
    cd "$PROJECT_DIR"
    git config --global --add safe.directory "$PROJECT_DIR"
    git fetch --all
    git reset --hard origin/main
else
    mkdir -p "$PROJECT_DIR"
    git clone "$REPO_URL" "$PROJECT_DIR"
fi

# 2. AMBIENTE VIRTUAL E DEPENDÊNCIAS
info "Configurando Python venv..."
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"
pip install --upgrade pip setuptools wheel > /dev/null
log "Instalando Flask, yt-dlp e Requests..."
pip install flask yt-dlp requests > /dev/null

# 3. CRIAÇÃO DO SERVIÇO SYSTEMD
info "Gerando serviço noads.service..."
cat > "/etc/systemd/system/${SERVICE_NAME}.service" << SERVICEEOF
[Unit]
Description=NOADS Service - you.andretsc.dev
After=network.target

[Service]
User=$SERVICE_USER
Group=$SERVICE_GROUP
WorkingDirectory=$PROJECT_DIR
ExecStart=$VENV_DIR/bin/python3 $PROJECT_DIR/api.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICEEOF

# 4. SCRIPT DE AUTO-RESTART (CORRIGIDO PARA O DOMÍNIO)
info "Gerando script de auto-restart..."
cat > "$PROJECT_DIR/auto-restart.sh" << AUTORESTARTEOF
#!/bin/bash
PROJECT_DIR="$PROJECT_DIR"
PORT=$PORT
CHECK_INTERVAL=15

while true; do
    if ! curl -s -m 5 "http://127.0.0.1:\$PORT/extract.php" > /dev/null; then
        echo "[$(date)] API Offline - Reiniciando..."
        systemctl restart $SERVICE_NAME
        sleep 20
    fi
    sleep \$CHECK_INTERVAL
done
AUTORESTARTEOF

chmod +x "$PROJECT_DIR/auto-restart.sh"

# 5. PERMISSÕES E FINALIZAÇÃO
info "Aplicando permissões finais..."
chown -R "$SERVICE_USER:$SERVICE_GROUP" "$PROJECT_DIR"
chmod -R 755 "$PROJECT_DIR"

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

log "MIGRAÇÃO E DEPLOY CONCLUÍDOS!"
info "Acesse: https://you.andretsc.dev"

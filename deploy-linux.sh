#!/bin/bash

# ============================================================================
# DEPLOY COMPLETO - NOADS v3.0 para Linux/Ubuntu
# ============================================================================
# Instalação e configuração automática com systemd
#
# Uso:
#   chmod +x deploy-linux.sh
#   sudo ./deploy-linux.sh
#
# OU sem sudo (para não-admin):
#   ./deploy-linux.sh --no-sudo

set -e

# ============================================================================
# CONFIGURAÇÕES
# ============================================================================

REPO_URL="https://github.com/andrebauru/noads.git"
PROJECT_DIR="/var/www/noads"
VENV_DIR="$PROJECT_DIR/venv"
SERVICE_NAME="noads"
SERVICE_USER="www-data"
SERVICE_GROUP="www-data"
PORT=8001

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================================
# FUNCTIONS
# ============================================================================

log() {
    echo -e "${GREEN}✅${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

error() {
    echo -e "${RED}❌${NC} $1"
    exit 1
}

info() {
    echo -e "${BLUE}ℹ️${NC} $1"
}

# Verificar se é root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Este script deve ser executado com sudo"
    fi
}

# ============================================================================
# HEADER
# ============================================================================

clear

echo -e "${BLUE}"
cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║           🚀 DEPLOY NOADS v3.0 - Linux/Ubuntu                            ║
║              Instalação Automática com Systemd                            ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo ""

# ============================================================================
# PRÉ-REQUISITOS
# ============================================================================

info "Verificando pré-requisitos..."
echo ""

# Verificar root
check_root

# Verificar Ubuntu/Debian
if ! command -v apt-get &> /dev/null; then
    error "Este script é para Ubuntu/Debian"
fi

# Verificar Python3
if ! command -v python3 &> /dev/null; then
    warn "Python3 não encontrado, instalando..."
    apt-get update
    apt-get install -y python3 python3-pip python3-venv
    log "Python3 instalado"
else
    log "Python3 já instalado"
fi

# Verificar Git
if ! command -v git &> /dev/null; then
    warn "Git não encontrado, instalando..."
    apt-get install -y git
    log "Git instalado"
else
    log "Git já instalado"
fi

# Verificar curl
if ! command -v curl &> /dev/null; then
    warn "curl não encontrado, instalando..."
    apt-get install -y curl
    log "curl instalado"
else
    log "curl já instalado"
fi

echo ""

# ============================================================================
# CRIAR DIRETÓRIO E CLONAR REPO
# ============================================================================

info "Preparando diretório de projeto..."
echo ""

if [ -d "$PROJECT_DIR" ]; then
    warn "Diretório já existe, atualizando..."
    cd "$PROJECT_DIR"
    git pull origin main 2>/dev/null || git fetch origin && git reset --hard origin/main
    log "Repositório atualizado"
else
    log "Criando diretório: $PROJECT_DIR"
    mkdir -p "$PROJECT_DIR"
    
    log "Clonando repositório..."
    git clone "$REPO_URL" "$PROJECT_DIR"
    log "Repositório clonado"
fi

echo ""

# ============================================================================
# CRIAR AMBIENTE VIRTUAL
# ============================================================================

info "Criando ambiente virtual Python..."
echo ""

if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
    log "Ambiente virtual criado"
else
    log "Ambiente virtual já existe"
fi

# Ativar venv
source "$VENV_DIR/bin/activate"

# Instalar/atualizar pip
pip install --upgrade pip setuptools wheel > /dev/null 2>&1
log "pip atualizado"

# Instalar dependências
log "Instalando dependências..."
pip install flask yt-dlp requests > /dev/null 2>&1
log "Dependências instaladas"

echo ""

# ============================================================================
# CRIAR ESTRUTURA DE DIRETÓRIOS
# ============================================================================

info "Criando estrutura de diretórios..."
echo ""

mkdir -p "$PROJECT_DIR/logs"
mkdir -p "$PROJECT_DIR/cache"

log "Diretórios criados"

echo ""

# ============================================================================
# CRIAR ARQUIVO requirements.txt
# ============================================================================

info "Gerando requirements.txt..."
echo ""

cat > "$PROJECT_DIR/requirements.txt" << 'REQEOF'
flask==2.3.3
yt-dlp==2023.10.13
requests==2.31.0
Werkzeug==2.3.7
REQEOF

log "requirements.txt gerado"

echo ""

# ============================================================================
# CRIAR SYSTEMD SERVICE
# ============================================================================

info "Configurando systemd service..."
echo ""

SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

cat > "$SERVICE_FILE" << SERVICEEOF
[Unit]
Description=NOADS - NoAds YouTube Extraction Service
Documentation=https://github.com/andrebauru/noads
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_GROUP
WorkingDirectory=$PROJECT_DIR
ExecStart=$VENV_DIR/bin/python3 $PROJECT_DIR/simple_api.py

Restart=always
RestartSec=10
StartLimitInterval=60
StartLimitBurst=5

MemoryMax=512M
CPUQuota=50%

PrivateTmp=true
NoNewPrivileges=true

StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME

KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
SERVICEEOF

log "Service file criado: $SERVICE_FILE"

echo ""

# ============================================================================
# CONFIGURAR PERMISSÕES
# ============================================================================

info "Configurando permissões..."
echo ""

chown -R "$SERVICE_USER:$SERVICE_GROUP" "$PROJECT_DIR"
chmod -R 755 "$PROJECT_DIR"
chmod 644 "$SERVICE_FILE"

log "Permissões configuradas"

echo ""

# ============================================================================
# ATIVAR E INICIAR SERVIÇO
# ============================================================================

info "Ativando e iniciando serviço..."
echo ""

systemctl daemon-reload
log "Daemon recarregado"

systemctl enable "$SERVICE_NAME"
log "Serviço habilitado para auto-start"

systemctl start "$SERVICE_NAME"
log "Serviço iniciado"

sleep 3

# Verificar status
if systemctl is-active --quiet "$SERVICE_NAME"; then
    log "✅ Serviço está rodando!"
else
    error "Serviço não iniciou! Verifique com: sudo journalctl -u $SERVICE_NAME -n 20"
fi

echo ""

# ============================================================================
# CRIAR SCRIPT AUTO-RESTART
# ============================================================================

info "Criando script de auto-restart..."
echo ""

cat > "$PROJECT_DIR/auto-restart.sh" << 'AUTORESTARTEOF'
#!/bin/bash
# Script auto-restart para monitorar a API

PROJECT_DIR="/var/www/noads"
PORT=8001
CHECK_INTERVAL=10
MAX_RESTARTS=5

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')]${NC} $1"; }

test_api() {
    curl -s -m 3 "http://127.0.0.1:$PORT/extract.php" > /dev/null 2>&1
}

RESTART_COUNT=0

trap 'log "Interrompido"; exit 0' SIGINT SIGTERM

while true; do
    if test_api; then
        log "✅ API OK"
        RESTART_COUNT=0
    else
        error "❌ API caiu!"
        RESTART_COUNT=$((RESTART_COUNT + 1))
        
        if [ $RESTART_COUNT -gt $MAX_RESTARTS ]; then
            error "Limite de restarts atingido!"
            exit 1
        fi
        
        warn "Restart #$RESTART_COUNT/$MAX_RESTARTS..."
        systemctl restart $SERVICE_NAME
        sleep 15
    fi
    
    sleep $CHECK_INTERVAL
done
AUTORESTARTEOF

chmod +x "$PROJECT_DIR/auto-restart.sh"
log "Script auto-restart criado"

echo ""

# ============================================================================
# RESUMO FINAL
# ============================================================================

echo -e "${GREEN}"
cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                  ✅ DEPLOY CONCLUÍDO COM SUCESSO!                         ║
╚════════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
info "📍 INFORMAÇÕES DE DEPLOYMENT:"
echo ""
echo "   Diretório: $PROJECT_DIR"
echo "   Porta: $PORT"
echo "   Usuário: $SERVICE_USER"
echo "   Service: $SERVICE_NAME"
echo ""

echo -e "${BLUE}🔧 COMANDOS ÚTEIS:${NC}"
echo ""
echo "   Ver status do serviço:"
echo "   $ sudo systemctl status $SERVICE_NAME"
echo ""
echo "   Ver logs em tempo real:"
echo "   $ sudo journalctl -u $SERVICE_NAME -f"
echo ""
echo "   Reiniciar manualmente:"
echo "   $ sudo systemctl restart $SERVICE_NAME"
echo ""
echo "   Parar o serviço:"
echo "   $ sudo systemctl stop $SERVICE_NAME"
echo ""

echo -e "${BLUE}🚀 PRÓXIMAS AÇÕES:${NC}"
echo ""
echo "   1. Verifique se está rodando:"
echo "      $ curl http://127.0.0.1:$PORT/extract.php"
echo ""
echo "   2. Configure seu servidor web (nginx/apache):"
echo "      Proxy para http://127.0.0.1:$PORT"
echo ""
echo "   3. Acesse sua aplicação:"
echo "      https://you.andretsc.dev"
echo ""

echo -e "${GREEN}✅ Deploy finalizado!${NC}"
echo ""

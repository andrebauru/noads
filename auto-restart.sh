#!/bin/bash

# ============================================================================
# AUTO-RESTART SCRIPT - Para Linux/Ubuntu
# ============================================================================
# Monitora a API e reinicia automaticamente se cair
#
# Uso:
#   chmod +x auto-restart.sh
#   ./auto-restart.sh
#
# Ou em background:
#   nohup ./auto-restart.sh > auto-restart.log 2>&1 &

set -e

# ============================================================================
# CONFIGURAÇÕES
# ============================================================================

PROJECT_DIR="$HOME/noads"
VENV_DIR="$PROJECT_DIR/venv"
PORT=8001
CHECK_INTERVAL=10
MAX_RESTARTS=5

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# FUNCTIONS
# ============================================================================

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Testar se API está respondendo
test_api() {
    if curl -s -m 3 "http://127.0.0.1:$PORT/extract.php" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Iniciar serviços
start_services() {
    info "🚀 INICIANDO SERVIÇOS..."
    
    # Matar processos antigos
    pkill -f "python.*simple_api.py" || true
    sleep 2
    
    # Iniciar Python API
    info "→ Iniciando Python API (porta $PORT)..."
    cd "$PROJECT_DIR"
    
    if [ -f "$VENV_DIR/bin/activate" ]; then
        source "$VENV_DIR/bin/activate"
        nohup python3 simple_api.py > "$PROJECT_DIR/api.log" 2>&1 &
    else
        nohup python3 simple_api.py > "$PROJECT_DIR/api.log" 2>&1 &
    fi
    
    local pid=$!
    log "✅ Python iniciado (PID: $pid)"
    
    return 0
}

# ============================================================================
# HEADER
# ============================================================================

clear

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║          🔄 AUTO-RESTART MONITOR - NOADS v3.0 (Linux)                 ║"
echo "║          Monitora e reinicia automaticamente se cair                   ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

info "📍 CONFIGURAÇÃO:"
echo "   Diretório: $PROJECT_DIR"
echo "   Porta: $PORT"
echo "   Intervalo verificação: ${CHECK_INTERVAL}s"
echo "   Max tentativas restart: $MAX_RESTARTS"
echo ""

# Verificar se curl está instalado
if ! command -v curl &> /dev/null; then
    error "❌ curl não está instalado!"
    error "   Instale com: sudo apt-get install curl"
    exit 1
fi

# Verificar se Python está instalado
if ! command -v python3 &> /dev/null; then
    error "❌ Python3 não está instalado!"
    error "   Instale com: sudo apt-get install python3 python3-pip"
    exit 1
fi

# ============================================================================
# MAIN LOOP
# ============================================================================

RESTART_COUNT=0

# Iniciar serviços
start_services

log "⏳ Aguardando API estabilizar..."
sleep 5

info "🔄 MONITORAMENTO INICIADO"
info "Pressione CTRL+C para parar"
echo ""

# Trap para cleanup
trap 'log "⏹️  Monitoramento interrompido"; pkill -f "python.*simple_api.py" || true; exit 0' SIGINT SIGTERM

while true; do
    # Verificar saúde da API
    if test_api; then
        log "✅ API respondendo"
        RESTART_COUNT=0
    else
        error "❌ API NÃO RESPONDEU!"
        
        RESTART_COUNT=$((RESTART_COUNT + 1))
        
        if [ $RESTART_COUNT -gt $MAX_RESTARTS ]; then
            error ""
            error "❌ LIMITE DE RESTARTS ATINGIDO ($MAX_RESTARTS)"
            error "    Interrompa manualmente: pkill -f simple_api.py"
            exit 1
        fi
        
        warn ""
        warn "⚠️  API CAIU! Restart #$RESTART_COUNT/$MAX_RESTARTS"
        warn ""
        
        # Reiniciar
        start_services
        
        warn "⏳ Aguardando estabilização (15s)..."
        sleep 15
    fi
    
    # Aguardar próximo check
    sleep $CHECK_INTERVAL
done

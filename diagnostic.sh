#!/bin/bash

# ============================================================================
# SCRIPT DE DIAGNÓSTICO - NOADS v3.0
# ============================================================================
# Use para verificar problemas em produção
# Uso: chmod +x diagnostic.sh && sudo ./diagnostic.sh

echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║        🔍 DIAGNÓSTICO NOADS v3.0 - Verificação de Produção              ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

pass() { echo -e "${GREEN}✅${NC} $1"; }
fail() { echo -e "${RED}❌${NC} $1"; }
warn() { echo -e "${YELLOW}⚠️${NC} $1"; }
info() { echo -e "${BLUE}ℹ️${NC} $1"; }

PROJECT_DIR="/var/www/noads"
SERVICE_NAME="noads"
PORT=8001

echo -e "${BLUE}1. VERIFICANDO SERVIÇO SYSTEMD${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""

if systemctl is-active --quiet "$SERVICE_NAME"; then
    pass "Serviço $SERVICE_NAME está rodando"
else
    fail "Serviço $SERVICE_NAME NÃO está rodando"
    warn "Iniciando..."
    sudo systemctl start "$SERVICE_NAME"
    sleep 2
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        pass "Serviço iniciado com sucesso"
    else
        fail "Não conseguiu iniciar. Verifique os logs:"
        echo "  $ sudo journalctl -u $SERVICE_NAME -n 30"
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}2. VERIFICANDO LOGS RECENTES${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""

LAST_ERRORS=$(sudo journalctl -u "$SERVICE_NAME" -n 20 --no-pager 2>/dev/null | grep -i "error\|exception\|traceback" | wc -l)

if [ "$LAST_ERRORS" -gt 0 ]; then
    fail "Encontrados $LAST_ERRORS erros nos logs recentes"
    echo ""
    echo "📋 Últimos 20 logs:"
    sudo journalctl -u "$SERVICE_NAME" -n 20 --no-pager
else
    pass "Nenhum erro encontrado nos logs recentes"
fi

echo ""
echo -e "${BLUE}3. TESTANDO CONECTIVIDADE DA API${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""

# Testar localhost
if curl -s -m 5 "http://127.0.0.1:$PORT/extract.php" > /dev/null 2>&1; then
    pass "API respondendo em http://127.0.0.1:$PORT"
else
    fail "API NÃO respondendo em http://127.0.0.1:$PORT"
    warn "Possível problema: porta bloqueada, processo morto, ou erro na API"
fi

# Testar com URL
TEST_RESPONSE=$(curl -s -m 5 "http://127.0.0.1:$PORT/extract.php?url=https://youtu.be/jNQXAC9IVRw" 2>&1)

if echo "$TEST_RESPONSE" | grep -q "success"; then
    pass "API respondendo com JSON válido"
    echo "Resposta: $TEST_RESPONSE" | head -c 100
    echo "..."
else
    fail "API não retornando JSON válido"
    echo "Resposta recebida: $TEST_RESPONSE" | head -c 100
    echo ""
fi

echo ""
echo -e "${BLUE}4. VERIFICANDO PERMISSÕES DE ARQUIVOS${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""

if [ -d "$PROJECT_DIR" ]; then
    pass "Diretório do projeto existe: $PROJECT_DIR"
    
    # Verificar cache
    if [ -d "$PROJECT_DIR/cache" ]; then
        pass "Diretório de cache existe"
    else
        fail "Diretório de cache não existe"
        warn "Criando..."
        mkdir -p "$PROJECT_DIR/cache"
    fi
    
    # Verificar api.py
    if [ -f "$PROJECT_DIR/api.py" ]; then
        pass "api.py existe"
    else
        fail "api.py NÃO encontrado!"
        warn "Atualize o repositório: cd $PROJECT_DIR && git pull origin main"
    fi
    
    # Verificar extract.php
    if [ -f "$PROJECT_DIR/extract.php" ]; then
        pass "extract.php existe"
    else
        fail "extract.php NÃO encontrado!"
    fi
    
    # Verificar permissões
    OWNER=$(ls -ld "$PROJECT_DIR" | awk '{print $3":"$4}')
    if [ "$OWNER" = "www-data:www-data" ]; then
        pass "Permissões corretas (www-data:www-data)"
    else
        warn "Proprietário é $OWNER (esperado www-data:www-data)"
        warn "Corrigindo permissões..."
        sudo chown -R www-data:www-data "$PROJECT_DIR"
        sudo chmod -R 755 "$PROJECT_DIR"
    fi
else
    fail "Diretório do projeto não existe: $PROJECT_DIR"
    exit 1
fi

echo ""
echo -e "${BLUE}5. VERIFICANDO DEPENDÊNCIAS${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""

VENV_DIR="$PROJECT_DIR/venv"

if [ -d "$VENV_DIR" ]; then
    pass "Ambiente virtual existe"
    
    # Verificar yt-dlp
    if "$VENV_DIR/bin/python3" -c "import yt_dlp" 2>/dev/null; then
        pass "yt-dlp instalado"
    else
        fail "yt-dlp NÃO instalado!"
        warn "Instalando..."
        source "$VENV_DIR/bin/activate"
        pip install yt-dlp > /dev/null 2>&1
        pass "yt-dlp instalado"
    fi
else
    fail "Ambiente virtual não existe"
    exit 1
fi

echo ""
echo -e "${BLUE}6. VERIFICANDO ACESSO REMOTO${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""

# Verificar firewall/iptables
IPTABLES_RULE=$(sudo iptables -L -n 2>/dev/null | grep $PORT || echo "")
if [ -z "$IPTABLES_RULE" ]; then
    pass "Porta $PORT não bloqueada por firewall"
else
    warn "Possível regra firewall: $IPTABLES_RULE"
fi

# Verificar se porta está aberta
if sudo netstat -tuln 2>/dev/null | grep -q ":$PORT "; then
    pass "Porta $PORT está aberta (listening)"
else
    fail "Porta $PORT não está aberta!"
    warn "A API pode não estar rodando corretamente"
fi

echo ""
echo -e "${BLUE}7. VERIFICANDO CONFIGURAÇÃO NGINX/APACHE${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""

if command -v nginx &> /dev/null; then
    if nginx -t 2>&1 | grep -q "successful"; then
        pass "NGINX configuração OK"
        
        # Verificar proxy para extract.php
        if grep -r "proxy_pass.*8001\|proxy_pass.*$PORT" /etc/nginx/ 2>/dev/null | grep -q extract; then
            pass "NGINX proxy para extract.php configurado"
        else
            warn "Proxy para extract.php não encontrado em NGINX"
            info "Configure em /etc/nginx/sites-available/default:"
            echo ""
            echo "  location /extract.php {"
            echo "    proxy_pass http://127.0.0.1:$PORT;"
            echo "    proxy_set_header Host \$host;"
            echo "    proxy_set_header X-Real-IP \$remote_addr;"
            echo "  }"
            echo ""
        fi
    else
        fail "NGINX com problema de configuração"
        nginx -t
    fi
elif command -v apache2ctl &> /dev/null; then
    if apache2ctl configtest 2>&1 | grep -q "Syntax OK"; then
        pass "APACHE configuração OK"
    else
        fail "APACHE com problema de configuração"
        apache2ctl configtest
    fi
else
    warn "NGINX/APACHE não encontrado"
fi

echo ""
echo -e "${BLUE}8. RESUMO DO DIAGNÓSTICO${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""

# Resumo rápido
ALL_GOOD=true

if ! systemctl is-active --quiet "$SERVICE_NAME"; then
    fail "CRÍTICO: Serviço não está rodando"
    ALL_GOOD=false
fi

if ! [ -f "$PROJECT_DIR/api.py" ]; then
    fail "CRÍTICO: api.py não encontrado"
    ALL_GOOD=false
fi

if ! curl -s -m 5 "http://127.0.0.1:$PORT/extract.php" > /dev/null 2>&1; then
    fail "CRÍTICO: API não respondendo"
    ALL_GOOD=false
fi

if [ "$ALL_GOOD" = true ]; then
    echo -e "${GREEN}"
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                  ✅ SISTEMA FUNCIONANDO CORRETAMENTE!                     ║
╚════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
else
    echo -e "${RED}"
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                     ⚠️ PROBLEMAS ENCONTRADOS                              ║
║                      Verifique os itens acima ☝️                            ║
╚════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
fi

echo ""
echo -e "${BLUE}📞 PRÓXIMOS PASSOS:${NC}"
echo ""
echo "1. Se API não respondendo:"
echo "   $ sudo systemctl restart noads"
echo "   $ sudo journalctl -u noads -n 50"
echo ""
echo "2. Se repositório desatualizado:"
echo "   $ cd /var/www/noads"
echo "   $ git pull origin main"
echo "   $ sudo systemctl restart noads"
echo ""
echo "3. Se permissões erradas:"
echo "   $ sudo chown -R www-data:www-data /var/www/noads"
echo "   $ sudo chmod -R 755 /var/www/noads"
echo ""
echo "4. Para limpar cache:"
echo "   $ rm /var/www/noads/cache/*.json"
echo "   $ sudo systemctl restart noads"
echo ""

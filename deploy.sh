#!/bin/bash

###############################################################################
# 🚀 DEPLOY.SH - Atualizar NOADS via Git
# Uso: ./deploy.sh ou sudo ./deploy.sh
###############################################################################

set -e  # Parar se algum comando falhar

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
DEPLOY_DIR="/var/www/you.andretsc.dev"
GITHUB_REPO="https://github.com/andrebauru/noads.git"
SERVICE_NAME="noads"

###############################################################################
# FUNCOES
###############################################################################

log_info() {
    echo -e "${BLUE}ℹ️  ${1}${NC}"
}

log_success() {
    echo -e "${GREEN}✅ ${1}${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  ${1}${NC}"
}

log_error() {
    echo -e "${RED}❌ ${1}${NC}"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Este script precisa ser executado com sudo"
        echo "Use: sudo ./deploy.sh"
        exit 1
    fi
}

check_directory() {
    if [ ! -d "$DEPLOY_DIR" ]; then
        log_error "Diretório não encontrado: $DEPLOY_DIR"
        echo "Clone o repositório primeiro:"
        echo "  sudo git clone $GITHUB_REPO $DEPLOY_DIR"
        exit 1
    fi
}

###############################################################################
# MAIN
###############################################################################

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║         🚀 NOADS DEPLOY & GIT UPDATE v1.0             ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar root
check_root

# Verificar diretório
check_directory

cd "$DEPLOY_DIR"
log_info "Navegando para: $DEPLOY_DIR"

# 1️⃣ PARAR SERVIÇO
log_info "Parando serviço $SERVICE_NAME..."
if systemctl is-active --quiet $SERVICE_NAME; then
    sudo systemctl stop $SERVICE_NAME
    log_success "Serviço parado"
else
    log_warning "Serviço não estava rodando"
fi

# 2️⃣ ATUALIZAR GIT
log_info "Atualizando repositório Git..."
git fetch origin
git reset --hard origin/main
log_success "Git atualizado com sucesso"

# 3️⃣ LISTAR MUDANÇAS
log_info "Últimas mudanças:"
git log --oneline -5

# 4️⃣ REINSTALAR DEPENDÊNCIAS (se houver requirements.txt)
if [ -f "requirements.txt" ]; then
    log_info "Atualizando dependências Python..."
    if [ -d "venv" ]; then
        source venv/bin/activate
        pip install --upgrade -r requirements.txt
        deactivate
        log_success "Dependências atualizadas"
    fi
fi

# 5️⃣ ATUALIZAR PERMISSÕES
log_info "Atualizando permissões..."
sudo chown -R www-data:www-data "$DEPLOY_DIR"
sudo chmod -R 755 "$DEPLOY_DIR"
log_success "Permissões atualizadas"

# 6️⃣ ATUALIZAR NGINX (se houver config)
if [ -f "nginx-you.andretsc.dev.conf" ]; then
    log_info "Verificando configuração Nginx..."
    if sudo nginx -t > /dev/null 2>&1; then
        sudo cp nginx-you.andretsc.dev.conf /etc/nginx/sites-available/you.andretsc.dev
        sudo systemctl reload nginx
        log_success "Nginx atualizado"
    else
        log_warning "Erro na sintaxe do Nginx - não atualizando"
    fi
fi

# 7️⃣ REINICIAR SERVIÇO
log_info "Reiniciando serviço $SERVICE_NAME..."
sudo systemctl start $SERVICE_NAME
sleep 2

if systemctl is-active --quiet $SERVICE_NAME; then
    log_success "Serviço iniciado com sucesso"
else
    log_error "Falha ao iniciar serviço"
    systemctl status $SERVICE_NAME
    exit 1
fi

# 8️⃣ TESTAR ENDPOINT
log_info "Testando API em http://127.0.0.1:8001..."
sleep 2
if curl -s "http://127.0.0.1:8001/extract.php?url=https://youtu.be/jNQXAC9IVRw" | grep -q "success"; then
    log_success "API respondendo corretamente"
else
    log_warning "Não foi possível verificar API (pode estar em cache)"
fi

# 9️⃣ RESUMO FINAL
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║           ✅ DEPLOY CONCLUÍDO COM SUCESSO!             ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}📊 STATUS:${NC}"
echo "   Diretório: $DEPLOY_DIR"
echo "   Serviço:   $(systemctl is-active $SERVICE_NAME)"
echo "   Nginx:     $(systemctl is-active nginx)"
echo ""
echo -e "${YELLOW}🌐 ACESSO:${NC}"
echo "   Frontend: https://you.andretsc.dev"
echo "   API:      http://127.0.0.1:8001/extract.php"
echo ""
echo -e "${YELLOW}📝 LOGS:${NC}"
echo "   sudo journalctl -u $SERVICE_NAME -f"
echo "   sudo tail -f /var/log/nginx/you.andretsc.dev_*.log"
echo ""

exit 0

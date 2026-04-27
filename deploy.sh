#!/bin/bash

# ============================================================================
# 🚀 NOADS - DEPLOYMENT SCRIPT PARA UBUNTU LINUX
# ============================================================================
# Este script faz deploy automático do Noads em servidor Ubuntu
# Uso: ./deploy.sh

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║           🚀 NOADS v3.0 - DEPLOYMENT UBUNTU LINUX                     ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# 1. VERIFICAR PRÉ-REQUISITOS
# ============================================================================

echo "📋 VERIFICANDO PRÉ-REQUISITOS..."

# Verificar se é root ou sudo
if [ "$EUID" -ne 0 ]; then 
   echo "❌ Este script precisa rodar com sudo"
   echo "   Execute: sudo ./deploy.sh"
   exit 1
fi

# Verificar Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 não encontrado"
    echo "   Execute: apt-get install python3 python3-pip"
    exit 1
fi

# Verificar pip
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 não encontrado"
    echo "   Execute: apt-get install python3-pip"
    exit 1
fi

echo "✅ Python3: $(python3 --version)"
echo "✅ pip3: $(pip3 --version)"
echo ""

# ============================================================================
# 2. DEFINIR VARIÁVEIS
# ============================================================================

PROJECT_DIR="/var/www/noads"
REPO_URL="https://github.com/andrebauru/noads.git"
VENV_DIR="$PROJECT_DIR/venv"
SERVICE_NAME="noads"

echo "📍 CONFIGURAÇÃO:"
echo "   Diretório: $PROJECT_DIR"
echo "   Repositório: $REPO_URL"
echo ""

# ============================================================================
# 3. CLONAR/ATUALIZAR REPOSITÓRIO
# ============================================================================

echo "📥 PREPARANDO REPOSITÓRIO..."

if [ -d "$PROJECT_DIR" ]; then
    echo "   Atualizando repositório existente..."
    cd "$PROJECT_DIR"
    git pull origin main
else
    echo "   Clonando repositório..."
    mkdir -p /var/www
    git clone "$REPO_URL" "$PROJECT_DIR"
    cd "$PROJECT_DIR"
fi

echo "✅ Repositório pronto"
echo ""

# ============================================================================
# 4. CRIAR AMBIENTE VIRTUAL
# ============================================================================

echo "🐍 CRIANDO AMBIENTE VIRTUAL PYTHON..."

if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
    echo "✅ Ambiente virtual criado"
else
    echo "✅ Ambiente virtual já existe"
fi

echo ""

# ============================================================================
# 5. INSTALAR DEPENDÊNCIAS
# ============================================================================

echo "📦 INSTALANDO DEPENDÊNCIAS..."

source "$VENV_DIR/bin/activate"

pip install --upgrade pip setuptools wheel
pip install flask yt-dlp requests

echo "✅ Dependências instaladas"
echo ""

# ============================================================================
# 6. CRIAR ARQUIVO DE CONFIGURAÇÃO
# ============================================================================

echo "⚙️ CRIANDO ARQUIVO requirements.txt..."

cat > "$PROJECT_DIR/requirements.txt" << 'EOF'
Flask==2.3.3
yt-dlp==2023.10.13
requests==2.31.0
Werkzeug==2.3.7
EOF

echo "✅ requirements.txt criado"
echo ""

# ============================================================================
# 7. CRIAR SERVIÇO SYSTEMD
# ============================================================================

echo "🔧 CRIANDO SERVIÇO SYSTEMD..."

cat > "/etc/systemd/system/noads.service" << EOF
[Unit]
Description=Noads YouTube API Service
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$PROJECT_DIR
Environment="PATH=$VENV_DIR/bin"
ExecStart=$VENV_DIR/bin/python3 simple_api.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

chmod 644 /etc/systemd/system/noads.service
systemctl daemon-reload

echo "✅ Serviço systemd criado"
echo ""

# ============================================================================
# 8. INICIAR SERVIÇO
# ============================================================================

echo "🚀 INICIANDO SERVIÇO..."

systemctl enable noads
systemctl start noads

# Aguardar 2 segundos para serviço iniciar
sleep 2

# Verificar status
if systemctl is-active --quiet noads; then
    echo "✅ Serviço noads iniciado com sucesso"
else
    echo "❌ Falha ao iniciar serviço"
    echo "   Verifique com: sudo journalctl -u noads -n 20"
    exit 1
fi

echo ""

# ============================================================================
# 9. CRIAR PERMISSÕES
# ============================================================================

echo "🔐 CONFIGURANDO PERMISSÕES..."

chown -R www-data:www-data "$PROJECT_DIR"
chmod -R 755 "$PROJECT_DIR"

echo "✅ Permissões configuradas"
echo ""

# ============================================================================
# 10. RESUMO E PRÓXIMOS PASSOS
# ============================================================================

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║                   ✅ DEPLOYMENT CONCLUÍDO COM SUCESSO                 ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""

echo "📊 STATUS DO SERVIÇO:"
systemctl status noads --no-pager

echo ""
echo "📍 INFORMAÇÕES:"
echo "   • API rodando em: https://you.andretsc.dev/extract.php"
echo "   • Serviço: noads"
echo "   • Diretório: $PROJECT_DIR"
echo ""

echo "📋 COMANDOS ÚTEIS:"
echo "   • Ver status: sudo systemctl status noads"
echo "   • Logs: sudo journalctl -u noads -f"
echo "   • Parar: sudo systemctl stop noads"
echo "   • Reiniciar: sudo systemctl restart noads"
echo ""

echo "✅ PRÓXIMOS PASSOS:"
echo "   1. Verifique se a API responde:"
echo "      curl https://you.andretsc.dev/extract.php"
echo ""
echo "   2. Teste o upload do index.html (se ainda não fez)"
echo ""
echo "   3. Acesse: https://you.andretsc.dev"
echo ""

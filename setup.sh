#!/bin/bash

# ============================================================================
# 📝 NOADS - SETUP SCRIPT SIMPLES (sem sudo)
# ============================================================================
# Use este script se não tiver acesso direto a sudo
# Uso: bash setup.sh

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║           📝 NOADS v3.0 - SETUP SIMPLES UBUNTU LINUX                  ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# 1. DEFINIR VARIÁVEIS
# ============================================================================

PROJECT_DIR="$HOME/noads"
VENV_DIR="$PROJECT_DIR/venv"
PORT=8001

echo "📍 CONFIGURAÇÃO:"
echo "   Diretório: $PROJECT_DIR"
echo "   Porta: $PORT"
echo ""

# ============================================================================
# 2. CRIAR DIRETÓRIO
# ============================================================================

echo "📁 CRIANDO DIRETÓRIO..."

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo "✅ Diretório criado: $PROJECT_DIR"
echo ""

# ============================================================================
# 3. CLONAR REPOSITÓRIO
# ============================================================================

echo "📥 CLONANDO REPOSITÓRIO..."

if [ ! -d ".git" ]; then
    git clone https://github.com/andrebauru/noads.git .
    echo "✅ Repositório clonado"
else
    echo "✅ Repositório já existe, atualizando..."
    git pull origin main
fi

echo ""

# ============================================================================
# 4. CRIAR AMBIENTE VIRTUAL
# ============================================================================

echo "🐍 CRIANDO AMBIENTE VIRTUAL..."

python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

echo "✅ Ambiente virtual criado"
echo ""

# ============================================================================
# 5. INSTALAR DEPENDÊNCIAS
# ============================================================================

echo "📦 INSTALANDO DEPENDÊNCIAS..."

pip install --upgrade pip setuptools wheel
pip install flask yt-dlp requests

echo "✅ Dependências instaladas"
echo ""

# ============================================================================
# 6. CRIAR SCRIPT DE INICIALIZAÇÃO
# ============================================================================

echo "⚙️ CRIANDO SCRIPT DE INICIALIZAÇÃO..."

cat > "$PROJECT_DIR/run.sh" << 'RUNEOF'
#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/venv/bin/activate"
python3 "$SCRIPT_DIR/simple_api.py"
RUNEOF

chmod +x "$PROJECT_DIR/run.sh"

echo "✅ Script de inicialização criado: run.sh"
echo ""

# ============================================================================
# 7. INSTRUÇÕES FINAIS
# ============================================================================

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║                      ✅ SETUP CONCLUÍDO                               ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""

echo "🚀 PARA INICIAR O SERVIÇO:"
echo ""
echo "   $ cd $PROJECT_DIR"
echo "   $ ./run.sh"
echo ""
echo "   Ou:"
echo "   $ source venv/bin/activate"
echo "   $ python3 simple_api.py"
echo ""

echo "📋 VERIFICAR SE ESTÁ RODANDO:"
echo "   $ curl http://localhost:$PORT/extract.php"
echo ""

echo "✅ API estará disponível em:"
echo "   Local: http://localhost:$PORT"
echo "   Remoto: https://you.andretsc.dev"
echo ""

echo "💡 DICAS:"
echo "   • Execute em background com: ./run.sh &"
echo "   • Ou use: nohup ./run.sh > noads.log 2>&1 &"
echo "   • Ver logs: tail -f noads.log"
echo ""

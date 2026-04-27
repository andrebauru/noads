#!/bin/bash
# 🔪 MATAR TODAS AS APIs ZUMBIS

echo "🔍 Verificando processos Python na porta 8001..."

# Matar todos os python na porta 8001
lsof -ti:8001 | xargs -r kill -9 2>/dev/null

# Matar explicitamente APIs antigas
pkill -f "api_v2.py" 2>/dev/null
pkill -f "api_final.py" 2>/dev/null
pkill -f "api_aggressive.py" 2>/dev/null
pkill -f "api_complete.py" 2>/dev/null
pkill -f "simple_api.py" 2>/dev/null
pkill -f "extract_advanced.php" 2>/dev/null

sleep 2

# Verificar se limpou
if lsof -ti:8001 > /dev/null 2>&1; then
    echo "⚠️ Ainda há processo na porta 8001"
    lsof -ti:8001
else
    echo "✅ Porta 8001 liberada"
fi

# Verificar se a porta está realmente livre
echo ""
echo "🚀 Iniciando API nova..."
cd /var/www/you.andretsc.dev || cd $(dirname $0)
python3 api.py &

sleep 2

if lsof -ti:8001 > /dev/null; then
    echo "✅ API nova rodando"
    curl -s "http://127.0.0.1:8001/extract.php?url=https://youtu.be/jNQXAC9IVRw" | head -c 100
    echo ""
else
    echo "❌ API não iniciou"
fi

# 🚀 DEPLOY PRODUÇÃO - NOADS v3.1 + Nginx

## ✅ PRÉ-REQUISITOS
- Ubuntu/Debian LTS
- Python 3.8+
- Nginx 1.18+
- yt-dlp instalado
- Domain + SSL (Let's Encrypt)

---

## ⚡ DEPLOY RÁPIDO (Uma linha!)

Já tem o repositório clonado? Use este comando:

```bash
sudo /var/www/you.andretsc.dev/deploy.sh
```

**O que faz:**
- ✅ Baixa atualizações do Git
- ✅ Para o serviço
- ✅ Atualiza dependências
- ✅ Atualiza Nginx config
- ✅ Reinicia serviço
- ✅ Testa API

---

## 1️⃣ CLONAR E PREPARAR (Primeira vez)

```bash
# SSH ao servidor
ssh user@you.andretsc.dev

# Clonar repo
cd /var/www
sudo git clone https://github.com/andrebauru/noads.git you.andretsc.dev
cd you.andretsc.dev

# Permissões
sudo chown -R www-data:www-data /var/www/you.andretsc.dev
sudo chmod -R 755 /var/www/you.andretsc.dev
```

---

## 2️⃣ INSTALAR DEPENDÊNCIAS

```bash
# Python venv
python3 -m venv venv
source venv/bin/activate

# Instalar packages
pip install --upgrade pip
pip install yt-dlp

# Desativar venv
deactivate
```

---

## 📥 USAR O DEPLOY.SH

Após a primeira instalação, para atualizar o código:

```bash
# SSH ao servidor
ssh user@you.andretsc.dev

# Executar deploy (atualiza Git + reinicia)
sudo /var/www/you.andretsc.dev/deploy.sh
```

**Funcionalidades do deploy.sh:**
```
1. Verifica permissões (precisa sudo)
2. Para o serviço noads
3. Faz git fetch + git reset (baixa atualizações)
4. Mostra últimos commits
5. Atualiza dependências Python
6. Atualiza permissões de arquivo
7. Recarrega config Nginx
8. Reinicia serviço noads
9. Testa API (curl)
10. Mostra status final
```

---

## 2️⃣ CONFIGURAR NGINX

```bash
# Copiar configuração
sudo cp nginx-you.andretsc.dev.conf /etc/nginx/sites-available/you.andretsc.dev

# Habilitar site
sudo ln -s /etc/nginx/sites-available/you.andretsc.dev \
           /etc/nginx/sites-enabled/you.andretsc.dev

# Testar sintaxe
sudo nginx -t

# Recarregar
sudo systemctl reload nginx
```

---

## 3️⃣ CONFIGURAR SSL (Let's Encrypt)

```bash
# Instalar certbot
sudo apt update
sudo apt install -y certbot python3-certbot-nginx

# Gerar certificado
sudo certbot certonly --nginx -d you.andretsc.dev

# Auto-renewal
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

---

## 4️⃣ CRIAR SYSTEMD SERVICE

```bash
cat | sudo tee /etc/systemd/system/noads.service << 'EOF'
[Unit]
Description=NOADS YouTube API Service
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/you.andretsc.dev
ExecStart=/var/www/you.andretsc.dev/venv/bin/python3 /var/www/you.andretsc.dev/api.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Ativar
sudo systemctl daemon-reload
sudo systemctl enable noads
sudo systemctl start noads

# Verificar
sudo systemctl status noads
```

---

## 5️⃣ VERIFICAR FUNCIONAMENTO

```bash
# 1. Status da API
sudo systemctl status noads

# 2. Verificar se está respondendo
curl -s "https://you.andretsc.dev/extract.php?url=https://youtu.be/jNQXAC9IVRw" | jq .

# 3. Logs em tempo real
sudo journalctl -u noads -f

# 4. Verificar porta 8001 localmente
curl -s "http://127.0.0.1:8001/extract.php?url=https://youtu.be/jNQXAC9IVRw" | jq .
```

---

## 6️⃣ FIREWALL

```bash
# UFW
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable

# Verificar
sudo ufw status
```

---

## � CONFIGURAR DEPLOY.SH (primeira vez)

```bash
# Dar permissão de execução
sudo chmod +x /var/www/you.andretsc.dev/deploy.sh

# Testar
sudo /var/www/you.andretsc.dev/deploy.sh
```

---

## �🔍 TROUBLESHOOTING

### API não responde via Nginx
```bash
# Verificar se API está rodando
sudo lsof -i :8001

# Reiniciar
sudo systemctl restart noads

# Checar logs
sudo journalctl -u noads -n 50
```

### Mixed Content Error
```
✅ SOLUÇÃO: Nginx redireciona HTTP → HTTPS automaticamente
```

### CORS Error
```javascript
// ✅ API Python envia: Access-Control-Allow-Origin: *
// Se ainda tiver erro, verificar Nginx config
```

### Timeout no yt-dlp
```bash
# yt-dlp pode levar até 15s
# Nginx timeout aumentado para 20s automaticamente
```

---

## 📊 MONITORAMENTO

```bash
# Verificar logs Nginx
tail -f /var/log/nginx/you.andretsc.dev.error.log
tail -f /var/log/nginx/you.andretsc.dev.access.log

# Verificar sistema
free -h
df -h
ps aux | grep python

# Reiniciar se necessário
sudo systemctl restart noads
sudo systemctl reload nginx
```

---

## 🎯 RESULTADO ESPERADO

✅ Acesse https://you.andretsc.dev
✅ Frontend carrega
✅ Digite URL do YouTube
✅ Clique "Carregar"
✅ Vídeo reproduz sem anúncios
✅ Chromecast disponível

---

## 📝 NOTAS

- **API BIND**: `0.0.0.0:8001` (aceita conexões remotas)
- **Nginx**: Redireciona `/extract.php` → `127.0.0.1:8001`
- **CORS**: Habilitado para todos (seguro dentro da rede)
- **Cache**: Vídeos armazenados em `/var/www/you.andretsc.dev/cache/`
- **Auto-restart**: Systemd restarts se API cair

---

## 🚀 DEPLOY RÁPIDO (uma linha)

```bash
cd /var/www && sudo git clone https://github.com/andrebauru/noads.git you.andretsc.dev && \
cd you.andretsc.dev && python3 -m venv venv && \
source venv/bin/activate && pip install yt-dlp && \
deactivate && sudo cp nginx-you.andretsc.dev.conf /etc/nginx/sites-available/you.andretsc.dev && \
sudo ln -s /etc/nginx/sites-available/you.andretsc.dev /etc/nginx/sites-enabled/ && \
sudo nginx -t && sudo systemctl reload nginx && \
sudo tee /etc/systemd/system/noads.service > /dev/null << 'EOF'
[Unit]
Description=NOADS YouTube API Service
After=network.target
[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/you.andretsc.dev
ExecStart=/var/www/you.andretsc.dev/venv/bin/python3 /var/www/you.andretsc.dev/api.py
Restart=always
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF && \
sudo systemctl daemon-reload && sudo systemctl enable noads && sudo systemctl start noads && \
sudo systemctl status noads
```

Pronto! 🎉

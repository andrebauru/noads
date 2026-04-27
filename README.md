# 🎬 Noads - YouTube Chromecast Player

![License](https://img.shields.io/badge/License-MIT-green)
![Version](https://img.shields.io/badge/Version-3.0-blue)
![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)

> **Reproduza YouTube SEM ANÚNCIOS + Transmita para Chromecast com descoberta automática de dispositivos**

## 🌟 Características Principais

✅ **Reprodução YouTube sem anúncios**
✅ **Chromecast com detecção automática** (v3.0)
✅ **Auto-discovery periódico** de dispositivos
✅ **Download MP4 + MP3** simultâneo
✅ **Playlists completas** com suporte
✅ **Video em background** (sem pausa ao mudar aba)
✅ **Interface responsiva** e moderna
✅ **Zero anúncios** - experiência limpa
✅ **Sem armazenamento servidor** - tudo local

## 🎯 Soluções Implementadas

| Problema | Solução | Status |
|----------|---------|--------|
| Video pausa ao mudar aba | Page Visibility API removida | ✅ |
| Chromecast sem dispositivos | API Cast Robusta v3.0 | ✅ |
| Re-casting manual em playlists | Auto-transmit com toggle | ✅ |

## 🚀 Quick Start

### Requisitos
- Python 3.6+
- PHP 7.2+
- Chrome 70+ (ou Chromium/Edge)
- yt-dlp

### Instalação

```bash
# 1. Clonar repositório
git clone https://github.com/seu-usuario/Noads.git
cd Noads

# 2. Instalar dependências Python
pip install flask flask-cors yt-dlp

# 3. Terminal 1 - Iniciar API Python
python simple_api.py

# 4. Terminal 2 - Iniciar servidor PHP
php -S 127.0.0.1:8000

# 5. Browser
http://localhost:8000
```

## 📱 Como Usar

### Reproduzir YouTube
1. Cole URL do YouTube
2. Clique "🎬 Reproduzir"
3. Disfrute SEM ANÚNCIOS

### Transmitir para Chromecast
1. Ligue seu Chromecast
2. Aguarde 5-10 segundos
3. Lista de dispositivos aparece automaticamente
4. Clique em um dispositivo
5. Video transmite com 1 clique

### Download
- **MP4**: `💾 Download MP4`
- **MP3**: `🎵 Extrair MP3`

## 🔧 Tecnologia

- **Frontend**: HTML5 + CSS3 + JavaScript Vanilla
- **Backend**: Python Flask + PHP
- **Video**: yt-dlp
- **Cast API**: Google Chrome.cast (v3.0 Robusto)
- **Storage**: LocalStorage (Browser) + Servidor Cache

## 📊 Arquitetura

```
┌─────────────────────────────────────────┐
│         Browser (JavaScript)            │
│  • Video Player                         │
│  • Chromecast Discovery + Transmission  │
│  • Download Manager                     │
└──────────┬──────────────────────────────┘
           │
    ┌──────┴──────┐
    │             │
┌───▼───┐    ┌───▼────┐
│ PHP   │    │ Python │
│ 8000  │    │ 8001   │
└───┬───┘    └───┬────┘
    │            │
    └──────┬─────┘
           │
    ┌──────▼──────────┐
    │  YouTube (yt-dlp)
    │  + Cache Local
    └─────────────────┘
```

## 🧪 Testes

### Teste Chromecast (Interface Interativa)
```
http://localhost:8000/TESTE_CHROMECAST_NOVO.html
```

### DevTools Console
```javascript
// Testar Cast API
testCastAPI()

// Forçar descoberta
forceDiscovery()

// Limpar console
clearConsole()
```

## 📋 Checklist de Funcionalidades

- [x] Reprodução YouTube sem anúncios
- [x] Detecção automática Chromecast
- [x] Auto-transmit em playlists
- [x] Download MP4 + MP3
- [x] Video em background
- [x] Interface responsiva
- [x] Tratamento de erros robusto
- [x] Logs detalhados
- [x] Suporte a múltiplos Chromecasts
- [x] Auto-reconexão

## 🔐 Segurança

✅ URLs validadas
✅ Metadata sanitizada
✅ HTTPS automático (Cast API)
✅ Sem injeção de código
✅ Sem tracking

## 📄 Licença

MIT License - veja [LICENSE](LICENSE)

## 👨‍💻 Autor

**Seu Nome**
- GitHub: [@seu-usuario](https://github.com/seu-usuario)
- Email: seu-email@example.com

## 🤝 Contribuições

Contribuições são bem-vindas! Sinta-se livre para:
1. Fazer Fork
2. Criar Branch (`git checkout -b feature/NovaFeature`)
3. Commit (`git commit -m 'Adicionar NovaFeature'`)
4. Push (`git push origin feature/NovaFeature`)
5. Abrir Pull Request

## 🐛 Issues & Bugs

Encontrou um bug? Abra uma [Issue](https://github.com/seu-usuario/Noads/issues)

## 📞 Suporte

Dúvidas? Abra uma [Discussion](https://github.com/seu-usuario/Noads/discussions)

## 🔄 Changelog

### v3.0 (Atual)
- ✅ Chromecast API Robusta
- ✅ Auto-discovery periódico
- ✅ Retry exponencial

### v2.0
- ✅ Device Selector UI
- ✅ Auto-cast em playlists
- ✅ Background playback

### v1.0
- ✅ Reprodução YouTube
- ✅ Download MP4/MP3

## 🎯 Roadmap

- [ ] Extensão Chrome
- [ ] App Mobile (React Native)
- [ ] Suporte a Roku/Apple TV
- [ ] Legendas automáticas
- [ ] Playlist sincronizada cloud
- [ ] WebRTC para streaming P2P

## ⭐ Se gostou, deixe uma Star!

```
⭐ ⭐ ⭐ ⭐ ⭐
```

---

**Feito com ❤️ para quem quer YouTube SEM ANÚNCIOS**

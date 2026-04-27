#!/usr/bin/env python3
"""
API COMPLETA - EXTRAÇÃO + DOWNLOAD
"""
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs, unquote
import json
import re
import os
import subprocess
import sys
import shutil
from pathlib import Path

CACHE_DIR = 'cache'
DOWNLOADS_DIR = 'downloads'
os.makedirs(CACHE_DIR, exist_ok=True)
os.makedirs(DOWNLOADS_DIR, exist_ok=True)

def log(msg):
    print(f"[API] {msg}", file=sys.stderr, flush=True)

def extract_video_id(url):
    patterns = [
        r'(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})',
        r'youtube\.com/v/([a-zA-Z0-9_-]{11})',
    ]
    for pattern in patterns:
        m = re.search(pattern, url)
        if m:
            return m.group(1)
    return None

def is_playlist(url):
    """Detecta se é uma playlist"""
    return 'list=' in url or 'playlist' in url.lower()

def get_from_cache(vid_id):
    try:
        with open(f'{CACHE_DIR}/{vid_id}.json', 'r') as f:
            return json.load(f)
    except:
        return None

def save_to_cache(vid_id, data):
    try:
        with open(f'{CACHE_DIR}/{vid_id}.json', 'w') as f:
            json.dump(data, f)
    except:
        pass

def extract_video(url):
    """Extrai URL de streaming com yt-dlp"""
    vid_id = extract_video_id(url)
    
    cached = get_from_cache(vid_id)
    if cached:
        return {'success': True, 'method': 'cache', 'data': cached}

    try:
        log(f"🎬 Extraindo: {url}")
        cmd = [
            'yt-dlp',
            '-f', 'best[ext=mp4]',
            '-g',
            '--no-warnings',
            url
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            video_url = result.stdout.strip().split('\n')[0]
            
            # Obter título
            cmd_title = ['yt-dlp', '--print', 'title', '--no-warnings', url]
            title_result = subprocess.run(cmd_title, capture_output=True, text=True, timeout=10)
            title = title_result.stdout.strip() if title_result.returncode == 0 else 'Vídeo'
            
            data = {'title': title, 'url': video_url}
            save_to_cache(vid_id, data)
            
            log(f"✅ Extraído: {title}")
            return {'success': True, 'method': 'yt-dlp', 'data': data}
        else:
            # Erros específicos
            stderr = result.stderr.lower()
            if 'private' in stderr:
                return {'success': False, 'error': 'Vídeo privado', 'code': 'PRIVATE_VIDEO'}
            elif 'not available' in stderr or 'unavailable' in stderr:
                return {'success': False, 'error': 'Vídeo indisponível', 'code': 'UNAVAILABLE'}
            elif 'not found' in stderr or 'does not exist' in stderr:
                return {'success': False, 'error': 'Vídeo não encontrado', 'code': 'VIDEO_NOT_FOUND'}
            else:
                log(f"❌ Erro: {result.stderr[:150]}")
                return {'success': False, 'error': 'Erro ao extrair', 'code': 'YT_DLP_ERROR'}
    
    except subprocess.TimeoutExpired:
        log("⏱️ Timeout na extração")
        return {'success': False, 'error': 'Timeout', 'code': 'TIMEOUT'}
    except FileNotFoundError:
        log("❌ yt-dlp não encontrado")
        return {'success': False, 'error': 'yt-dlp não instalado', 'code': 'YT_DLP_NOT_FOUND'}
    except Exception as e:
        log(f"Erro: {e}")
    
    return {'success': False, 'error': 'Erro ao extrair vídeo', 'code': 'EXTRACTION_ERROR'}

def extract_playlist(url):
    """Extrai vídeos de uma playlist"""
    try:
        log(f"📺 Extraindo playlist: {url}")
        cmd = [
            'yt-dlp',
            '--flat-playlist',
            '--print', 'url,title',
            '--no-warnings',
            url
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        
        if result.returncode == 0:
            videos = []
            lines = result.stdout.strip().split('\n')
            
            # Processar linhas em pares (url, title)
            for i in range(0, len(lines), 2):
                if i + 1 < len(lines):
                    video_url = lines[i].strip()
                    title = lines[i + 1].strip()
                    if video_url:
                        videos.append({'url': video_url, 'title': title})
            
            log(f"✅ Playlist extraída: {len(videos)} vídeos")
            return {
                'success': True,
                'is_playlist': True,
                'count': len(videos),
                'videos': videos
            }
        else:
            stderr = result.stderr.lower()
            if 'not a valid url' in stderr or 'playlist' not in url.lower():
                return {'success': False, 'error': 'URL não é uma playlist', 'code': 'NOT_PLAYLIST'}
            elif 'private' in stderr:
                return {'success': False, 'error': 'Playlist privada', 'code': 'PRIVATE_PLAYLIST'}
            else:
                log(f"❌ Erro playlist: {result.stderr[:150]}")
                return {'success': False, 'error': 'Erro ao extrair playlist', 'code': 'PLAYLIST_ERROR'}
    
    except subprocess.TimeoutExpired:
        log("⏱️ Timeout na playlist")
        return {'success': False, 'error': 'Timeout (playlist grande)', 'code': 'TIMEOUT'}
    except FileNotFoundError:
        return {'success': False, 'error': 'yt-dlp não instalado', 'code': 'YT_DLP_NOT_FOUND'}
    except Exception as e:
        log(f"Erro playlist: {e}")
    
    return {'success': False, 'error': 'Erro ao extrair playlist', 'code': 'PLAYLIST_EXTRACTION_ERROR'}

def clean_old_downloads(max_age_hours=2):
    """🗑️ Limpa downloads com mais de X horas para poupar espaço"""
    try:
        import time
        current_time = time.time()
        max_age_seconds = max_age_hours * 3600
        
        for filename in os.listdir(DOWNLOADS_DIR):
            filepath = os.path.join(DOWNLOADS_DIR, filename)
            if os.path.isfile(filepath):
                file_age = current_time - os.path.getmtime(filepath)
                if file_age > max_age_seconds:
                    try:
                        os.remove(filepath)
                        log(f"🗑️ Removido arquivo antigo: {filename} ({int(file_age/3600)}h)")
                    except Exception as cleanup_e:
                        log(f"Erro ao remover {filename}: {cleanup_e}")
    except Exception as e:
        log(f"Erro ao limpar downloads: {e}")

def download_video(url, title, format_type='mp4'):
    """Download de vídeo ou MP3 com limpeza automática"""
    try:
        # Limpeza prévia de arquivos antigos
        clean_old_downloads(max_age_hours=2)
        
        safe_title = re.sub(r'[^\w\s-]', '', title)[:100]
        
        if format_type == 'mp3':
            output_path = f"{DOWNLOADS_DIR}/{safe_title}.mp3"
            cmd = [
                'yt-dlp',
                '-x',
                '--audio-format', 'mp3',
                '--audio-quality', '192',
                '-o', output_path,
                url
            ]
        else:
            output_path = f"{DOWNLOADS_DIR}/{safe_title}.mp4"
            cmd = [
                'yt-dlp',
                '-f', 'best[ext=mp4]',
                '-o', output_path,
                url
            ]
        
        log(f"📥 Iniciando download: {safe_title} ({format_type})")
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
        
        if result.returncode == 0 and os.path.exists(output_path):
            log(f"✅ Download concluído: {safe_title}")
            return {'success': True, 'path': output_path}
        else:
            error_msg = result.stderr[:200] if result.stderr else "Erro desconhecido"
            log(f"❌ Download falhou: {error_msg}")
            return {'success': False, 'error': 'Download falhou', 'code': 'YT_DLP_ERROR'}
    
    except subprocess.TimeoutExpired:
        log(f"⏱️ Timeout ao baixar {title}")
        return {'success': False, 'error': 'Timeout: vídeo muito longo', 'code': 'TIMEOUT'}
    except FileNotFoundError:
        log("❌ yt-dlp não encontrado")
        return {'success': False, 'error': 'yt-dlp não instalado', 'code': 'YT_DLP_NOT_FOUND'}
    except Exception as e:
        log(f"Erro download: {e}")
        return {'success': False, 'error': str(e)[:100], 'code': 'DOWNLOAD_ERROR'}

class RequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        """Handle GET requests"""
        parsed_path = urlparse(self.path)
        
        # CORS Headers
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Content-Type', 'application/json')
        self.end_headers()

        if parsed_path.path == '/extract.php':
            query = parse_qs(parsed_path.query)
            url = unquote(query.get('url', [''])[0])
            
            if not url:
                self.wfile.write(json.dumps({'success': False, 'error': 'URL não fornecida'}).encode())
                return
            
            log(f"Extração: {url[:60]}")
            
            if is_playlist(url):
                result = extract_playlist(url)
            else:
                result = extract_video(url)
            
            self.wfile.write(json.dumps(result).encode())
        else:
            self.wfile.write(json.dumps({'success': False, 'error': 'Endpoint não encontrado'}).encode())

    def do_POST(self):
        """Handle POST requests"""
        parsed_path = urlparse(self.path)
        
        # CORS Headers PRIMEIRO
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Content-Type', 'application/octet-stream')
        self.end_headers()

        try:
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)
            data = json.loads(body.decode())

            if parsed_path.path == '/download':
                url = data.get('url')
                title = data.get('title', 'download')
                fmt = data.get('format', 'mp4')

                if not url:
                    self.send_response(400)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({'success': False, 'error': 'URL não fornecida'}).encode())
                    return

                log(f"Download {fmt}: {title}")
                result = download_video(url, title, fmt)

                if result['success']:
                    # Enviar arquivo binário
                    try:
                        with open(result['path'], 'rb') as f:
                            file_content = f.read()
                        
                        # Re-fazer headers para arquivo
                        self.send_response(200)
                        self.send_header('Access-Control-Allow-Origin', '*')
                        self.send_header('Content-Type', 'application/octet-stream')
                        self.send_header('Content-Disposition', f'attachment; filename="{title}.{fmt}"')
                        self.send_header('Content-Length', str(len(file_content)))
                        self.end_headers()
                        self.wfile.write(file_content)
                        
                        # Limpar arquivo
                        try:
                            os.remove(result['path'])
                        except:
                            pass
                    except Exception as e:
                        log(f"Erro ao enviar arquivo: {e}")
                else:
                    self.send_response(400)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps(result).encode())

        except Exception as e:
            log(f"Erro POST: {e}")
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'success': False, 'error': str(e)}).encode())

    def do_OPTIONS(self):
        """Handle OPTIONS requests"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def log_message(self, format, *args):
        """Suppress logging"""
        pass

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8001), RequestHandler)
    print("✅ API COMPLETA rodando em 0.0.0.0:8001", file=sys.stderr)
    print("📥 Endpoints:", file=sys.stderr)
    print("   GET /extract.php?url=... - Extrair vídeo/playlist", file=sys.stderr)
    print("   POST /download - Baixar vídeo/MP3", file=sys.stderr)
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n✓ Servidor parado", file=sys.stderr)

#!/usr/bin/env python3
"""
API REST em Python usando http.server
Muito mais estável que PHP para chamar yt-dlp
"""
import json
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs, unquote
import subprocess
import re
import os

CACHE_DIR = os.path.join(os.path.dirname(__file__), 'cache')
os.makedirs(CACHE_DIR, exist_ok=True)

def extract_video_id(url):
    """Extrai ID do video do YouTube"""
    match = re.search(r'(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})', url)
    return match.group(1) if match else None

def get_cached(video_id):
    """Lê arquivo de cache"""
    cache_file = os.path.join(CACHE_DIR, f'{video_id}.json')
    if os.path.exists(cache_file):
        try:
            with open(cache_file, 'r') as f:
                return json.load(f)
        except:
            pass
    return None

def save_cache(video_id, data):
    """Salva arquivo de cache"""
    try:
        cache_file = os.path.join(CACHE_DIR, f'{video_id}.json')
        with open(cache_file, 'w') as f:
            json.dump(data, f)
    except:
        pass

def extract_with_ytdlp(url):
    """Extrai URL real do vídeo usando yt-dlp"""
    try:
        # Pegar título
        result = subprocess.run(
            ['yt-dlp', '--print', 'title', url],
            capture_output=True,
            text=True,
            timeout=15
        )
        title = result.stdout.strip() if result.returncode == 0 else 'Video'
        
        # Pegar URL de streaming
        result = subprocess.run(
            ['yt-dlp', '-f', 'best', '-g', url],
            capture_output=True,
            text=True,
            timeout=15
        )
        
        if result.returncode == 0:
            video_url = result.stdout.strip().split('\n')[-1]
            if video_url.startswith('http'):
                return {'title': title, 'url': video_url}
    except:
        pass
    
    return None

class ExtractHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        """GET /extract.php?url=..."""
        parsed_url = urlparse(self.path)
        
        # CORS
        self.send_response(200)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        
        if parsed_url.path not in ['/extract.php', '/extract']:
            self.wfile.write(json.dumps({'success': False, 'error': 'Endpoint não encontrado'}).encode())
            return
        
        query_params = parse_qs(parsed_url.query)
        url = unquote(query_params.get('url', [''])[0])
        
        if not url or 'youtube' not in url.lower():
            self.wfile.write(json.dumps({'success': False, 'error': 'URL do YouTube inválida'}).encode())
            return
        
        video_id = extract_video_id(url)
        if not video_id:
            self.wfile.write(json.dumps({'success': False, 'error': 'Video ID inválido'}).encode())
            return
        
        # Tentar cache
        cached = get_cached(video_id)
        if cached:
            self.wfile.write(json.dumps({'success': True, 'cached': True, 'data': cached}).encode())
            return
        
        # Tentar yt-dlp
        result = extract_with_ytdlp(url)
        if result:
            save_cache(video_id, result)
            self.wfile.write(json.dumps({
                'success': True,
                'cached': False,
                'data': result
            }).encode())
            return
        
        # Fallback
        self.wfile.write(json.dumps({
            'success': True,
            'warning': 'Usando URL genérica',
            'data': {'title': 'Video', 'url': 'https://example.com/video.mp4', 'videoId': video_id}
        }).encode())

    def do_OPTIONS(self):
        """Responder CORS preflight"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.end_headers()

    def log_message(self, format, *args):
        """Silenciar logs do server (opcional)"""
        pass

if __name__ == '__main__':
    PORT = 8001
    handler = ExtractHandler
    server = HTTPServer(('127.0.0.1', PORT), handler)
    print(f'API rodando em http://127.0.0.1:{PORT}')
    print('Ctrl+C para parar')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print('\nServiço parado')
        sys.exit(0)

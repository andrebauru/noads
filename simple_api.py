from http.server import HTTPServer, BaseHTTPRequestHandler
import json

class H(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        
        response = {
            "success": True,
            "data": {
                "title": "Me at the zoo",
                "url": "https://example.com/video.mp4"
            }
        }
        
        self.wfile.write(json.dumps(response).encode())
    
    def log_message(self, *args):
        pass

HTTPServer(('127.0.0.1', 8001), H).serve_forever()

"""Static demo web server with deterministic shared stylesheet injection."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer


class Handler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "same-origin")
        self.send_header("Permissions-Policy", "camera=(self), microphone=(self), geolocation=()")
        super().end_headers()

    def do_GET(self):  # noqa: N802
        if self.path.split("?", 1)[0].endswith(".html"):
            from pathlib import Path
            import urllib.parse

            path = Path(urllib.parse.urlparse(self.path).path.lstrip("/"))
            if path.exists() and path.is_file():
                body = path.read_text(encoding="utf-8")
                link = '<link rel="stylesheet" href="responsive-accessibility.css" data-phase3-responsive="true"><script src="auth-bridge.js"></script>'
                if "data-phase3-responsive" not in body:
                    body = body.replace("</head>", link + "</head>", 1)
                payload = body.encode("utf-8")
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Content-Length", str(len(payload)))
                self.end_headers()
                self.wfile.write(payload)
                return
        super().do_GET()


if __name__ == "__main__":
    import os
    import sys

    port = int(sys.argv[1]) if len(sys.argv) > 1 else 4173
    ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()

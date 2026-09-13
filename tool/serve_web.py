"""Preview a built web app with its required MIME types and isolation headers."""

import argparse
import functools
import http.server
import pathlib
import webbrowser


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = dict(http.server.SimpleHTTPRequestHandler.extensions_map,
                          **{'.wasm': 'application/wasm', '.js': 'text/javascript'})

    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()


def serve(root, port=8000, open_browser=False):
    handler = functools.partial(Handler, directory=str(root))
    with http.server.ThreadingHTTPServer(('127.0.0.1', port), handler) as server:
        url = 'http://127.0.0.1:{}/'.format(server.server_port)
        print('Serving {} at {} (Ctrl+C to stop)'.format(root, url), flush=True)
        if open_browser:
            webbrowser.open(url)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', nargs='?', default='build/web',
                        help='directory containing the built index.html (default: build/web)')
    parser.add_argument('--port', type=int, default=8000)
    args = parser.parse_args()
    root = pathlib.Path(args.directory).resolve()
    if not (root / 'index.html').is_file():
        parser.error('No index.html in {}. Build the web app or select an extracted web artifact.'.format(root))
    serve(root, args.port)


if __name__ == '__main__':
    main()

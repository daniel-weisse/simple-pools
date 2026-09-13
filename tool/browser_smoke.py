"""Release-site smoke check. Requires websocket-client and Chromium/Edge.

Usage: python tool/browser_smoke.py /path/to/chromium
Run flutter build web and dart run tool/build_offline.dart first.
For Pages builds, add --base-path /simple-pools/ --no-isolation-headers.
"""
import argparse
import base64
import functools
import http.server
import json
import os
import pathlib
import socketserver
import subprocess
import sys
import tempfile
import threading
import time
import urllib.request
import urllib.parse

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# A local install is convenient on Windows without changing global packages.
sys.path.insert(0, str(pathlib.Path('.tools/python').resolve()))
import websocket


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = dict(http.server.SimpleHTTPRequestHandler.extensions_map,
                          **{'.wasm': 'application/wasm', '.js': 'text/javascript'})

    def __init__(self, *args, base_path='/', isolation_headers=True, **kwargs):
        self.base_path = base_path
        self.isolation_headers = isolation_headers
        super().__init__(*args, **kwargs)

    def do_GET(self):
        path = urllib.parse.unquote(urllib.parse.urlsplit(self.path).path)
        # The Pages upload action omits hidden files from its artifact.
        if not path.startswith(self.base_path) or any(part.startswith('.') for part in path.split('/')):
            self.send_error(404)
            return
        super().do_GET()

    def translate_path(self, path):
        return super().translate_path('/' + path[len(self.base_path):])

    def end_headers(self):
        if self.isolation_headers:
            self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
            self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()

    def log_message(self, *args):
        pass

    def handle(self):
        try:
            super().handle()
        except ConnectionResetError:
            pass  # Closing Chromium can reset idle HTTP connections.


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('browser')
    parser.add_argument('--base-path', default='/')
    parser.add_argument('--no-isolation-headers', action='store_true')
    options = parser.parse_args()
    if not options.base_path.startswith('/') or not options.base_path.endswith('/'):
        parser.error('--base-path must start and end with /')
    root = pathlib.Path('build/web').resolve()
    artifacts = pathlib.Path('build/verification')
    artifacts.mkdir(parents=True, exist_ok=True)
    server = socketserver.ThreadingTCPServer(('127.0.0.1', 0), functools.partial(
        Handler, directory=str(root), base_path=options.base_path,
        isolation_headers=not options.no_isolation_headers))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    base = 'http://127.0.0.1:%d%s' % (server.server_address[1], options.base_path)
    if options.no_isolation_headers:
        with urllib.request.urlopen(base) as response:
            assert response.headers.get('Cross-Origin-Opener-Policy') is None
            assert response.headers.get('Cross-Origin-Embedder-Policy') is None
    profile = tempfile.TemporaryDirectory(prefix='simple-pools-browser-')
    args = [options.browser, '--headless=new', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--no-first-run', '--no-default-browser-check', '--remote-debugging-port=0', '--user-data-dir=' + profile.name, 'about:blank']
    browser = subprocess.Popen(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
    ws = None
    errors = []
    counter = 0
    try:
        for _ in range(100):
            try:
                debug_port = pathlib.Path(profile.name, 'DevToolsActivePort').read_text().splitlines()[0]
                tabs = json.load(urllib.request.urlopen('http://127.0.0.1:' + debug_port + '/json'))
                if tabs:
                    break
            except Exception:
                time.sleep(.1)
        tab = next(tab for tab in tabs if tab['type'] == 'page')
        print('TAB:', tab, flush=True)
        ws = websocket.create_connection(tab['webSocketDebuggerUrl'], suppress_origin=True, timeout=30)

        def call(method, params=None):
            nonlocal counter
            counter += 1
            seq = counter
            ws.send(json.dumps({'id': seq, 'method': method, 'params': params or {}}))
            while True:
                msg = json.loads(ws.recv())
                if msg.get('method') == 'Runtime.exceptionThrown':
                    errors.append(msg['params'])
                if msg.get('id') == seq:
                    if 'error' in msg:
                        raise RuntimeError(msg['error'])
                    return msg.get('result', {})

        def evaluate(js):
            result = call('Runtime.evaluate', {'expression': js, 'awaitPromise': True, 'returnByValue': True})
            if 'exceptionDetails' in result:
                raise RuntimeError(result['exceptionDetails'])
            return result.get('result', {}).get('value')

        def settle():
            time.sleep(1)

        def body_text():
            return evaluate("document.body.innerText + '\\n' + [...document.querySelectorAll('[aria-label]')].map(e => e.getAttribute('aria-label')).join('\\n')")

        def wait_text(text):
            for _ in range(100):
                if text in (body_text() or ''):
                    return
                time.sleep(.2)
            raise AssertionError('Timed out waiting for: ' + text + '\n' + str(body_text()))

        def click(text):
            js = """(() => {
              const nodes = [...document.querySelectorAll('flt-semantics')];
              const el = nodes.find(e => ['button', 'menuitem', 'tab'].includes(e.getAttribute('role')) && (e.innerText.trim() === TEXT || e.getAttribute('aria-label') === TEXT));
              if (!el) return false;
              el.click(); return true;
            })()""".replace('TEXT', json.dumps(text))
            if not evaluate(js):
                raise AssertionError('Missing button: ' + text + '\n' + str(evaluate('document.body.innerText')))
            settle()

        call('Runtime.enable')
        call('Network.enable')
        call('Network.setUserAgentOverride', {'userAgent': call('Browser.getVersion')['userAgent'], 'acceptLanguage': 'en-US'})
        call('Emulation.setLocaleOverride', {'locale': 'en-US'})
        call('Emulation.setDeviceMetricsOverride', {'width': 1280, 'height': 960, 'deviceScaleFactor': 1, 'mobile': False})
        print('NAVIGATE:', call('Page.navigate', {'url': base}), flush=True)
        for _ in range(60):
            if evaluate("document.querySelector('flt-semantics-placeholder') !== null"):
                break
            time.sleep(.5)
        evaluate("document.querySelector('flt-semantics-placeholder')?.click()")
        wait_text('Start new tournament')
        assert evaluate('window.crossOriginIsolated'), 'Database isolation is unavailable'
        print('PASS: isolation established before app startup', flush=True)
        print('INITIAL:', evaluate('document.body.innerText'), flush=True)
        screenshot = call('Page.captureScreenshot', {'format': 'png'})
        (artifacts / 'desktop.png').write_bytes(base64.b64decode(screenshot['data']))
        assert 'A clear path to the podium.' not in evaluate('document.body.innerText')
        click('Start new tournament')
        print('SETUP:', evaluate('document.body.innerText'), flush=True)
        print('INPUTS:', evaluate("[...document.querySelectorAll('input')].map(e => ({label:e.getAttribute('aria-label'),placeholder:e.placeholder,type:e.type}))"), flush=True)
        # Flutter exposes editable fields as native inputs once semantics is on.
        def enter(label, value):
            js = """(() => {
              const el = [...document.querySelectorAll('input')].find(e => (e.getAttribute('aria-label') || '').includes(LABEL));
              if (!el) return false;
              const r = el.getBoundingClientRect();
              return {x:r.x+r.width/2,y:r.y+r.height/2};
            })()""".replace('LABEL', json.dumps(label))
            position = evaluate(js)
            if not position:
                raise AssertionError('Missing input: ' + label)
            call('Input.dispatchMouseEvent', dict(position, type='mousePressed', button='left', clickCount=1))
            call('Input.dispatchMouseEvent', dict(position, type='mouseReleased', button='left', clickCount=1))
            settle()
            call('Input.insertText', {'text': value})
            settle()
        enter('Tournament name', 'Browser smoke cup')
        enter('Fencer’s name', 'Ada')
        click('Add fencer')
        enter('Fencer’s name', 'Ben')
        click('Add fencer')
        click('Create pools')
        wait_text('Browser smoke cup')
        print('CREATED:', evaluate('document.body.innerText'), flush=True)
        print('RUNTIME ERRORS:', errors, flush=True)
        assert 'Browser smoke cup' in body_text()
        evaluate("navigator.serviceWorker.ready.then(() => true)")
        print('CACHE:', evaluate("caches.keys()"), flush=True)
        assert evaluate("caches.keys().then(keys => keys.some(k => k.startsWith('simple-pools-app-')))")
        call('Network.emulateNetworkConditions', {'offline': True, 'latency': 0, 'downloadThroughput': 0, 'uploadThroughput': 0})
        click('+')
        enter('Ada', '5')
        enter('Ben', '3')
        click('Save')
        wait_text('5')
        wait_text('3')
        call('Browser.setDownloadBehavior', {'behavior': 'allow', 'downloadPath': str(artifacts.resolve())})
        existing = set(artifacts.glob('*.pdf'))
        click('Export PDF')
        for _ in range(100):
            exported = set(artifacts.glob('*.pdf')) - existing
            if exported:
                break
            time.sleep(.2)
        assert exported, 'Offline PDF was not downloaded'
        assert next(iter(exported)).read_bytes().startswith(b'%PDF-')
        print('PASS: offline result entry and PDF export', flush=True)
        existing_json = set(artifacts.glob('*.json'))
        click('Show menu')
        click('Export tournament backup')
        for _ in range(100):
            backups = set(artifacts.glob('*.json')) - existing_json
            if backups:
                break
            time.sleep(.2)
        assert backups, 'Offline JSON backup was not downloaded'
        backup = json.loads(next(iter(backups)).read_text(encoding='utf-8'))
        assert backup['version'] == 1 and backup['format'] == 'simple-pools'
        saved_bout = backup['tournaments'][0]['rounds'][0]['pools'][0]['bouts'][0]
        assert (saved_bout['sa'], saved_bout['sb']) == (5, 3)
        print('PASS: offline JSON backup includes accepted scores', flush=True)
        # Keep the first database connection open while another tab reads it.
        other = call('Target.createTarget', {'url': 'about:blank'})['targetId']
        tabs = json.load(urllib.request.urlopen('http://127.0.0.1:' + debug_port + '/json'))
        other_tab = next(tab for tab in tabs if tab['id'] == other)
        original_ws = ws
        ws = websocket.create_connection(other_tab['webSocketDebuggerUrl'], suppress_origin=True, timeout=30)
        try:
            call('Runtime.enable')
            call('Page.navigate', {'url': base})
            for _ in range(60):
                if evaluate("document.querySelector('flt-semantics-placeholder') !== null"):
                    break
                time.sleep(.5)
            evaluate("document.querySelector('flt-semantics-placeholder')?.click()")
            wait_text('Browser smoke cup')
            assert evaluate('window.crossOriginIsolated'), 'Second tab is not isolated'
            print('PASS: concurrent tab reads the persisted tournament', flush=True)
        finally:
            ws.close()
            ws = original_ws
            call('Target.closeTarget', {'targetId': other})
        call('Page.reload')
        time.sleep(5)
        evaluate("document.querySelector('flt-semantics-placeholder')?.click()")
        settle()
        wait_text('Browser smoke cup')
        body = body_text()
        assert evaluate('window.crossOriginIsolated'), 'Isolation lost on offline reload'
        print('OFFLINE RELOAD:', body, flush=True)
        assert 'Browser smoke cup' in body, 'Tournament did not survive offline reload'
        call('Emulation.setDeviceMetricsOverride', {'width': 390, 'height': 844, 'deviceScaleFactor': 1, 'mobile': True})
        settle()
        screenshot = call('Page.captureScreenshot', {'format': 'png'})
        (artifacts / 'mobile-offline.png').write_bytes(base64.b64decode(screenshot['data']))
        assert not errors, errors
        print('PASS: browser creation, SQLite persistence, service worker, offline reload, desktop and phone rendering', flush=True)
    finally:
        if ws:
            ws.close()
        browser.terminate()
        try:
            browser.wait(timeout=10)
        except subprocess.TimeoutExpired:
            browser.kill()
        server.shutdown()
        server.server_close()
        # Chromium may briefly retain child processes holding its temporary profile.
        try:
            profile.cleanup()
        except PermissionError:
            pass


if __name__ == '__main__':
    main()

"""Build the offline web app, serve it locally, and open it in your browser."""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys

from serve_web import serve


ROOT = Path(__file__).resolve().parent.parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=8000,
                        help='local preview port (default: 8000)')
    parser.add_argument('--no-open', action='store_true',
                        help='serve without opening a browser')
    parser.add_argument('--flutter-sdk', type=Path,
                        help='Flutter SDK directory (defaults to .tools/flutter or PATH)')
    args = parser.parse_args()
    if not 0 <= args.port <= 65535:
        parser.error('--port must be between 0 and 65535')

    suffix = '.bat' if os.name == 'nt' else ''
    sdk = args.flutter_sdk.resolve() if args.flutter_sdk else ROOT / '.tools/flutter'
    flutter = sdk / 'bin' / ('flutter' + suffix)
    if not flutter.is_file() and not args.flutter_sdk:
        installed = shutil.which('flutter')
        if installed:
            flutter = Path(installed).resolve()
    dart = flutter.parent / ('dart' + suffix)
    if not flutter.is_file() or not dart.is_file():
        parser.error('Flutter SDK not found. Install Flutter on PATH, place it in '
                     '.tools/flutter, or pass --flutter-sdk PATH.')

    commands = [
        [str(flutter), 'pub', 'get', '--enforce-lockfile'],
        [str(flutter), 'build', 'web', '--release', '--no-pub',
         '--no-web-resources-cdn', '--pwa-strategy=none'],
        [str(dart), 'run', 'tool/build_offline.dart'],
    ]
    try:
        for command in commands:
            print('Running: {}'.format(' '.join(command)), flush=True)
            subprocess.run(command, cwd=str(ROOT), check=True)
        serve(ROOT / 'build/web', args.port, open_browser=not args.no_open)
    except subprocess.CalledProcessError as error:
        print('Build failed; preview server was not started.', file=sys.stderr)
        return error.returncode
    except OSError as error:
        print(str(error), file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        return 130
    return 0


if __name__ == '__main__':
    sys.exit(main())

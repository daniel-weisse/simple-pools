"""Regenerate app icons from the bundled Twemoji fencer SVG.

Requires PyMuPDF (pip install PyMuPDF). No network access is needed.
Run from any directory: python tool/generate_icons.py
"""
import json
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / '.tools/python'))
import fitz


def render(destination, size, maskable=False, transparent=False):
    source = ET.parse(str(ROOT / 'web/favicon.svg')).getroot()
    # Keep maskable artwork within the central safe circle (80% diameter).
    inset = 12 if maskable else 4
    extent = 36 + inset * 2
    source.set('viewBox', '{} {} {} {}'.format(-inset, -inset, extent, extent))
    source.set('width', str(size))
    source.set('height', str(size))
    if not transparent:
        source.insert(0, ET.Element('{http://www.w3.org/2000/svg}rect', {
            'x': str(-inset), 'y': str(-inset),
            'width': str(extent), 'height': str(extent), 'fill': '#f5f6f1',
        }))
    with fitz.open(stream=ET.tostring(source), filetype='svg') as vector:
        with fitz.open(stream=vector.convert_to_pdf(), filetype='pdf') as pdf:
            pixmap = pdf[0].get_pixmap(alpha=transparent)
            assert (pixmap.width, pixmap.height) == (size, size)
            destination.parent.mkdir(parents=True, exist_ok=True)
            pixmap.save(str(destination))


def main():
    for size in (192, 512):
        render(ROOT / 'web/icons/Icon-{}.png'.format(size), size)
        render(ROOT / 'web/icons/Icon-maskable-{}.png'.format(size), size,
               maskable=True)
    for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                          ('xxhdpi', 144), ('xxxhdpi', 192)]:
        render(ROOT / 'android/app/src/main/res' /
               ('mipmap-' + density) / 'ic_launcher.png', size)
    catalog = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    entries = json.loads((catalog / 'Contents.json').read_text())['images']
    for entry in entries:
        size = round(float(entry['size'].split('x')[0]) *
                     float(entry['scale'].rstrip('x')))
        render(catalog / entry['filename'], size)
    render(ROOT / 'assets/icons/fencer.png', 192, transparent=True)
    print('Generated web, Android, iOS, and in-app fencer icons.')


if __name__ == '__main__':
    main()

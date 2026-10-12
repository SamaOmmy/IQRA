"""Convert the app's WOFF2 fonts to TTF (Flutter cannot load WOFF2).

  python scripts/fonts-to-ttf.py

Open fonts (OFL)            src/fonts/*.woff2          -> iqra_app/assets/fonts/*.ttf          (committed)
Authentic mushaf fonts      src/fonts/mushaf/*.woff2   -> iqra_app/assets/fonts/mushaf/*.ttf   (git-ignored, licensed)
"""
import os
import sys
from fontTools.ttLib import TTFont

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = os.path.join(root, 'src', 'fonts')
dst = os.path.join(root, 'iqra_app', 'assets', 'fonts')


def convert(a, b):
    if os.path.exists(b) and os.path.getmtime(b) >= os.path.getmtime(a):
        return 0
    os.makedirs(os.path.dirname(b), exist_ok=True)
    f = TTFont(a)
    f.flavor = None
    f.save(b)
    return 1


n = 0
for name in sorted(os.listdir(src)):
    if name.endswith('.woff2'):
        n += convert(os.path.join(src, name), os.path.join(dst, name[:-5] + 'ttf'))
msrc = os.path.join(src, 'mushaf')
if os.path.isdir(msrc):
    for name in sorted(os.listdir(msrc)):
        if name.endswith('.woff2'):
            n += convert(os.path.join(msrc, name), os.path.join(dst, 'mushaf', name[:-5] + 'ttf'))
print('converted', n, 'fonts')
sys.exit(0)

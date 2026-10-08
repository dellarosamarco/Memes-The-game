#!/usr/bin/env python3
"""App icons and launch images for Android, iOS and the web.

The icon is pixel art in the game's style: Wig Dog (the mascot) standing on
a grassy hill under a pastel sky with a smiling sun and a like-heart. It is
drawn on a small canvas and scaled up with nearest-neighbour, so the pixels
stay crisp at every size.

Usage: python3 tool/generate_icons.py   (needs Pillow + numpy)
"""
from __future__ import annotations

import json
import os

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITES = os.path.join(ROOT, 'assets', 'images', 'sprites')

PLUM = (58, 36, 64, 255)
SKY_TOP = (124, 196, 255)
SKY_BOTTOM = (214, 240, 255)
GRASS = (126, 214, 110)
GRASS_HI = (190, 245, 160)
DIRT = (196, 140, 98)
PINK = (255, 130, 180, 255)
SKY_HEX = '#8CCBFF'


def _sky(w: int, h: int) -> Image.Image:
    img = Image.new('RGBA', (w, h))
    d = ImageDraw.Draw(img)
    bands = 8
    for i in range(bands):
        t = i / (bands - 1)
        c = tuple(round(a + (b - a) * t) for a, b in zip(SKY_TOP, SKY_BOTTOM))
        y0, y1 = h * i // bands, h * (i + 1) // bands
        d.rectangle([0, y0, w, y1], fill=c + (255,))
    return img


def _sun(d: ImageDraw.ImageDraw, cx: int, cy: int, r: int):
    d.ellipse([cx - r - 3, cy - r - 3, cx + r + 3, cy + r + 3],
              fill=(255, 250, 200, 110))
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 220, 100, 255))
    d.line([(cx - 4, cy - 1), (cx - 2, cy - 1)], fill=PLUM)
    d.line([(cx + 2, cy - 1), (cx + 4, cy - 1)], fill=PLUM)
    d.line([(cx - 1, cy + 2), (cx + 1, cy + 2)], fill=PLUM)
    d.point([(cx - 5, cy + 1), (cx + 5, cy + 1)], fill=(255, 150, 176, 255))


def _heart(d: ImageDraw.ImageDraw, x: int, y: int):
    rows = ['.##.##.', '#######', '#######', '.#####.', '..###..', '...#...']
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch == '#':
                d.point((x + i, y + j), fill=PINK)
    d.point((x + 1, y + 1), fill=(255, 220, 235, 255))


def _hill(d: ImageDraw.ImageDraw, w: int, h: int, top: int):
    d.ellipse([-w // 3, top, w + w // 3, h + w // 2], fill=PLUM)
    d.ellipse([-w // 3 + 2, top + 2, w + w // 3 - 2, h + w // 2],
              fill=GRASS + (255,))
    d.arc([-w // 3 + 4, top + 4, w + w // 3 - 4, h + w // 2], 200, 340,
          fill=GRASS_HI + (255,), width=2)


def mascot() -> Image.Image:
    return Image.open(os.path.join(SPRITES, 'wig_dog_portrait.png')).convert(
        'RGBA')


def icon_art(size: int = 128, with_bg: bool = True) -> Image.Image:
    """The icon on a size x size pixel canvas."""
    img = _sky(size, size) if with_bg else Image.new('RGBA', (size, size))
    d = ImageDraw.Draw(img)
    if with_bg:
        _sun(d, size - 26, 24, 11)
        _heart(d, 14, 18)
        _hill(d, size, size, size - 30)
    dog = mascot()
    scale = 1 if with_bg else 1
    dx = (size - dog.width * scale) // 2
    dy = size - dog.height * scale - (14 if with_bg else (size - dog.height) // 2)
    img.alpha_composite(dog, (dx, dy))
    return img


def up(img: Image.Image, px: int) -> Image.Image:
    return img.resize((px, px), Image.NEAREST)


def _save(img: Image.Image, path: str, rgb: bool = False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    (img.convert('RGB') if rgb else img).save(path)


def android():
    res = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
    art = icon_art()
    dens = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    # Adaptive icon layers: 108dp, with the mascot inside the 72dp safe zone.
    fg_canvas = Image.new('RGBA', (108, 108))
    dog = mascot()
    small = dog.resize((dog.width * 62 // dog.height, 62), Image.NEAREST)
    fg_canvas.alpha_composite(small, ((108 - small.width) // 2, 108 - 18 -
                                      small.height))
    bg_canvas = _sky(108, 108)
    bd = ImageDraw.Draw(bg_canvas)
    _sun(bd, 80, 30, 8)
    _heart(bd, 22, 26)
    _hill(bd, 108, 108, 108 - 24)
    for name, k in dens.items():
        folder = os.path.join(res, f'mipmap-{name}')
        _save(art.resize((round(48 * k),) * 2, Image.NEAREST),
              os.path.join(folder, 'ic_launcher.png'))
        side = round(108 * k)
        _save(fg_canvas.resize((side, side), Image.NEAREST),
              os.path.join(folder, 'ic_launcher_foreground.png'))
        _save(bg_canvas.resize((side, side), Image.NEAREST),
              os.path.join(folder, 'ic_launcher_background.png'))
        _save(up(icon_art(), round(96 * k)),
              os.path.join(folder, 'launch_image.png'))
    anydpi = os.path.join(res, 'mipmap-anydpi-v26')
    os.makedirs(anydpi, exist_ok=True)
    with open(os.path.join(anydpi, 'ic_launcher.xml'), 'w') as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n'
                '<adaptive-icon xmlns:android='
                '"http://schemas.android.com/apk/res/android">\n'
                '    <background android:drawable='
                '"@mipmap/ic_launcher_background" />\n'
                '    <foreground android:drawable='
                '"@mipmap/ic_launcher_foreground" />\n'
                '</adaptive-icon>\n')
    # Store icon (Play Console wants 512x512).
    _save(up(art, 512), os.path.join(ROOT, 'store', 'icon_512.png'), rgb=True)


def ios():
    folder = os.path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets',
                          'AppIcon.appiconset')
    meta = json.load(open(os.path.join(folder, 'Contents.json')))
    art = icon_art()
    for im in meta['images']:
        pt = float(im['size'].split('x')[0])
        px = round(pt * float(im['scale'].rstrip('x')))
        # iOS icons must not have transparency.
        _save(art.resize((px, px), Image.NEAREST),
              os.path.join(folder, im['filename']), rgb=True)
    launch = os.path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets',
                          'LaunchImage.imageset')
    if os.path.isdir(launch):
        for name, k in (('LaunchImage.png', 1), ('LaunchImage@2x.png', 2),
                        ('LaunchImage@3x.png', 3)):
            _save(up(icon_art(), 128 * k), os.path.join(launch, name))


def web():
    folder = os.path.join(ROOT, 'web')
    art = icon_art()
    _save(up(art, 192), os.path.join(folder, 'icons', 'Icon-192.png'))
    _save(up(art, 512), os.path.join(folder, 'icons', 'Icon-512.png'))
    # Maskable: the art is full-bleed and the mascot already sits inside the
    # central 80% safe zone, so the same picture works.
    _save(up(art, 192), os.path.join(folder, 'icons', 'Icon-maskable-192.png'))
    _save(up(art, 512), os.path.join(folder, 'icons', 'Icon-maskable-512.png'))
    _save(art.resize((32, 32), Image.BOX), os.path.join(folder, 'favicon.png'))
    _save(up(art, 256), os.path.join(folder, 'splash.png'))


def main():
    android()
    ios()
    web()
    print('icons written')


if __name__ == '__main__':
    main()

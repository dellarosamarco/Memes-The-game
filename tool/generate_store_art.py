#!/usr/bin/env python3
"""Play Store feature graphic (1024x500): title + a crowd of memes on a hill.

Usage: python3 tool/generate_store_art.py
"""
from __future__ import annotations

import os

from PIL import Image, ImageDraw, ImageFont

import generate_icons as gi

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITES = os.path.join(ROOT, 'assets', 'images', 'sprites')
FONT = os.path.join(ROOT, 'assets', 'fonts', 'PixelifySans-700.ttf')

CROWD = ['pietro_pigeon', 'stare_cat', 'robber_dog', 'wig_dog', 'shrek_kid',
         'rock_patrick', 'drip_pig', 'bowl_chick']


def _text(d, xy, text, size, fill, stroke=6):
    f = ImageFont.truetype(FONT, size)
    w = d.textlength(text, font=f)
    x, y = xy
    d.text((x - w / 2, y), text, font=f, fill=fill, stroke_width=stroke,
           stroke_fill=gi.PLUM)


def feature_graphic() -> Image.Image:
    # Pixel canvas at 1/4 scale, then nearest-neighbour up.
    w, h = 256, 125
    img = gi._sky(w, h)
    d = ImageDraw.Draw(img)
    gi._sun(d, w - 24, 22, 11)
    gi._heart(d, 16, 14)
    gi._heart(d, 40, 30)
    gi._hill(d, w, h, h - 28)
    x = 14
    for name in CROWD:
        frame = Image.open(os.path.join(SPRITES, f'{name}.png')).crop(
            (0, 0, 60, 60))
        img.alpha_composite(frame, (x - 6, h - 60 - 4))
        x += 31
    big = img.resize((w * 4, h * 4), Image.NEAREST).convert('RGBA')
    d = ImageDraw.Draw(big)
    _text(d, (512, 26), 'MEMES', 112, (255, 130, 180), stroke=10)
    _text(d, (512, 150), 'the game', 44, (255, 224, 122), stroke=7)
    return big.convert('RGB')


CAPTIONS = {
    '1_home': 'I meme più iconici se le danno!',
    '2_select': '24 lottatori, ognuno con la sua mossa',
    '3_fight': 'Scaraventali fuori dall\'arena!',
    '4_special': 'Mosse speciali assurde',
    '5_arcade': 'Arcade: 8 avversari sempre più forti',
    '6_shop': 'Cappelli e trofei da sbloccare',
}


def framed(shot: Image.Image, caption: str) -> Image.Image:
    """Store screenshot: caption band on top, the game below in a frame."""
    w, h = shot.size
    out = gi._sky(32, 32).resize((w, h), Image.NEAREST).convert('RGB')
    d = ImageDraw.Draw(out)
    band = round(h * 0.17)
    d.rectangle([0, 0, w, band], fill=(255, 130, 180))
    d.rectangle([0, band - max(4, h // 160), w, band], fill=gi.PLUM[:3])
    size = round(band * 0.5)
    _text(d, (w / 2, (band - size) / 2 - size * .12), caption, size,
          (255, 255, 255), stroke=max(3, size // 9))
    margin = round(h * 0.035)
    avail_w, avail_h = w - 2 * margin, h - band - 2 * margin
    k = min(avail_w / w, avail_h / h)
    sw, sh = round(w * k), round(h * k)
    x, y = (w - sw) // 2, band + margin
    border = max(4, h // 150)
    d.rectangle([x - border, y - border, x + sw + border - 1,
                 y + sh + border - 1], fill=gi.PLUM[:3])
    out.paste(shot.convert('RGB').resize((sw, sh), Image.LANCZOS), (x, y))
    return out


def screenshots(raw_dir: str):
    """raw_dir/<device>/<name>.png -> store/screenshots/<device>/<n>.jpg"""
    for device in sorted(os.listdir(raw_dir)):
        src = os.path.join(raw_dir, device)
        dst = os.path.join(ROOT, 'store', 'screenshots', device)
        os.makedirs(dst, exist_ok=True)
        for name, caption in CAPTIONS.items():
            path = os.path.join(src, f'{name}.png')
            if os.path.exists(path):
                framed(Image.open(path), caption).save(
                    os.path.join(dst, f'{name}.jpg'), quality=90)


def main():
    import sys
    out = os.path.join(ROOT, 'store')
    os.makedirs(out, exist_ok=True)
    feature_graphic().save(os.path.join(out, 'feature_graphic_1024x500.png'))
    if len(sys.argv) > 1:
        screenshots(sys.argv[1])
    print('store art written')


if __name__ == '__main__':
    main()

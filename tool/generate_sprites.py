#!/usr/bin/env python3
"""Generates every pixel-art asset of the game.

Characters are built from the *real* meme photos: the background-removed
cutouts in tool/sprite_sources/ (made with `rembg` + the BiRefNet model) are
downscaled, color-quantized and outlined, so they stay faithful to the
original memes; only the little walking legs are added. The cute world
(enemies, 10 themes, items, UI kit) is drawn in tool/pixel_world.py.

Usage:  python3 tool/generate_sprites.py      (needs Pillow + numpy)
Output: assets/images/sprites/*.png and assets/images/ui/*.png
"""
from __future__ import annotations

import os

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

import pixel_world

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'tool', 'sprite_sources')
OUT = os.path.join(ROOT, 'assets', 'images', 'sprites')

OUTLINE = pixel_world.PLUM

# Character frame size and strip layout (must match lib/game/sprites.dart).
FW, FH = 60, 60
FRAMES = ['idle0', 'idle1', 'run0', 'run1', 'run2', 'run3', 'jump', 'fall']


# --------------------------------------------------------------------- utils

def outline(img: Image.Image, color=OUTLINE) -> Image.Image:
    a = np.array(img)
    m = a[:, :, 3] > 0
    p = np.pad(m, 1)
    border = p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]
    border &= ~m
    a[border] = color
    return Image.fromarray(a)


def shade(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c[:3]) + (255,)


# --------------------------------------------------------------- characters

# name: (crop box in the cutout, sprite height, ellipse mask width, tuning)
FIGURES = {
    'wig_dog': ((5, 0, 236, 238), 48, 0.58,
                dict(colors=16, sat=1.2, contrast=1.1, levels=(0, 255))),
    'stare_cat': ((0, 0, 294, 315), 46, 0.58,
                  dict(colors=16, sat=1.35, contrast=1.15, levels=(10, 245))),
    'robber_dog': ((0, 0, 537, 700), 52, 0.75,
                   dict(colors=16, sat=1.1, contrast=1.1, levels=(0, 240))),
    'smile_dog': ((0, 0, 394, 620), 50, 0.58,
                  dict(colors=20, sat=1.3, contrast=1.3, levels=(10, 255),
                       warm=True, gamma=1.6)),
}


def pixel_figure(name: str, height: int | None = None) -> Image.Image:
    """The whole meme (head + chest) from the photo, as pixel art.

    The bottom of the photo crop is rounded off with an ellipse so the figure
    reads as a body instead of a cut-out rectangle.
    """
    box, h, mask_w, t = FIGURES[name]
    h = height or h
    im = Image.open(os.path.join(SRC, f'{name}.png')).convert('RGBA').crop(box)
    width = round(im.width * h / im.height)
    rgb, a = im.convert('RGB'), im.getchannel('A')
    lo, hi = t['levels']
    rgb = rgb.point(lambda v: max(0, min(255, int((v - lo) * 255 / (hi - lo)))))
    g = t.get('gamma', 1.0)
    if g != 1.0:
        rgb = rgb.point(lambda v: int(255 * (v / 255) ** g))
    if t.get('warm'):
        r, gg, b = rgb.split()
        r = r.point(lambda v: min(255, int(v * 1.12)))
        b = b.point(lambda v: int(v * 0.85))
        rgb = Image.merge('RGB', (r, gg, b))
    rgb = ImageEnhance.Color(rgb).enhance(t['sat'])
    rgb = ImageEnhance.Contrast(rgb).enhance(t['contrast'])
    rgb = rgb.filter(ImageFilter.UnsharpMask(2, 80, 2))
    small = rgb.resize((width, h), Image.BOX)
    mask = np.array(a.resize((width, h), Image.BOX)) > 110
    yy, xx = np.mgrid[0:h, 0:width]
    mask &= (((xx - width / 2) / (width * mask_w)) ** 2 +
             ((yy - h * 0.42) / (h * 0.6)) ** 2) <= 1
    q = small.quantize(colors=t['colors'], method=Image.Quantize.MEDIANCUT,
                       dither=Image.Dither.NONE).convert('RGB')
    out = np.zeros((h, width, 4), np.uint8)
    out[:, :, :3] = np.array(q)
    out[:, :, 3] = mask * 255
    return Image.fromarray(out)


def leg_color(fig: Image.Image):
    a = np.array(fig)
    h, w = a.shape[:2]
    rows = a[int(h * 0.8):, int(w * 0.3):int(w * 0.7)]
    px = rows[rows[:, :, 3] > 0][:, :3]
    return tuple(int(v) for v in np.median(px, 0)) + (255,)


LEG_LIFT = {'run0': (0, 2), 'run2': (2, 0), 'jump': (3, 3), 'fall': (-1, -1)}
LEG_SHIFT = {'run0': (-2, 2), 'run2': (2, -2)}


def knife(d: ImageDraw.ImageDraw, x: int, y: int):
    """The robber's knife (too thin to survive the downscale, so redrawn)."""
    d.rectangle([x, y, x + 2, y + 6], fill=(20, 20, 22, 255))
    d.point([(x + 1, y + 2), (x + 1, y + 4)], fill=(150, 150, 150, 255))
    d.polygon([(x, y - 1), (x + 2, y - 1), (x + 4, y - 11), (x, y - 6)],
              fill=(214, 222, 228, 255))
    d.line([(x + 2, y - 2), (x + 3, y - 9)], fill=(255, 255, 255, 255))


def character_strip(name: str) -> Image.Image:
    fig = pixel_figure(name)
    col = leg_color(fig)
    dark = shade(col, 0.75)
    strip = Image.new('RGBA', (FW * len(FRAMES), FH))
    for i, frame in enumerate(FRAMES):
        im = Image.new('RGBA', (FW, FH))
        d = ImageDraw.Draw(im)
        bob = 1 if frame in ('idle1', 'run1', 'run3') else 0
        fx = FW // 2 - fig.width // 2
        fy = FH - 8 - fig.height + 3 + bob - (2 if frame == 'jump' else 0)
        lift = LEG_LIFT.get(frame, (0, 0))
        shift = LEG_SHIFT.get(frame, (0, 0))
        for k, lx in enumerate([FW // 2 - 9, FW // 2 + 4]):
            x = lx + shift[k]
            bottom = FH - 2 - lift[k]
            d.rectangle([x, fy + fig.height - 6, x + 4, bottom], fill=col)
            d.rectangle([x, bottom - 1, x + 4, bottom], fill=dark)
        im.alpha_composite(fig, (fx, fy))
        if name == 'robber_dog':
            knife(ImageDraw.Draw(im), fx + fig.width - 9, fy + fig.height - 12)
        strip.alpha_composite(outline(im), (i * FW, 0))
    return strip


def portrait(name: str) -> Image.Image:
    """Bigger pixel portrait for menus (same technique, more pixels)."""
    return outline(pixel_figure(name, height=FIGURES[name][1] * 2))


def main():
    os.makedirs(OUT, exist_ok=True)
    for name in FIGURES:
        character_strip(name).save(os.path.join(OUT, f'{name}.png'))
        portrait(name).save(os.path.join(OUT, f'{name}_portrait.png'))
    pixel_world.write_all(OUT)
    print('sprites written to', OUT)


if __name__ == '__main__':
    main()

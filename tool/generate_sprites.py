#!/usr/bin/env python3
"""Generates every pixel-art asset of the game.

Characters are built from the *real* meme photos: the background-removed
cutouts in tool/sprite_sources/ (made with `rembg` + the BiRefNet model) are
downscaled, color-quantized and outlined, so they stay faithful to the
original memes; only the little walking legs are added. Enemies, tiles and
items are drawn pixel by pixel here.

Usage:  python3 tool/generate_sprites.py      (needs Pillow + numpy)
Output: assets/images/sprites/*.png
"""
from __future__ import annotations

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'tool', 'sprite_sources')
OUT = os.path.join(ROOT, 'assets', 'images', 'sprites')

OUTLINE = (24, 18, 20, 255)

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


# --------------------------------------------------------------------- enemies

EW, EH = 28, 28
ENEMY_FRAMES = 2


def _emoji_face(d: ImageDraw.ImageDraw, ox, oy, base, rim):
    d.ellipse([ox + 3, oy + 2, ox + 24, oy + 23], fill=base)
    d.arc([ox + 3, oy + 2, ox + 24, oy + 23], 20, 160, fill=rim, width=2)


def enemy_strip(kind: str) -> Image.Image:
    strip = Image.new('RGBA', (EW * ENEMY_FRAMES, EH))
    for f in range(ENEMY_FRAMES):
        img = Image.new('RGBA', (EW, EH))
        d = ImageDraw.Draw(img)
        step = 1 if f else 0
        yb = -step  # bounce
        K = (24, 18, 20, 255)
        W = (255, 255, 255, 255)
        if kind == 'normie':  # 🤓
            d.rectangle([7 + step, 24, 11 + step, 27], fill=(70, 50, 40, 255))
            d.rectangle([16 - step, 24, 20 - step, 27], fill=(70, 50, 40, 255))
            _emoji_face(d, 0, yb, (255, 204, 77, 255), (222, 160, 40, 255))
            for x in (8, 16):
                d.ellipse([x - 1, 8 + yb, x + 5, 14 + yb], fill=W, outline=K)
                d.point((x + 3, 11 + yb), fill=K)
            d.line([(13, 10 + yb), (14, 10 + yb)], fill=K)
            d.arc([9, 12 + yb, 19, 20 + yb], 20, 160, fill=K)
            d.rectangle([12, 18 + yb, 15, 20 + yb], fill=W)
        elif kind == 'cringe':  # 😬
            _emoji_face(d, 0, yb - step, (255, 204, 77, 255),
                        (222, 160, 40, 255))
            for x in (9, 17):
                d.ellipse([x - 2, 7 + yb, x + 2, 12 + yb], fill=W, outline=K)
                d.point((x, 10 + yb), fill=K)
            d.rectangle([8, 15 + yb, 19, 20 + yb], fill=W, outline=K)
            d.line([(8, 17 + yb), (19, 17 + yb)], fill=K)
            for x in (11, 14, 17):
                d.line([(x, 15 + yb), (x, 20 + yb)], fill=K)
            d.ellipse([23, 4 + yb, 26, 8 + yb], fill=(120, 200, 255, 255))
        elif kind == 'hater':  # 😡
            d.rectangle([7 + step, 24, 11 + step, 27], fill=(60, 20, 20, 255))
            d.rectangle([16 - step, 24, 20 - step, 27], fill=(60, 20, 20, 255))
            _emoji_face(d, 0, yb, (232, 72, 60, 255), (180, 40, 36, 255))
            d.line([(6, 7 + yb), (11, 10 + yb)], fill=K, width=2)
            d.line([(21, 7 + yb), (16, 10 + yb)], fill=K, width=2)
            for x in (9, 18):
                d.rectangle([x - 1, 11 + yb, x + 1, 13 + yb], fill=K)
            d.arc([9, 17 + yb, 19, 25 + yb], 200, 340, fill=K, width=2)
            if f:
                d.ellipse([1, 0, 5, 4], fill=(240, 240, 240, 220))
                d.ellipse([22, 0, 26, 4], fill=(240, 240, 240, 220))
        elif kind == 'boomer':  # 👴
            d.rectangle([7 + step, 24, 11 + step, 27], fill=(110, 90, 70, 255))
            d.rectangle([16 - step, 24, 20 - step, 27], fill=(110, 90, 70, 255))
            _emoji_face(d, 0, yb, (240, 196, 150, 255), (200, 150, 110, 255))
            d.ellipse([2, 6 + yb, 7, 14 + yb], fill=(225, 225, 225, 255))
            d.ellipse([20, 6 + yb, 25, 14 + yb], fill=(225, 225, 225, 255))
            for x in (8, 15):
                d.rectangle([x, 9 + yb, x + 4, 12 + yb], fill=(220, 236, 255, 255),
                            outline=K)
                d.point((x + 2, 11 + yb), fill=K)
            d.polygon([(8, 18 + yb), (13, 16 + yb), (19, 18 + yb), (17, 19 + yb),
                       (13, 18 + yb), (10, 19 + yb)], fill=(245, 245, 245, 255),
                      outline=(180, 180, 180, 255))
            d.line([(11, 21 + yb), (16, 21 + yb)], fill=K)
        img = outline(img)
        strip.alpha_composite(img, (f * EW, 0))
    return strip


def boss_strip() -> Image.Image:
    """L'Algoritmo: a big green robot with a screen face."""
    BW, BH = 56, 56
    strip = Image.new('RGBA', (BW * 2, BH))
    for f in range(2):
        img = Image.new('RGBA', (BW, BH))
        d = ImageDraw.Draw(img)
        s = 2 if f else 0
        d.rectangle([12 + s, 48, 22 + s, 55], fill=(40, 52, 46, 255))
        d.rectangle([34 - s, 48, 44 - s, 55], fill=(40, 52, 46, 255))
        d.line([(28, 8), (28, 2)], fill=(40, 52, 46, 255), width=2)
        d.ellipse([25, 0, 31, 5], fill=(255, 64, 64, 255) if f else
                  (255, 224, 64, 255))
        d.rounded_rectangle([4, 7, 52, 50], 8, fill=(46, 204, 113, 255))
        d.rounded_rectangle([9, 12, 47, 36], 4, fill=(16, 38, 26, 255))
        g = (124, 255, 158, 255)
        d.rectangle([15, 19, 21, 23], fill=g)
        d.rectangle([35, 19, 41, 23], fill=g)
        d.line([(13, 15), (21, 18)], fill=g, width=2)
        d.line([(43, 15), (35, 18)], fill=g, width=2)
        for i in range(6):
            y = 29 if (i + f) % 2 else 27
            d.rectangle([14 + i * 5, y, 17 + i * 5, y + 2], fill=g)
        d.line([(14, 45), (22, 40), (28, 42), (40, 36)], fill=(16, 38, 26, 255),
               width=2)
        d.polygon([(40, 36), (36, 36), (40, 40)], fill=(16, 38, 26, 255))
        strip.alpha_composite(outline(img), (f * BW, 0))
    return strip


# --------------------------------------------------------------------- tiles

T = 24
THEMES = {
    # level theme: grass top, dirt, dirt dark, brick, brick dark
    'feed': ((88, 196, 72), (150, 96, 56), (118, 72, 40), (206, 92, 52),
             (150, 60, 34)),
    'comments': ((170, 110, 230), (92, 70, 120), (68, 50, 92), (120, 120, 150),
                 (84, 84, 110)),
    'server': ((60, 230, 160), (48, 56, 72), (32, 38, 52), (70, 80, 100),
               (44, 52, 68)),
}
TILE_NAMES = ['ground_top', 'ground', 'brick', 'platform', 'spikes',
              'block', 'block_used', 'gate']


def tileset(theme: str) -> Image.Image:
    grass, dirt, dirt_dk, brick, brick_dk = THEMES[theme]
    img = Image.new('RGBA', (T * len(TILE_NAMES), T))
    rnd = np.random.default_rng(7)
    for i, name in enumerate(TILE_NAMES):
        t = Image.new('RGBA', (T, T))
        d = ImageDraw.Draw(t)
        if name in ('ground_top', 'ground'):
            d.rectangle([0, 0, T - 1, T - 1], fill=dirt + (255,))
            for _ in range(10):
                x, y = rnd.integers(0, T - 2, 2)
                d.rectangle([x, y, x + 1, y + 1], fill=dirt_dk + (255,))
            if name == 'ground_top':
                d.rectangle([0, 0, T - 1, 6], fill=grass + (255,))
                for x in range(0, T, 3):
                    d.rectangle([x, 6, x + 1, 7 + (x // 3) % 2 * 2],
                                fill=grass + (255,))
                d.line([(0, 0), (T - 1, 0)], fill=shade(grass, 1.25))
        elif name == 'brick':
            d.rectangle([0, 0, T - 1, T - 1], fill=brick_dk + (255,))
            for row in range(3):
                off = 0 if row % 2 == 0 else 6
                for col in range(-1, 3):
                    x = col * 12 + off
                    d.rectangle([x + 1, row * 8 + 1, x + 10, row * 8 + 6],
                                fill=brick + (255,))
                    d.line([(x + 1, row * 8 + 1), (x + 10, row * 8 + 1)],
                           fill=shade(brick, 1.2))
        elif name == 'platform':
            d.rectangle([0, 0, T - 1, 9], fill=(170, 116, 64, 255))
            d.line([(0, 0), (T - 1, 0)], fill=(214, 158, 96, 255), width=2)
            d.line([(0, 9), (T - 1, 9)], fill=(110, 70, 36, 255), width=2)
            for x in (4, 18):
                d.point([(x, 4), (x + 1, 4)], fill=(90, 56, 28, 255))
        elif name == 'spikes':
            for k in range(4):
                x = k * 6
                d.polygon([(x, T - 1), (x + 3, T - 12), (x + 5, T - 1)],
                          fill=(196, 204, 214, 255), outline=(90, 96, 110, 255))
        elif name in ('block', 'block_used'):
            used = name == 'block_used'
            base = (150, 120, 90) if used else (255, 196, 40)
            d.rectangle([0, 0, T - 1, T - 1], fill=base + (255,),
                        outline=OUTLINE)
            d.line([(1, 1), (T - 2, 1)], fill=shade(base, 1.2), width=2)
            for x, y in [(3, 3), (T - 5, 3), (3, T - 5), (T - 5, T - 5)]:
                d.point([(x, y), (x + 1, y), (x, y + 1), (x + 1, y + 1)],
                        fill=shade(base, .6))
            if not used:
                # A "like" heart on the block.
                h = (230, 50, 90, 255)
                d.ellipse([6, 7, 12, 13], fill=h)
                d.ellipse([11, 7, 17, 13], fill=h)
                d.polygon([(6, 11), (17, 11), (11, 18)], fill=h)
                d.point([(8, 9), (9, 9)], fill=(255, 220, 230, 255))
        elif name == 'gate':
            d.rectangle([0, 0, T - 1, T - 1], fill=(60, 20, 40, 255))
            for x in (3, 11, 19):
                d.rectangle([x, 0, x + 2, T - 1], fill=(255, 64, 120, 255))
        img.alpha_composite(t, (i * T, 0))
    return img


def items() -> dict[str, Image.Image]:
    res = {}
    # Like (collectible heart), 4-frame spin.
    like = Image.new('RGBA', (16 * 4, 16))
    for f, w in enumerate([12, 8, 3, 8]):
        im = Image.new('RGBA', (16, 16))
        d = ImageDraw.Draw(im)
        cx = 8
        h = (240, 60, 100, 255)
        if w >= 8:
            r = w // 4
            d.ellipse([cx - w // 2, 3, cx, 3 + r * 2 + 1], fill=h)
            d.ellipse([cx, 3, cx + w // 2, 3 + r * 2 + 1], fill=h)
            d.polygon([(cx - w // 2, 3 + r + 1), (cx + w // 2, 3 + r + 1),
                       (cx, 13)], fill=h)
            d.point([(cx - w // 4, 5)], fill=(255, 220, 230, 255))
        else:
            d.rectangle([cx - 1, 3, cx + 1, 13], fill=shade(h, .8))
        like.alpha_composite(outline(im), (f * 16, 0))
    res['like'] = like
    # Finish trophy ("VIRALE") and checkpoint flag.
    flag = Image.new('RGBA', (24 * 2, 72))
    for f in range(2):
        im = Image.new('RGBA', (24, 72))
        d = ImageDraw.Draw(im)
        d.rectangle([2, 4, 4, 71], fill=(220, 220, 230, 255))
        wave = f * 2
        d.polygon([(5, 6), (22, 10 + wave), (5, 18)], fill=(255, 64, 140, 255))
        d.ellipse([1, 1, 5, 5], fill=(255, 210, 60, 255))
        flag.alpha_composite(outline(im), (f * 24, 0))
    res['flag'] = flag
    cp = Image.new('RGBA', (24 * 2, 40))
    for f in range(2):
        im = Image.new('RGBA', (24, 40))
        d = ImageDraw.Draw(im)
        d.rectangle([2, 4, 3, 39], fill=(200, 200, 210, 255))
        col = (90, 220, 120, 255) if f else (150, 150, 160, 255)
        d.polygon([(4, 5), (18, 9), (4, 14)], fill=col)
        cp.alpha_composite(outline(im), (f * 24, 0))
    res['checkpoint'] = cp
    # "RATIO" projectile thrown by haters.
    ratio = Image.new('RGBA', (22, 12))
    d = ImageDraw.Draw(ratio)
    d.rounded_rectangle([0, 0, 21, 9], 3, fill=(255, 255, 255, 255),
                        outline=OUTLINE)
    d.polygon([(4, 9), (8, 9), (4, 11)], fill=(255, 255, 255, 255))
    # Tiny "-1".
    d.line([(6, 5), (9, 5)], fill=(220, 40, 40, 255))
    d.line([(12, 2), (12, 7)], fill=(220, 40, 40, 255))
    d.line([(11, 3), (12, 2)], fill=(220, 40, 40, 255))
    res['ratio'] = ratio
    return res


def backgrounds() -> dict[str, Image.Image]:
    """Two parallax layers per theme (sky gradient is drawn in code)."""
    res = {}
    for theme, (grass, dirt, *_ ) in THEMES.items():
        W, H = 480, 160
        far = Image.new('RGBA', (W, H))
        d = ImageDraw.Draw(far)
        hill = shade(grass, .55) if theme != 'server' else (30, 50, 70, 255)
        for k in range(5):
            cx = k * 110 + 30
            d.ellipse([cx - 80, 60 + (k % 2) * 20, cx + 80, 260], fill=hill)
        if theme == 'server':
            for k in range(8):
                x = k * 60 + 10
                h = 40 + (k * 37) % 70
                d.rectangle([x, H - h, x + 36, H], fill=(24, 34, 50, 255))
                for y in range(H - h + 6, H, 8):
                    d.point([(x + 6, y), (x + 12, y)],
                            fill=(60, 230, 160, 255))
        res[f'bg_{theme}_far'] = far
        clouds = Image.new('RGBA', (W, 100))
        d = ImageDraw.Draw(clouds)
        cc = (255, 255, 255, 230) if theme == 'feed' else (
            (210, 190, 255, 200) if theme == 'comments' else (80, 110, 140, 200))
        for x, y in [(30, 20), (180, 50), (320, 15), (420, 60)]:
            d.ellipse([x, y, x + 50, y + 20], fill=cc)
            d.ellipse([x + 15, y - 10, x + 45, y + 15], fill=cc)
        res[f'bg_{theme}_clouds'] = clouds
    return res


def main():
    os.makedirs(OUT, exist_ok=True)
    for name in FIGURES:
        character_strip(name).save(os.path.join(OUT, f'{name}.png'))
        portrait(name).save(os.path.join(OUT, f'{name}_portrait.png'))
    for kind in ['normie', 'cringe', 'hater', 'boomer']:
        enemy_strip(kind).save(os.path.join(OUT, f'enemy_{kind}.png'))
    boss_strip().save(os.path.join(OUT, 'enemy_algorithm.png'))
    for theme in THEMES:
        tileset(theme).save(os.path.join(OUT, f'tiles_{theme}.png'))
    for k, im in {**items(), **backgrounds()}.items():
        im.save(os.path.join(OUT, f'{k}.png'))
    print('sprites written to', OUT)


if __name__ == '__main__':
    main()

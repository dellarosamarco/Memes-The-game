"""Cute pixel-art world assets: enemies, 10 world themes (tiles + parallax
backgrounds), items and the UI kit (icons, panels, buttons).

Everything is drawn at 1x with aliased primitives or ASCII pixel maps, in a
soft pastel palette with a plum outline.
"""
from __future__ import annotations

import os

import numpy as np
from PIL import Image, ImageDraw

PLUM = (58, 36, 64, 255)
WHITE = (255, 255, 255, 255)
BLUSH = (255, 150, 176, 255)
SHINE = (255, 255, 255, 200)
T = 24


def rgba(c, a=255):
    return tuple(c[:3]) + (a,)


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3)) + (255,)


def lighten(c, t=.3):
    return mix(c, (255, 255, 255), t)


def darken(c, t=.25):
    return mix(c, (40, 20, 50), t)


def outline(img: Image.Image, color=PLUM) -> Image.Image:
    a = np.array(img)
    m = a[:, :, 3] > 0
    p = np.pad(m, 1)
    border = p[:-2, 1:-1] | p[2:, 1:-1] | p[1:-1, :-2] | p[1:-1, 2:]
    border &= ~m
    a[border] = color
    return Image.fromarray(a)


def pixmap(rows: list[str], palette: dict[str, tuple]) -> Image.Image:
    """Builds an image from ASCII art ('.' = transparent)."""
    h, w = len(rows), max(len(r) for r in rows)
    img = Image.new('RGBA', (w, h))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in palette:
                img.putpixel((x, y), palette[ch])
    return img


# =================================================================== enemies

EW = 28


def _blob(d, box, base, shade_col):
    x0, y0, x1, y1 = box
    d.ellipse(box, fill=base)
    # Soft bottom shading + top shine.
    d.chord([x0 + 1, y0 + (y1 - y0) // 2, x1 - 1, y1], 20, 160, fill=shade_col)
    d.ellipse([x0 + 4, y0 + 3, x0 + 8, y0 + 6], fill=lighten(base, .55))


def _feet(d, f, col, y=24):
    s = 1 if f else 0
    d.ellipse([7 + s, y, 12 + s, y + 3], fill=col)
    d.ellipse([16 - s, y, 21 - s, y + 3], fill=col)


def _eye(d, x, y, look=1, big=True):
    if big:
        d.rectangle([x, y, x + 2, y + 3], fill=PLUM)
        d.point((x + (1 if look > 0 else 0), y), fill=WHITE)
    else:
        d.rectangle([x, y, x + 1, y + 1], fill=PLUM)


def _blush(d, y=17):
    d.rectangle([5, y, 7, y + 1], fill=BLUSH)
    d.rectangle([20, y, 22, y + 1], fill=BLUSH)


def enemy_strip(kind: str) -> Image.Image:
    strip = Image.new('RGBA', (EW * 2, EW))
    for f in range(2):
        img = Image.new('RGBA', (EW, EW))
        d = ImageDraw.Draw(img)
        up = -1 if f else 0
        if kind == 'normie':
            _feet(d, f, (150, 110, 90, 255))
            _blob(d, [3, 4 + up, 24, 25 + up], (255, 222, 120, 255),
                  (246, 196, 92, 255))
            # Hair tuft.
            d.polygon([(11, 4 + up), (14, 1 + up), (17, 4 + up)],
                      fill=(150, 100, 70, 255))
            # Big round glasses.
            for x in (6, 15):
                d.ellipse([x, 9 + up, x + 7, 16 + up], fill=WHITE, outline=PLUM)
                d.rectangle([x + 3, 11 + up, x + 4, 13 + up], fill=PLUM)
                d.point((x + 3, 11 + up), fill=WHITE)
            d.line([(13, 12 + up), (14, 12 + up)], fill=PLUM)
            _blush(d, 17 + up)
            d.arc([10, 15 + up, 18, 21 + up], 20, 160, fill=PLUM)
            d.rectangle([13, 20 + up, 15, 21 + up], fill=WHITE)
        elif kind == 'cringe':
            jump = -2 if f else 0
            _blob(d, [3, 5 + jump, 24, 26 + jump], (255, 236, 150, 255),
                  (246, 210, 110, 255))
            d.ellipse([7, 24, 11, 27], fill=(200, 160, 90, 255))
            d.ellipse([16, 24, 20, 27], fill=(200, 160, 90, 255))
            for x in (8, 17):
                d.ellipse([x - 1, 10 + jump, x + 3, 14 + jump], fill=WHITE,
                          outline=PLUM)
                d.point((x + 1, 12 + jump), fill=PLUM)
            d.line([(6, 8 + jump), (10, 9 + jump)], fill=PLUM)
            d.line([(21, 8 + jump), (17, 9 + jump)], fill=PLUM)
            # Clenched teeth.
            d.rounded_rectangle([8, 17 + jump, 19, 21 + jump], 1, fill=WHITE,
                                outline=PLUM)
            d.line([(9, 19 + jump), (18, 19 + jump)], fill=(200, 190, 200, 255))
            for x in (11, 14, 17):
                d.line([(x, 18 + jump), (x, 20 + jump)],
                       fill=(200, 190, 200, 255))
            _blush(d, 16 + jump)
            d.polygon([(23, 6 + jump), (25, 10 + jump), (21, 10 + jump)],
                      fill=(140, 210, 255, 255))
        elif kind == 'hater':
            _feet(d, f, (170, 70, 90, 255))
            _blob(d, [3, 4 + up, 24, 25 + up], (255, 128, 140, 255),
                  (236, 92, 112, 255))
            d.line([(6, 9 + up), (11, 11 + up)], fill=PLUM, width=2)
            d.line([(21, 9 + up), (16, 11 + up)], fill=PLUM, width=2)
            _eye(d, 8, 12 + up)
            _eye(d, 17, 12 + up)
            d.ellipse([4, 15 + up, 8, 18 + up], fill=(255, 90, 110, 255))
            d.ellipse([19, 15 + up, 23, 18 + up], fill=(255, 90, 110, 255))
            d.arc([10, 18 + up, 18, 24 + up], 200, 340, fill=PLUM, width=1)
            if f:
                for x in (1, 22):
                    d.ellipse([x, 0, x + 4, 4], fill=(255, 255, 255, 220))
        elif kind == 'boomer':
            _feet(d, f, (140, 110, 90, 255))
            _blob(d, [3, 4 + up, 24, 25 + up], (250, 214, 182, 255),
                  (236, 188, 154, 255))
            d.chord([3, 14 + up, 24, 25 + up], 0, 180,
                    fill=(196, 160, 120, 255))
            for x in (2, 20):
                d.ellipse([x, 8 + up, x + 5, 15 + up], fill=(246, 246, 250, 255))
            for x in (7, 15):
                d.rounded_rectangle([x, 9 + up, x + 5, 13 + up], 1,
                                    fill=(224, 240, 255, 255), outline=PLUM)
                d.point((x + 3, 11 + up), fill=PLUM)
            d.line([(12, 11 + up), (14, 11 + up)], fill=PLUM)
            d.polygon([(8, 16 + up), (13, 14 + up), (19, 16 + up), (17, 17 + up),
                       (13, 16 + up), (10, 17 + up)], fill=WHITE)
            d.rectangle([5, 14 + up, 6, 15 + up], fill=BLUSH)
            d.rectangle([21, 14 + up, 22, 15 + up], fill=BLUSH)
        strip.alpha_composite(outline(img), (f * EW, 0))
    return strip


def boss_strip() -> Image.Image:
    """L'Algoritmo: a cute-but-evil mint robot with a screen face."""
    BW = 56
    strip = Image.new('RGBA', (BW * 2, BW))
    mint = (120, 230, 180, 255)
    for f in range(2):
        img = Image.new('RGBA', (BW, BW))
        d = ImageDraw.Draw(img)
        s = 2 if f else 0
        d.rounded_rectangle([12 + s, 47, 22 + s, 54], 3, fill=(90, 160, 130, 255))
        d.rounded_rectangle([34 - s, 47, 44 - s, 54], 3, fill=(90, 160, 130, 255))
        # Arms.
        d.rounded_rectangle([0, 26 - s, 6, 36 - s], 3, fill=mint)
        d.rounded_rectangle([50, 26 + s, 56, 36 + s], 3, fill=mint)
        # Antenna with a heart.
        d.line([(28, 9), (28, 4)], fill=PLUM, width=2)
        heart = (255, 90, 130, 255) if f else (255, 150, 180, 255)
        d.ellipse([23, 0, 28, 5], fill=heart)
        d.ellipse([28, 0, 33, 5], fill=heart)
        d.polygon([(23, 3), (33, 3), (28, 8)], fill=heart)
        d.rounded_rectangle([5, 8, 51, 49], 10, fill=mint)
        d.rounded_rectangle([9, 12, 23, 18], 3, fill=lighten(mint, .5))
        d.rounded_rectangle([10, 14, 46, 37], 6, fill=(40, 52, 78, 255))
        g = (130, 255, 200, 255)
        # >< angry eyes.
        for (x0, x1) in ((16, 22), (40, 34)):
            d.line([(x0, 19), (x1, 23)], fill=g, width=2)
            d.line([(x1, 23), (x0, 27)], fill=g, width=2)
        for i in range(5):
            y = 31 if (i + f) % 2 else 29
            d.rectangle([18 + i * 4, y, 20 + i * 4, y + 1], fill=g)
        d.rectangle([9, 40, 13, 42], fill=BLUSH)
        d.rectangle([43, 40, 47, 42], fill=BLUSH)
        strip.alpha_composite(outline(img), (f * BW, 0))
    return strip


# =================================================================== themes

THEMES = {
    # id: top, dirt, brick, platform, sky top/bottom, hills, clouds, deco
    'feed': dict(top=(126, 214, 110), dirt=(196, 140, 98), brick=(240, 150, 120),
                 plat=(214, 160, 110), sky=((140, 210, 255), (214, 242, 255)),
                 hill=(150, 220, 140), cloud=(255, 255, 255), deco='flowers'),
    'comments': dict(top=(200, 150, 240), dirt=(130, 100, 170),
                     brick=(170, 150, 220), plat=(230, 180, 240),
                     sky=((90, 70, 150), (200, 160, 230)),
                     hill=(150, 110, 200), cloud=(240, 220, 255),
                     deco='bubbles'),
    'beach': dict(top=(252, 228, 160), dirt=(240, 200, 130),
                  brick=(255, 190, 150), plat=(200, 150, 100),
                  sky=((110, 200, 250), (200, 245, 255)),
                  hill=(90, 200, 220), cloud=(255, 255, 255), deco='shells'),
    'desert': dict(top=(250, 200, 120), dirt=(226, 160, 96),
                   brick=(214, 130, 90), plat=(190, 130, 80),
                   sky=((255, 190, 140), (255, 236, 190)),
                   hill=(240, 180, 110), cloud=(255, 240, 220), deco='cacti'),
    'ice': dict(top=(240, 250, 255), dirt=(160, 210, 240), brick=(190, 230, 250),
                plat=(210, 240, 255), sky=((170, 210, 250), (235, 248, 255)),
                hill=(200, 230, 250), cloud=(255, 255, 255), deco='snow'),
    'candy': dict(top=(255, 180, 220), dirt=(190, 130, 100),
                  brick=(255, 150, 190), plat=(255, 220, 240),
                  sky=((255, 200, 230), (255, 240, 250)),
                  hill=(255, 170, 210), cloud=(255, 255, 255), deco='sprinkles'),
    'forest': dict(top=(90, 180, 110), dirt=(130, 96, 80), brick=(150, 120, 100),
                   plat=(170, 120, 80), sky=((100, 170, 150), (190, 230, 200)),
                   hill=(70, 140, 100), cloud=(230, 255, 240), deco='mushrooms'),
    'volcano': dict(top=(255, 140, 90), dirt=(110, 70, 80), brick=(140, 90, 100),
                    plat=(150, 100, 90), sky=((90, 40, 70), (220, 110, 100)),
                    hill=(120, 60, 80), cloud=(255, 170, 140), deco='embers'),
    'clouds': dict(top=(255, 255, 255), dirt=(220, 230, 255),
                   brick=(255, 240, 200), plat=(255, 255, 255),
                   sky=((150, 180, 255), (255, 230, 250)),
                   hill=(230, 235, 255), cloud=(255, 255, 255), deco='stars'),
    'server': dict(top=(110, 250, 190), dirt=(60, 70, 110), brick=(80, 100, 150),
                   plat=(110, 130, 180), sky=((20, 24, 50), (60, 60, 120)),
                   hill=(40, 50, 90), cloud=(90, 100, 160), deco='leds'),
}

TILE_NAMES = ['ground_top', 'ground', 'brick', 'platform', 'spikes', 'block',
              'block_used', 'gate', 'spring', 'spring_up']


def _deco(d, theme, rnd, x, y):
    k = THEMES[theme]['deco']
    if k == 'flowers':
        c = [(255, 140, 180), (255, 230, 110), (255, 255, 255)][rnd.integers(3)]
        d.point([(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)], fill=rgba(c))
        d.point((x, y), fill=(255, 210, 90, 255))
    elif k == 'bubbles':
        d.ellipse([x - 1, y - 1, x + 1, y + 1], outline=(255, 255, 255, 200))
    elif k == 'shells':
        d.point([(x, y), (x + 1, y), (x, y - 1)], fill=(255, 170, 170, 255))
    elif k == 'cacti':
        d.line([(x, y), (x, y - 2)], fill=(110, 180, 100, 255))
    elif k == 'snow':
        d.point((x, y), fill=(200, 230, 255, 255))
    elif k == 'sprinkles':
        c = [(120, 200, 255), (255, 240, 120), (160, 255, 170)][rnd.integers(3)]
        d.line([(x, y), (x + 1, y)], fill=rgba(c))
    elif k == 'mushrooms':
        d.point([(x - 1, y - 1), (x, y - 1), (x + 1, y - 1)],
                fill=(255, 90, 100, 255))
        d.point((x, y), fill=WHITE)
    elif k == 'embers':
        d.point((x, y), fill=(255, 220, 120, 255))
    elif k == 'stars':
        d.point([(x, y), (x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)],
                fill=(255, 240, 160, 255))
    elif k == 'leds':
        d.point((x, y), fill=(130, 255, 200, 255))


def tileset(theme: str) -> Image.Image:
    th = THEMES[theme]
    top, dirt, brick, plat = (rgba(th[k]) for k in ('top', 'dirt', 'brick',
                                                     'plat'))
    img = Image.new('RGBA', (T * len(TILE_NAMES), T))
    rnd = np.random.default_rng(sum(map(ord, theme)))
    for i, name in enumerate(TILE_NAMES):
        t = Image.new('RGBA', (T, T))
        d = ImageDraw.Draw(t)
        if name in ('ground_top', 'ground'):
            d.rectangle([0, 0, T - 1, T - 1], fill=dirt)
            # Soft strata lines (tile seamlessly) and little pebbles.
            for y0 in (9, 18):
                for x in range(0, T, 2):
                    yy = y0 + (1 if (x // 4) % 2 else 0)
                    d.point((x, yy), fill=darken(dirt, .1))
            for _ in range(3):
                x, y = rnd.integers(2, T - 5, 2)
                d.ellipse([x, y, x + 3, y + 2], fill=lighten(dirt, .18),
                          outline=darken(dirt, .22))
                d.point((x + 1, y), fill=lighten(dirt, .4))
            if name == 'ground_top':
                d.rectangle([0, 0, T - 1, 5], fill=top)
                for x in range(0, T, 6):  # scalloped edge
                    d.ellipse([x - 1, 3, x + 5, 9], fill=top)
                d.line([(0, 1), (T - 1, 1)], fill=lighten(top, .45))
                d.line([(0, 0), (T - 1, 0)], fill=PLUM)
                for _ in range(2):
                    x = int(rnd.integers(3, T - 3))
                    _deco(d, theme, rnd, x, 3)
        elif name == 'brick':
            d.rectangle([0, 0, T - 1, T - 1], fill=darken(brick, .22))
            for row in range(2):
                off = 0 if row == 0 else 6
                for col in range(-1, 3):
                    x = col * 12 + off
                    d.rounded_rectangle([x + 1, row * 12 + 1, x + 11,
                                         row * 12 + 11], 3, fill=brick)
                    d.line([(x + 3, row * 12 + 2), (x + 8, row * 12 + 2)],
                           fill=lighten(brick, .35))
        elif name == 'platform':
            d.rounded_rectangle([0, 0, T - 1, 10], 4, fill=plat)
            d.line([(2, 1), (T - 3, 1)], fill=lighten(plat, .4))
            d.line([(2, 9), (T - 3, 9)], fill=darken(plat, .2))
            d.point([(6, 5), (17, 5)], fill=darken(plat, .3))
        elif name == 'spikes':
            for k in range(3):
                x = k * 8
                d.polygon([(x, T - 1), (x + 4, T - 12), (x + 7, T - 1)],
                          fill=(232, 236, 250, 255), outline=(150, 140, 190, 255))
                d.line([(x + 3, T - 8), (x + 3, T - 4)], fill=WHITE)
        elif name in ('block', 'block_used'):
            used = name == 'block_used'
            base = (210, 190, 200) if used else (255, 214, 90)
            d.rounded_rectangle([0, 0, T - 1, T - 1], 4, fill=rgba(base),
                                outline=PLUM)
            d.line([(3, 2), (T - 4, 2)], fill=lighten(base, .45), width=2)
            d.line([(3, T - 3), (T - 4, T - 3)], fill=darken(base, .2))
            if not used:
                h = (255, 90, 130, 255)
                d.ellipse([6, 7, 12, 13], fill=h)
                d.ellipse([11, 7, 17, 13], fill=h)
                d.polygon([(6, 11), (17, 11), (11, 18)], fill=h)
                d.point([(8, 9), (9, 9)], fill=WHITE)
            else:
                for x, y in [(5, 5), (T - 7, 5), (5, T - 7), (T - 7, T - 7)]:
                    d.rectangle([x, y, x + 1, y + 1], fill=darken(base, .3))
        elif name == 'gate':
            d.rectangle([0, 0, T - 1, T - 1], fill=(120, 60, 110, 255))
            for x in (3, 11, 19):
                d.rounded_rectangle([x, 0, x + 3, T - 1], 1,
                                    fill=(255, 130, 190, 255))
            d.ellipse([9, 9, 14, 14], fill=(255, 220, 120, 255))
        elif name in ('spring', 'spring_up'):
            up = name == 'spring_up'
            coil_top = 8 if up else 14
            for y in range(coil_top, T - 3, 3):
                d.line([(7, y), (16, y + 1)], fill=(170, 170, 200, 255), width=2)
            d.rounded_rectangle([3, T - 4, 20, T - 1], 1,
                                fill=(140, 130, 170, 255))
            d.rounded_rectangle([2, coil_top - 4, 21, coil_top], 2,
                                fill=(255, 110, 140, 255))
            d.line([(4, coil_top - 3), (19, coil_top - 3)],
                   fill=(255, 190, 210, 255))
        img.alpha_composite(outline(t) if name in ('spikes', 'spring',
                                                    'spring_up', 'platform')
                            else t, (i * T, 0))
    # Auto-tile edges, variants and liquids (see pixel_details.py).
    import pixel_details
    extras = pixel_details.extra_tiles(theme, img.crop((0, 0, T, T)),
                                       img.crop((T, 0, 2 * T, T)))
    full = Image.new('RGBA', (T * (len(TILE_NAMES) + len(extras)), T))
    full.alpha_composite(img, (0, 0))
    for j, t in enumerate(extras):
        full.alpha_composite(t, ((len(TILE_NAMES) + j) * T, 0))
    return full


def moving_platform(theme: str) -> Image.Image:
    plat = rgba(THEMES[theme]['plat'])
    img = Image.new('RGBA', (T * 3, 12))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, T * 3 - 1, 10], 5, fill=plat)
    d.line([(3, 1), (T * 3 - 4, 1)], fill=lighten(plat, .45))
    d.line([(3, 9), (T * 3 - 4, 9)], fill=darken(plat, .2))
    for x in (8, 36, 64):
        d.rectangle([x - 1, 4, x, 5], fill=darken(plat, .35))
    return outline(img)


def _cloud(d, x, y, w, col, face=False):
    d.ellipse([x, y + 6, x + w, y + 18], fill=col)
    d.ellipse([x + w // 5, y, x + w // 5 + w // 2, y + 14], fill=col)
    d.ellipse([x + w // 2, y + 3, x + w // 2 + w // 3, y + 15], fill=col)
    if face:
        cx = x + w // 2
        d.point([(cx - 4, y + 10), (cx + 4, y + 10)], fill=PLUM)
        d.arc([cx - 2, y + 10, cx + 2, y + 13], 20, 160, fill=PLUM)
        d.point([(cx - 7, y + 12), (cx + 7, y + 12)], fill=BLUSH)


def backgrounds(theme: str) -> dict[str, Image.Image]:
    th = THEMES[theme]
    W, H = 480, 160
    far = Image.new('RGBA', (W, H))
    d = ImageDraw.Draw(far)
    hill = rgba(th['hill'])
    k = th['deco']
    if k in ('flowers', 'bubbles', 'snow', 'sprinkles', 'mushrooms', 'stars',
             'shells', 'cacti', 'embers'):
        for i in range(5):
            cx = i * 110 + 30
            top = 70 + (i % 2) * 22
            col = hill if i % 2 else lighten(hill, .15)
            if k == 'embers':  # volcano peaks
                d.polygon([(cx - 90, H), (cx, top - 20), (cx + 90, H)], fill=col)
                d.polygon([(cx - 12, top - 8), (cx, top - 20), (cx + 12, top - 8)],
                          fill=(255, 150, 90, 255))
                continue
            d.ellipse([cx - 80, top, cx + 80, top + 200], fill=col)
            # Sleepy cute faces on some hills.
            if i % 2 == 0:
                d.arc([cx - 14, top + 22, cx - 8, top + 26], 0, 180, fill=PLUM)
                d.arc([cx + 8, top + 22, cx + 14, top + 26], 0, 180, fill=PLUM)
                d.rectangle([cx - 20, top + 28, cx - 16, top + 29], fill=BLUSH)
                d.rectangle([cx + 16, top + 28, cx + 20, top + 29], fill=BLUSH)
            if k == 'cacti' and i % 2:
                d.rounded_rectangle([cx - 3, top - 22, cx + 3, top + 4], 3,
                                    fill=(110, 190, 110, 255))
                d.rounded_rectangle([cx - 10, top - 14, cx - 6, top - 4], 2,
                                    fill=(110, 190, 110, 255))
            if k == 'mushrooms' and i % 2:
                d.rectangle([cx - 3, top - 12, cx + 3, top + 2],
                            fill=(255, 240, 220, 255))
                d.ellipse([cx - 14, top - 22, cx + 14, top - 6],
                          fill=(255, 100, 110, 255))
                d.point([(cx - 6, top - 16), (cx + 5, top - 14)], fill=WHITE)
            if k == 'sprinkles' and i % 2:
                d.line([(cx, top), (cx, top - 26)], fill=WHITE, width=2)
                d.ellipse([cx - 10, top - 44, cx + 10, top - 24],
                          fill=(255, 140, 200, 255))
                d.arc([cx - 6, top - 40, cx + 6, top - 28], 0, 300, fill=WHITE)
        if k == 'shells':  # sea strip
            d.rectangle([0, H - 40, W, H], fill=(110, 210, 230, 255))
            for x in range(0, W, 16):
                d.arc([x, H - 44, x + 16, H - 36], 200, 340, fill=WHITE)
    else:  # server city
        for i in range(10):
            x = i * 48 + 4
            h = 50 + (i * 37) % 80
            d.rounded_rectangle([x, H - h, x + 38, H], 3, fill=hill)
            for y in range(H - h + 8, H - 4, 10):
                for xx in (x + 8, x + 18, x + 28):
                    d.rectangle([xx, y, xx + 3, y + 3],
                                fill=(130, 255, 200, 255) if (xx + y) % 3
                                else (255, 150, 200, 255))
    clouds = Image.new('RGBA', (W, 100))
    d = ImageDraw.Draw(clouds)
    cc = rgba(th['cloud'], 235)
    for j, (x, y, w) in enumerate([(20, 20, 60), (170, 50, 46), (300, 12, 70),
                                   (410, 60, 40)]):
        _cloud(d, x, y, w, cc, face=j % 2 == 0)
    return {f'bg_{theme}_far': far, f'bg_{theme}_clouds': clouds}


# =================================================================== items

def items() -> dict[str, Image.Image]:
    res = {}
    # Like (heart) with a 4-frame shine/bounce.
    like = Image.new('RGBA', (16 * 4, 16))
    for f in range(4):
        im = Image.new('RGBA', (16, 16))
        d = ImageDraw.Draw(im)
        squash = [0, 1, 0, -1][f]
        h = (255, 96, 140, 255)
        d.ellipse([2, 3 + squash, 8, 9], fill=h)
        d.ellipse([7, 3 + squash, 13, 9], fill=h)
        d.polygon([(2, 7), (13, 7), (7, 13)], fill=h)
        d.rectangle([4, 5 + squash, 5, 6 + squash], fill=WHITE)
        if f == 1:
            d.point([(14, 1), (15, 2), (13, 2), (14, 3)],
                    fill=(255, 240, 160, 255))
        like.alpha_composite(outline(im), (f * 16, 0))
    res['like'] = like
    # Finish flag with a heart.
    flag = Image.new('RGBA', (24 * 2, 72))
    for f in range(2):
        im = Image.new('RGBA', (24, 72))
        d = ImageDraw.Draw(im)
        d.rectangle([2, 4, 4, 71], fill=(240, 236, 250, 255))
        w = f * 2
        d.polygon([(5, 6), (22, 11 + w), (5, 20)], fill=(255, 130, 180, 255))
        d.ellipse([9, 9 + w // 2, 12, 12 + w // 2], fill=WHITE)
        d.ellipse([1, 0, 6, 5], fill=(255, 220, 110, 255))
        flag.alpha_composite(outline(im), (f * 24, 0))
    res['flag'] = flag
    cp = Image.new('RGBA', (24 * 2, 40))
    for f in range(2):
        im = Image.new('RGBA', (24, 40))
        d = ImageDraw.Draw(im)
        d.rectangle([2, 4, 3, 39], fill=(230, 226, 240, 255))
        col = (140, 236, 170, 255) if f else (200, 196, 214, 255)
        d.polygon([(4, 5), (18, 9), (4, 14)], fill=col)
        cp.alpha_composite(outline(im), (f * 24, 0))
    res['checkpoint'] = cp
    ratio = Image.new('RGBA', (22, 12))
    d = ImageDraw.Draw(ratio)
    d.rounded_rectangle([0, 0, 21, 9], 3, fill=WHITE, outline=PLUM)
    d.polygon([(4, 9), (8, 9), (4, 11)], fill=WHITE)
    d.line([(6, 5), (9, 5)], fill=(240, 70, 100, 255))
    d.line([(12, 2), (12, 7)], fill=(240, 70, 100, 255))
    d.line([(11, 3), (12, 2)], fill=(240, 70, 100, 255))
    res['ratio'] = ratio
    # Sparkle particle (3 frames).
    sp = Image.new('RGBA', (8 * 3, 8))
    d = ImageDraw.Draw(sp)
    for f, r in enumerate([3, 2, 1]):
        cx = f * 8 + 4
        d.line([(cx - r, 4), (cx + r, 4)], fill=(255, 245, 170, 255))
        d.line([(cx, 4 - r), (cx, 4 + r)], fill=(255, 245, 170, 255))
        d.point((cx, 4), fill=WHITE)
    res['sparkle'] = sp
    return res


# =================================================================== UI kit

ICON_PAL = {
    'k': PLUM, 'w': WHITE, 'r': (255, 96, 140, 255), 'p': (255, 180, 205, 255),
    'y': (255, 214, 90, 255), 'Y': (255, 240, 170, 255), 'o': (240, 160, 60, 255),
    'g': (200, 196, 214, 255), 'G': (150, 140, 170, 255), 'b': (120, 200, 255, 255),
    'm': (120, 230, 180, 255), 'v': (190, 150, 240, 255),
}

ICONS = {
    'heart': [
        "..kkk..kkk..",
        ".krrrkkrrrk.",
        "krwprrrrrrrk",
        "krprrrrrrrrk",
        "krrrrrrrrrrk",
        ".krrrrrrrrk.",
        "..krrrrrrk..",
        "...krrrrk...",
        "....krrk....",
        ".....kk.....",
    ],
    'heart_empty': [
        "..kkk..kkk..",
        ".kgggkkgggk.",
        "kgwgggggggGk",
        "kgggggggggGk",
        "kggggggggGGk",
        ".kgggggGGGk.",
        "..kgggGGGk..",
        "...kgGGGk...",
        "....kGGk....",
        ".....kk.....",
    ],
    'star': [
        ".....kk.....",
        "....kyyk....",
        "....kyyk....",
        "kkkkyYyykkkk",
        "kyyyYyyyyyyk",
        ".kyyyyyyyyk.",
        "..kyyyyyyk..",
        "..kyyookyyk.",
        ".kyyok.kyyk.",
        ".kok....kok.",
        ".kk......kk.",
    ],
    'star_empty': [
        ".....kk.....",
        "....kggk....",
        "....kggk....",
        "kkkkgwggkkkk",
        "kggggggggggk",
        ".kggggggGGk.",
        "..kgggGGGk..",
        "..kggGGkGGk.",
        ".kgGGk.kGGk.",
        ".kGk....kGk.",
        ".kk......kk.",
    ],
    'clock': [
        "...kkkkkk...",
        "..kwwwwwwk..",
        ".kwwwkwwwwk.",
        "kwwwwkwwwwwk",
        "kwwwwkwwwwwk",
        "kwwwwkkkwwwk",
        "kwwwwwwwwwwk",
        "kwwwwwwwwwwk",
        ".kwwwwwwwwk.",
        "..kwwwwwwk..",
        "...kkkkkk...",
    ],
    'skull': [
        "..kkkkkkkk..",
        ".kwwwwwwwwk.",
        "kwwwwwwwwwwk",
        "kwkkwwwwkkwk",
        "kwkkwwwwkkwk",
        "kwwwwkkwwwwk",
        ".kwwwwwwwwk.",
        "..kwkwkwkk..",
        "..kkkkkkk...",
    ],
    'lock': [
        "...kkkkk....",
        "..kgggggk...",
        "..kgk.kgk...",
        "..kgk.kgk...",
        ".kkkkkkkkk..",
        ".kyyyyyyyk..",
        ".kyyykyyyk..",
        ".kyyykyyyk..",
        ".kyyyyyyyk..",
        ".kkkkkkkkk..",
    ],
    'pause': [
        "kkkk..kkkk",
        "kwwk..kwwk",
        "kwwk..kwwk",
        "kwwk..kwwk",
        "kwwk..kwwk",
        "kwwk..kwwk",
        "kwwk..kwwk",
        "kkkk..kkkk",
    ],
    'play': [
        "kk......",
        "kwkk....",
        "kwwwkk..",
        "kwwwwwk.",
        "kwwwwwwk",
        "kwwwwwk.",
        "kwwwkk..",
        "kwkk....",
        "kk......",
    ],
    'left': [
        "....kk....",
        "...kwk....",
        "..kwwkkkkk",
        ".kwwwwwwwk",
        "kwwwwwwwwk",
        ".kwwwwwwwk",
        "..kwwkkkkk",
        "...kwk....",
        "....kk....",
    ],
    'up': [
        "....kk....",
        "...kwwk...",
        "..kwwwwk..",
        ".kwwwwwwk.",
        "kkkwwwwkkk",
        "..kwwwwk..",
        "..kwwwwk..",
        "..kwwwwk..",
        "..kkkkkk..",
    ],
    'home': [
        ".....kk.....",
        "....kwwk....",
        "...kwwwwk...",
        "..kwwwwwwk..",
        ".kwwwwwwwwk.",
        "kkkwwwwwwkkk",
        "..kwwkkwwk..",
        "..kwwkkwwk..",
        "..kkkkkkkk..",
    ],
    'replay': [
        "...kkkkk.k..",
        "..kwwwwwkwk.",
        ".kwkkkkkwwk.",
        "kwk....kwwk.",
        "kwk...kkkkk.",
        "kwk.........",
        "kwk.....kk..",
        ".kwkkkkkwk..",
        "..kwwwwwk...",
        "...kkkkk....",
    ],
    'trophy': [
        "kkkkkkkkkk",
        "kyYyyyyyok",
        "kyYyyyyyok",
        ".kyyyyyok.",
        "..kyyyok..",
        "...kook...",
        "....kk....",
        "...kook...",
        "..kkkkkk..",
    ],
    'edit': [
        "......kk..",
        ".....kpwk.",
        "....kyyk..",
        "...kyyk...",
        "..kyyk....",
        ".kyyk.....",
        "kwyk......",
        "kkk.......",
    ],
    'music': [
        "....kkkkkk",
        "....kwwwwk",
        "....kwkkkk",
        "....kwk..k",
        "....kwk.kk",
        "..kkkwkkwk",
        ".kwwwwkwwk",
        ".kwwwk.kk.",
        "..kkk.....",
    ],
    'sound': [
        "....kk..k...",
        "...kwk...k..",
        "kkkwwk.k..k.",
        "kwwwwk..k.k.",
        "kwwwwk..k.k.",
        "kkkwwk.k..k.",
        "...kwk...k..",
        "....kk..k...",
    ],
    'gear': [
        "....kkkk....",
        ".kk.kwwk.kk.",
        ".kwkkwwkkwk.",
        "..kwwwwwwk..",
        "kkkwwkkwwkkk",
        "kwwwk..kwwwk",
        "kwwwk..kwwwk",
        "kkkwwkkwwkkk",
        "..kwwwwwwk..",
        ".kwkkwwkkwk.",
        ".kk.kwwk.kk.",
        "....kkkk....",
    ],
    'vibrate': [
        ".k.kkkkkk.k.",
        "k.kwwwwwwk.k",
        ".kkwkkkkwkk.",
        "k.kwkkkkwk.k",
        ".kkwkkkkwkk.",
        "k.kwwwwwwk.k",
        ".k.kkkkkk.k.",
    ],
    'bolt': [
        "....kkkk",
        "...kyyk.",
        "..kyyk..",
        ".kyyykkk",
        "kkkyyyyk",
        "...kyyk.",
        "..kyyk..",
        ".kyk....",
        ".kk.....",
    ],
}


def ui_kit() -> dict[str, Image.Image]:
    res = {}
    for name, rows in ICONS.items():
        res[f'icon_{name}'] = pixmap(rows, ICON_PAL)
    res['icon_right'] = res['icon_left'].transpose(Image.FLIP_LEFT_RIGHT)
    res['icon_like'] = res['icon_heart']
    # 9-slice panel (cream with plum border and rounded pixel corners).
    # Single tiles used by the menus' little landscape.
    feed = tileset('feed')
    res['tile_grass'] = feed.crop((0, 0, T, T))
    res['tile_dirt'] = feed.crop((T, 0, 2 * T, T))
    res['panel'] = _frame(24, (255, 248, 236), (240, 226, 214))
    res['panel_dark'] = _frame(24, (70, 52, 92), (56, 40, 76))
    for name, col in {
        'pink': (255, 130, 180), 'purple': (180, 140, 240),
        'mint': (110, 220, 170), 'grey': (170, 164, 190),
        'yellow': (255, 210, 100), 'blue': (120, 190, 255),
    }.items():
        res[f'button_{name}'] = _button(col, False)
        res[f'button_{name}_down'] = _button(col, True)
    return res


def _frame(s, fill, shade_col):
    img = Image.new('RGBA', (s, s))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, s - 1, s - 1], 5, fill=rgba(fill), outline=PLUM,
                        width=2)
    d.line([(4, s - 4), (s - 5, s - 4)], fill=rgba(shade_col), width=2)
    d.line([(4, 3), (s - 5, 3)], fill=WHITE)
    return img


def _button(col, down):
    s = 24
    img = Image.new('RGBA', (s, s))
    d = ImageDraw.Draw(img)
    top = 2 if down else 0
    d.rounded_rectangle([0, top, s - 1, s - 1], 6, fill=rgba(darken(col, .3)),
                        outline=PLUM, width=2)
    d.rounded_rectangle([0, top, s - 1, s - 4 + (2 if down else 0)], 6,
                        fill=rgba(col), outline=PLUM, width=2)
    d.line([(5, top + 3), (s - 6, top + 3)], fill=lighten(col, .55), width=2)
    return img


def write_all(out: str):
    files = {}
    for kind in ['normie', 'cringe', 'hater', 'boomer']:
        files[f'enemy_{kind}'] = enemy_strip(kind)
    files['enemy_algorithm'] = boss_strip()
    import pixel_details
    files['dust'] = pixel_details.dust()
    for theme in THEMES:
        files[f'tiles_{theme}'] = tileset(theme)
        files[f'props_{theme}'] = pixel_details.props_sheet(theme)
        files[f'bg_{theme}_mid'] = pixel_details.mid_layer(theme)
        files[f'moving_{theme}'] = moving_platform(theme)
        files.update(backgrounds(theme))
    files.update(items())
    ui = ui_kit()
    os.makedirs(os.path.join(out, '..', 'ui'), exist_ok=True)
    for k, im in files.items():
        im.save(os.path.join(out, f'{k}.png'))
    for k, im in ui.items():
        im.save(os.path.join(out, '..', 'ui', f'{k}.png'))

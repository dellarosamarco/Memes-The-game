"""Detailed terrain tiles: each world gets its own ground material (grass,
sand, snow, frosting, goo, magma, metal, cloud) with a textured body, a
thick top cap with an overhanging fringe, and nicer bricks, platforms and
spikes. Used by pixel_world.tileset().
"""
from __future__ import annotations

import math

import numpy as np
from PIL import Image, ImageDraw

from pixel_world import PLUM, T, THEMES, WHITE, darken, lighten, mix, rgba

STYLE = {
    'feed': 'grass', 'forest': 'grass', 'beach': 'sand', 'desert': 'sand',
    'ice': 'snow', 'clouds': 'cloud', 'candy': 'frosting', 'comments': 'goo',
    'volcano': 'magma', 'server': 'metal',
}

# Depth of the top cap (rows of top material) before the fringe.
CAP = 7


def _wave(x: int, period: int = T, amp: float = 1.0, phase: float = 0) -> int:
    """Periodic over the tile width, so neighbouring tiles line up."""
    return int(round(amp * math.sin(2 * math.pi * (x + phase) / period)))


# ---------------------------------------------------------------- the body

def body(theme: str, rnd) -> Image.Image:
    th = THEMES[theme]
    style = STYLE[theme]
    dirt = rgba(th['dirt'])
    img = Image.new('RGBA', (T, T), dirt)
    d = ImageDraw.Draw(img)
    dark, light = darken(dirt, .13), lighten(dirt, .1)

    if style == 'metal':
        # Circuit board: panel seams, traces and glowing vias.
        d.rectangle([0, 0, T - 1, T - 1], fill=dirt)
        d.line([(0, 11), (T - 1, 11)], fill=dark)
        d.line([(0, 12), (T - 1, 12)], fill=light)
        neon = rgba(th['top'])
        trace = mix(dirt, neon, .35)
        d.line([(2, 5), (9, 5), (12, 8), (T - 1, 8)], fill=trace)
        d.line([(0, 17), (6, 17), (9, 20), (17, 20), (20, 17), (T - 1, 17)],
               fill=trace)
        for x, y in ((9, 5), (17, 20), (3, 17)):
            d.rectangle([x - 1, y - 1, x + 1, y + 1], fill=darken(dirt, .3))
            d.point((x, y), fill=neon)
        for x, y in ((1, 1), (T - 2, 1), (1, T - 2), (T - 2, T - 2)):
            d.point((x, y), fill=light)
        return img

    # Speckle texture (clusters of darker / lighter pixels).
    for _ in range(16):
        x, y = (int(v) for v in rnd.integers(0, T, 2))
        c = dark if rnd.random() < .6 else light
        d.point((x, y), fill=c)
        if rnd.random() < .5:
            d.point(((x + 1) % T, y), fill=c)
    # Wavy strata bands (periodic so tiles connect).
    for y0, ph in ((8, 0), (19, 7)):
        for x in range(T):
            y = y0 + _wave(x, amp=1.2, phase=ph)
            if x % 4 != 3:
                d.point((x, y), fill=darken(dirt, .08))
    # One soft pebble (a strong pattern would repeat visibly every tile).
    x, y = 14, 11
    peb = lighten(dirt, .14) if style != 'magma' else darken(dirt, .16)
    d.ellipse([x, y, x + 3, y + 2], fill=peb, outline=darken(dirt, .18))
    d.point((x + 1, y), fill=lighten(dirt, .3))

    if style == 'grass':
        pass
    elif style in ('snow', 'cloud'):
        # Ice crystals / soft swirls.
        c = lighten(dirt, .45)
        for x, y in ((5, 14), (18, 4)):
            d.point([(x, y), (x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)],
                    fill=c)
    elif style == 'frosting':
        # Cake layers: a cream stripe and sprinkles.
        d.rectangle([0, 12, T - 1, 13], fill=(255, 236, 214, 255))
        d.line([(0, 14), (T - 1, 14)], fill=darken(dirt, .2))
    elif style == 'goo':
        for x, y, r in ((5, 15, 2), (17, 6, 1), (14, 19, 1)):
            d.ellipse([x - r, y - r, x + r, y + r],
                      outline=lighten(dirt, .35))
    elif style == 'magma':
        # Glowing cracks.
        glow, hot = (255, 120, 60, 255), (255, 210, 110, 255)
        d.line([(0, 15), (5, 13), (9, 16), (13, 14)], fill=glow)
        d.line([(16, 4), (19, 7), (T - 1, 6)], fill=glow)
        d.point([(5, 13), (19, 7)], fill=hot)
    return img


# ----------------------------------------------------------------- the cap

def _fringe(style: str, x: int) -> int:
    """Extra rows the cap hangs down below CAP at column x (periodic)."""
    if style == 'grass':
        return 1 + (x * 7 % 5 == 0) + (x % 6 in (2, 3)) + _wave(x, 8, 0.6)
    if style == 'sand':
        return 1 + _wave(x, 12, 1.0)
    if style in ('snow', 'cloud'):
        return 2 + _wave(x, 8, 1.4, 2)
    if style == 'frosting':
        # Rounded drips.
        for cx, ln in ((4, 6), (13, 4), (20, 7)):
            if abs(x - cx) <= 1:
                return ln - (abs(x - cx) == 1) * 2
        return 1
    if style == 'goo':
        for cx, ln in ((6, 5), (17, 4)):
            if abs(x - cx) <= 1:
                return ln - (abs(x - cx) == 1)
        return 1 + _wave(x, 12, 0.6)
    if style == 'magma':
        return 1 + (x % 7 == 3)
    if style == 'metal':
        return 0
    return 1


def top_tile(theme: str, rnd) -> Image.Image:
    th = THEMES[theme]
    style = STYLE[theme]
    top = rgba(th['top'])
    dirt = rgba(th['dirt'])
    img = body(theme, rnd)
    d = ImageDraw.Draw(img)
    hi, lo = lighten(top, .4), darken(top, .16)
    for x in range(T):
        depth = CAP + max(0, _fringe(style, x))
        # Shadow cast on the dirt right under the fringe.
        d.point((x, depth), fill=darken(dirt, .28))
        d.point((x, depth + 1), fill=darken(dirt, .14))
        d.line([(x, 0), (x, depth - 1)], fill=top)
        d.point((x, depth - 1), fill=lo)
    # Highlight band and outline.
    d.line([(0, 1), (T - 1, 1)], fill=hi)
    d.line([(0, 2), (T - 1, 2)], fill=lighten(top, .18))
    d.line([(0, 0), (T - 1, 0)], fill=PLUM)

    if style == 'grass':
        blade = darken(top, .22)
        for x in range(1, T, 3):
            h = 2 + (x * 5 % 3)
            y = 3 + (x % 2)
            d.line([(x, y), (x, y + h - 1)], fill=blade)
        for _ in range(2):  # tiny flowers
            x = int(rnd.integers(3, T - 3))
            c = [(255, 140, 180), (255, 230, 110), (255, 255, 255)][
                int(rnd.integers(3))]
            d.point([(x - 1, 3), (x + 1, 3), (x, 2), (x, 4)], fill=rgba(c))
            d.point((x, 3), fill=(255, 200, 80, 255))
    elif style == 'sand':
        for x in range(0, T, 2):
            d.point((x, 4 + _wave(x, 12, 1)), fill=lo)
        d.point([(7, 3), (8, 3), (7, 2)], fill=(255, 170, 170, 255))
        d.point((18, 3), fill=WHITE)
    elif style == 'snow':
        for x in (3, 11, 19):
            d.point((x, 3), fill=WHITE)
        ice = (170, 220, 255, 255)
        for cx, ln in ((6, 4), (16, 5)):
            base = CAP + max(0, _fringe(style, cx))
            for k in range(ln):
                w = 1 if k < ln - 2 else 0
                d.line([(cx - w, base + k), (cx + w, base + k)], fill=ice)
            d.point((cx, base), fill=WHITE)
    elif style == 'cloud':
        for x in range(0, T, 6):
            d.arc([x, 1, x + 5, 6], 200, 340, fill=WHITE)
    elif style == 'frosting':
        cols = [(120, 200, 255), (255, 240, 120), (160, 255, 170),
                (255, 255, 255)]
        for i in range(6):
            x = int(rnd.integers(1, T - 2))
            y = int(rnd.integers(3, CAP))
            c = rgba(cols[i % len(cols)])
            d.line([(x, y), (x + 1, y)], fill=c)
        d.point([(4, 2), (13, 2)], fill=WHITE)
    elif style == 'goo':
        for x, y in ((5, 3), (15, 4), (20, 2)):
            d.ellipse([x - 1, y - 1, x + 1, y + 1], outline=hi)
    elif style == 'magma':
        d.line([(0, 1), (T - 1, 1)], fill=(255, 210, 120, 255))
        for x in (4, 13, 20):
            d.point((x, 3), fill=(255, 240, 170, 255))
        d.line([(8, 4), (11, 3)], fill=darken(top, .3))
    elif style == 'metal':
        d.line([(0, CAP - 2), (T - 1, CAP - 2)], fill=lighten(top, .5))
        for x in (3, T - 4):
            d.point((x, 3), fill=darken(top, .45))
        d.line([(10, 3), (13, 3)], fill=darken(top, .3))
    return img


# ------------------------------------------------------- bricks & friends

def brick(theme: str, rnd) -> Image.Image:
    b = rgba(THEMES[theme]['brick'])
    mortar = darken(b, .32)
    img = Image.new('RGBA', (T, T), mortar)
    d = ImageDraw.Draw(img)
    for row in range(3):
        y0 = row * 8
        off = 0 if row % 2 == 0 else 6
        for col in range(-1, 3):
            x0 = col * 12 + off
            tone = mix(b, lighten(b, .12) if (row + col) % 2 else
                       darken(b, .06), .6)
            d.rectangle([x0 + 1, y0 + 1, x0 + 11, y0 + 7], fill=tone)
            d.line([(x0 + 1, y0 + 1), (x0 + 10, y0 + 1)],
                   fill=lighten(tone, .35))
            d.line([(x0 + 1, y0 + 1), (x0 + 1, y0 + 6)],
                   fill=lighten(tone, .2))
            d.line([(x0 + 2, y0 + 7), (x0 + 11, y0 + 7)],
                   fill=darken(tone, .18))
            if (row * 3 + col) % 4 == 1:  # little chip
                d.point((x0 + 8, y0 + 4), fill=darken(tone, .22))
    return img


def platform(theme: str) -> Image.Image:
    p = rgba(THEMES[theme]['plat'])
    img = Image.new('RGBA', (T, T))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, T - 1, 9], fill=p)
    d.line([(0, 1), (T - 1, 1)], fill=lighten(p, .45))
    d.line([(0, 8), (T - 1, 8)], fill=darken(p, .18))
    d.line([(0, 9), (T - 1, 9)], fill=darken(p, .3))
    # Wood grain and nails.
    d.line([(2, 4), (8, 4)], fill=darken(p, .12))
    d.line([(13, 6), (20, 6)], fill=darken(p, .12))
    for x in (5, 18):
        d.point((x, 6), fill=darken(p, .45))
        d.point((x, 5), fill=lighten(p, .3))
    # Little support brackets underneath.
    for x in (4, T - 7):
        d.polygon([(x, 10), (x + 3, 10), (x + 1, 13)], fill=darken(p, .25))
    d.line([(0, 0), (T - 1, 0)], fill=PLUM)
    d.line([(0, 10), (T - 1, 10)], fill=PLUM)
    return img


def spikes() -> Image.Image:
    img = Image.new('RGBA', (T, T))
    d = ImageDraw.Draw(img)
    steel, shine, shade = ((226, 230, 246, 255), (255, 255, 255, 255),
                           (150, 150, 186, 255))
    d.rectangle([0, T - 4, T - 1, T - 1], fill=(120, 110, 150, 255))
    d.line([(0, T - 4), (T - 1, T - 4)], fill=(170, 160, 200, 255))
    for k in range(3):
        x = k * 8
        d.polygon([(x, T - 4), (x + 4, T - 15), (x + 8, T - 4)], fill=steel)
        d.polygon([(x + 4, T - 15), (x + 8, T - 4), (x + 5, T - 4)],
                  fill=shade)
        d.line([(x + 3, T - 11), (x + 2, T - 6)], fill=shine)
    return img

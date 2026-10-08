"""Extra cute details: auto-tile ground edges and variants, animated pit
liquids, decorative props for each world, a mid parallax layer and small
effect sprites (dust puffs).
"""
from __future__ import annotations

import os

import numpy as np
from PIL import Image, ImageDraw

from pixel_world import (BLUSH, PLUM, T, THEMES, WHITE, darken, lighten,
                         mix, outline, rgba)

# Extra tiles appended after the base tileset, in this order (must match
# lib/game/components/items.dart).
EXTRA_TILES = ['top_l', 'top_r', 'top_lr', 'side_l', 'side_r', 'side_lr',
               'top_v2', 'top_v3', 'dirt_v2', 'liquid0', 'liquid1',
               'liquid_deep', 'power_block']

LIQUIDS = {
    'feed': ((110, 200, 255), 'water'), 'comments': ((190, 130, 240), 'goo'),
    'beach': ((90, 210, 230), 'water'), 'desert': ((230, 170, 90), 'sand'),
    'ice': ((150, 220, 255), 'water'), 'candy': ((255, 140, 200), 'syrup'),
    'forest': ((90, 190, 170), 'water'), 'volcano': ((255, 120, 60), 'lava'),
    'clouds': ((255, 255, 255), 'fluff'), 'server': ((90, 255, 180), 'data'),
}


def _edge(tile: Image.Image, left: bool, right: bool, top: bool) -> Image.Image:
    """Adds thick (2px, Kenney-style) plum outlines and rounded corners on
    the open sides."""
    a = np.array(tile)
    h, w = a.shape[:2]
    shade = a.copy()
    for side, xs in ((left, (0, 1, 2)), (right, (w - 1, w - 2, w - 3))):
        if not side:
            continue
        x0, x1, x2 = xs
        a[:, x0] = PLUM
        a[:, x1] = PLUM
        for y in range(h):
            if a[y, x2, 3] and not (a[y, x2] == PLUM).all():
                a[y, x2, :3] = (np.array(shade[y, x2, :3]) * .85).astype(np.uint8)
        if top:
            # Rounded corner.
            a[0, x0] = (0, 0, 0, 0)
    return Image.fromarray(a)


def _top_outline(tile: Image.Image) -> Image.Image:
    d = ImageDraw.Draw(tile)
    d.line([(0, 0), (T - 1, 0)], fill=PLUM)
    return tile


def _liquid(theme: str, frame: int, deep: bool) -> Image.Image:
    col, kind = LIQUIDS[theme]
    base = rgba(col)
    img = Image.new('RGBA', (T, T))
    d = ImageDraw.Draw(img)
    if deep:
        d.rectangle([0, 0, T - 1, T - 1], fill=darken(base, .12))
        for (x, y) in ((4, 6), (15, 14), (9, 19)):
            d.point((x, y), fill=lighten(base, .3))
        return img
    d.rectangle([0, 6, T - 1, T - 1], fill=base)
    d.rectangle([0, 14, T - 1, T - 1], fill=darken(base, .12))
    # Wavy surface.
    for x in range(T):
        y = 4 + int(round(np.sin((x + frame * 6) / 24 * 2 * np.pi) * 1.5))
        d.line([(x, y), (x, 7)], fill=lighten(base, .35))
        d.point((x, y - 1), fill=lighten(base, .65))
    if kind in ('water', 'goo', 'syrup', 'data'):
        for (x, y) in ((5 + frame * 3, 10), (16 - frame * 2, 17)):
            d.ellipse([x, y, x + 2, y + 2], outline=lighten(base, .55))
    if kind == 'lava':
        for (x, y) in ((3 + frame * 4, 9), (17, 15 - frame)):
            d.rectangle([x, y, x + 1, y + 1], fill=(255, 230, 120, 255))
    if kind == 'fluff':
        for x in range(0, T, 8):
            d.ellipse([x - 2 + frame * 2, 2, x + 7 + frame * 2, 11], fill=WHITE)
    return img


def extra_tiles(theme: str, ground_top: Image.Image,
                ground: Image.Image) -> list[Image.Image]:
    rnd = np.random.default_rng(sum(map(ord, theme)) + 3)
    th = THEMES[theme]
    top_col = rgba(th['top'])
    dirt = rgba(th['dirt'])
    gt = _top_outline(ground_top.copy())
    tiles = {
        'top_l': _edge(gt, True, False, True),
        'top_r': _edge(gt, False, True, True),
        'top_lr': _edge(gt, True, True, True),
        'side_l': _edge(ground, True, False, False),
        'side_r': _edge(ground, False, True, False),
        'side_lr': _edge(ground, True, True, False),
    }
    v2 = gt.copy()
    d = ImageDraw.Draw(v2)
    # A little tuft of taller grass.
    for x in (6, 9, 12):
        d.line([(x, 4), (x + (x - 9) // 3, 0)], fill=darken(top_col, .2))
        d.point((x + (x - 9) // 3, 0), fill=lighten(top_col, .3))
    tiles['top_v2'] = v2
    v3 = gt.copy()
    d = ImageDraw.Draw(v3)
    d.ellipse([14, 1, 19, 5], fill=(214, 206, 226, 255), outline=PLUM)
    d.point((15, 2), fill=WHITE)
    tiles['top_v3'] = v3
    dv = ground.copy()
    d = ImageDraw.Draw(dv)
    if rnd.random() < .5 or True:
        # Buried treasure: a tiny gem or a bone.
        d.polygon([(10, 12), (13, 9), (16, 12), (13, 15)],
                  fill=(140, 230, 255, 255), outline=PLUM)
        d.point((12, 11), fill=WHITE)
        d.line([(3, 19), (7, 18)], fill=lighten(dirt, .35), width=2)
    tiles['dirt_v2'] = dv
    tiles['liquid0'] = _liquid(theme, 0, False)
    tiles['liquid1'] = _liquid(theme, 1, False)
    tiles['liquid_deep'] = _liquid(theme, 0, True)
    tiles['power_block'] = power_block()
    return [tiles[n] for n in EXTRA_TILES]


# ====================================================================== props

def _flower(d, x, petal, center=(255, 214, 90), stem=(90, 170, 90), h=9,
            sway=0):
    top = 23 - h
    d.line([(x, 23), (x + sway, top + 2)], fill=rgba(stem))
    d.point([(x - 1, 19), (x + 1, 17)], fill=rgba(stem))
    cx = x + sway
    for dx, dy in ((-2, 0), (2, 0), (0, -2), (0, 2)):
        d.ellipse([cx + dx - 1, top + dy - 1, cx + dx + 1, top + dy + 1],
                  fill=rgba(petal))
    d.point((cx, top), fill=rgba(center))


def _tuft(d, col, sway=0):
    for x, h in ((8, 6), (11, 9), (14, 7), (17, 5)):
        d.line([(x, 23), (x + sway, 23 - h)], fill=rgba(col), width=2)


def _bush(d, col, sway=0, face=True):
    d.ellipse([3, 11, 13, 23], fill=rgba(col))
    d.ellipse([10, 9 + sway, 21, 23], fill=rgba(col))
    d.ellipse([6, 6, 17, 20], fill=rgba(col))
    d.ellipse([8, 8, 11, 10], fill=lighten(col, .4))
    if face:
        d.point([(9, 15), (14, 15)], fill=PLUM)
        d.arc([10, 15, 13, 18], 20, 160, fill=PLUM)
        d.point([(7, 17), (16, 17)], fill=BLUSH)


def _mushroom(d, cap, sway=0, small=False):
    s = 0.7 if small else 1
    d.rounded_rectangle([10, int(23 - 8 * s), 14, 23], 1,
                        fill=(255, 240, 220, 255))
    d.ellipse([int(12 - 8 * s) + sway, int(23 - 15 * s),
               int(12 + 8 * s) + sway, int(23 - 6 * s)], fill=rgba(cap))
    d.point([(9 + sway, int(23 - 12 * s)), (14 + sway, int(23 - 11 * s))],
            fill=WHITE)
    d.point([(11, 21), (13, 21)], fill=PLUM)


def _rock(d, col):
    d.ellipse([5, 15, 19, 24], fill=rgba(col))
    d.ellipse([7, 16, 11, 19], fill=lighten(col, .35))


def _sign(d, text_col, board=(214, 160, 110), sway=0):
    d.rectangle([11, 14, 12, 23], fill=darken(board, .3))
    d.rounded_rectangle([3, 5 + sway, 20, 15 + sway], 2, fill=rgba(board))
    d.line([(6, 8 + sway), (17, 8 + sway)], fill=rgba(text_col))
    d.line([(6, 11 + sway), (14, 11 + sway)], fill=rgba(text_col))


def _heart(d, x, y, col, s=1):
    d.ellipse([x, y, x + 3 * s, y + 3 * s], fill=rgba(col))
    d.ellipse([x + 3 * s, y, x + 6 * s, y + 3 * s], fill=rgba(col))
    d.polygon([(x, y + 2 * s), (x + 6 * s, y + 2 * s), (x + 3 * s, y + 6 * s)],
              fill=rgba(col))


def _starfish(d, col):
    import math
    pts = []
    for i in range(10):
        r = 9 if i % 2 == 0 else 4
        a = -math.pi / 2 + i * math.pi / 5
        pts.append((12 + r * math.cos(a), 16 + r * math.sin(a)))
    d.polygon(pts, fill=rgba(col))
    d.point([(10, 15), (14, 15)], fill=PLUM)
    d.point([(12, 17)], fill=PLUM)


def _shell(d):
    d.pieslice([5, 12, 19, 26], 180, 360, fill=(255, 200, 200, 255))
    for x in (8, 12, 16):
        d.line([(12, 19), (x, 13)], fill=(230, 150, 160, 255))


def _palm(d, sway=0):
    d.line([(12, 23), (12 + sway, 10)], fill=(170, 120, 80, 255), width=3)
    for dx in (-6, 6):
        d.ellipse([12 + sway + (dx - 6 if dx < 0 else 0), 6,
                   12 + sway + (0 if dx < 0 else dx + 6), 12],
                  fill=(110, 200, 110, 255))
    d.ellipse([10 + sway, 10, 13 + sway, 13], fill=(150, 100, 60, 255))


def _sandcastle(d):
    d.rectangle([5, 14, 19, 23], fill=(250, 214, 150, 255))
    d.rectangle([9, 9, 15, 14], fill=(250, 214, 150, 255))
    for x in (5, 9, 13, 17):
        d.rectangle([x, 12, x + 1, 13], fill=(250, 214, 150, 255))
    d.rectangle([11, 18, 13, 23], fill=(200, 160, 100, 255))
    d.line([(12, 9), (12, 4)], fill=PLUM)
    d.polygon([(12, 4), (17, 5), (12, 7)], fill=(255, 110, 140, 255))


def _crab(d, sway=0):
    d.ellipse([6, 14 + sway, 18, 22 + sway], fill=(255, 120, 100, 255))
    d.ellipse([3, 11, 7, 15], fill=(255, 120, 100, 255))
    d.ellipse([17, 11, 21, 15], fill=(255, 120, 100, 255))
    d.point([(10, 16 + sway), (14, 16 + sway)], fill=PLUM)
    d.point([(8, 19 + sway), (16, 19 + sway)], fill=BLUSH)
    for x in (7, 10, 14, 17):
        d.line([(x, 22), (x, 23)], fill=(200, 80, 70, 255))


def _ball(d):
    d.ellipse([6, 12, 18, 24], fill=WHITE)
    d.pieslice([6, 12, 18, 24], 200, 260, fill=(255, 110, 140, 255))
    d.pieslice([6, 12, 18, 24], 320, 20, fill=(110, 200, 255, 255))
    d.pieslice([6, 12, 18, 24], 80, 140, fill=(255, 214, 90, 255))


def _cactus(d, round_=False, sway=0):
    g = (110, 190, 110, 255)
    if round_:
        d.ellipse([6, 12, 18, 24], fill=g)
        _flower(d, 12, (255, 130, 180), h=13, stem=(110, 190, 110), sway=0)
    else:
        d.rounded_rectangle([9, 6, 15, 23], 3, fill=g)
        d.rounded_rectangle([3 + sway, 11, 7 + sway, 17], 2, fill=g)
        d.rounded_rectangle([17, 9, 21, 15], 2, fill=g)
        d.point([(11, 11), (13, 11)], fill=PLUM)
        d.arc([10, 11, 14, 15], 20, 160, fill=PLUM)
    d.point([(12, 8), (10, 18)], fill=lighten(g, .4))


def _bone(d):
    d.line([(6, 20), (18, 17)], fill=(250, 246, 236, 255), width=3)
    for x, y in ((5, 19), (5, 21), (19, 16), (19, 18)):
        d.ellipse([x - 1, y - 1, x + 1, y + 1], fill=(250, 246, 236, 255))


def _pot(d):
    d.ellipse([6, 12, 18, 24], fill=(214, 130, 90, 255))
    d.rectangle([9, 10, 15, 13], fill=(214, 130, 90, 255))
    d.line([(7, 17), (17, 17)], fill=(255, 220, 140, 255))


def _snowman(d, sway=0):
    d.ellipse([5, 13, 19, 24], fill=WHITE)
    d.ellipse([8, 5 + sway, 16, 13 + sway], fill=WHITE)
    d.point([(10, 8 + sway), (14, 8 + sway)], fill=PLUM)
    d.point([(12, 10 + sway)], fill=(255, 150, 60, 255))
    d.rectangle([8, 12, 16, 13], fill=(255, 110, 140, 255))
    d.point([(9, 10 + sway), (15, 10 + sway)], fill=BLUSH)


def _crystal(d, col):
    d.polygon([(12, 4), (17, 12), (14, 23), (10, 23), (7, 12)], fill=rgba(col))
    d.polygon([(6, 15), (9, 18), (8, 23), (4, 23)], fill=lighten(col, .2))
    d.line([(11, 8), (10, 18)], fill=lighten(col, .55))


def _pine(d, sway=0):
    for i, (w, y) in enumerate(((5, 4), (7, 9), (9, 14))):
        d.polygon([(12 + sway, y), (12 - w, y + 7), (12 + w, y + 7)],
                  fill=(90, 160, 130, 255))
        d.line([(12 - w + 1, y + 6), (12 + w - 1, y + 6)], fill=WHITE)
    d.rectangle([11, 21, 13, 23], fill=(150, 100, 80, 255))


def _penguin(d, sway=0):
    d.ellipse([6, 8 + sway, 18, 24], fill=(60, 64, 90, 255))
    d.ellipse([8, 12 + sway, 16, 24], fill=WHITE)
    d.point([(10, 12 + sway), (14, 12 + sway)], fill=PLUM)
    d.polygon([(11, 14 + sway), (13, 14 + sway), (12, 16 + sway)],
              fill=(255, 180, 60, 255))
    d.point([(9, 15 + sway), (15, 15 + sway)], fill=BLUSH)


def _snowpile(d):
    d.ellipse([3, 15, 21, 25], fill=WHITE)
    d.ellipse([8, 12, 16, 20], fill=WHITE)
    d.point([(9, 15), (14, 17)], fill=(200, 230, 255, 255))


def _igloo(d):
    d.pieslice([3, 8, 21, 32], 180, 360, fill=WHITE)
    d.pieslice([9, 16, 15, 28], 180, 360, fill=(120, 170, 220, 255))
    for y in (14, 18):
        d.line([(5, y), (19, y)], fill=(200, 230, 255, 255))


def _snowflake(d, sway=0):
    c = (230, 245, 255, 255)
    cx, cy = 12, 14 + sway
    for dx, dy in ((5, 0), (0, 5), (4, 4), (4, -4)):
        d.line([(cx - dx, cy - dy), (cx + dx, cy + dy)], fill=c)


def _lollipop(d, col, sway=0):
    d.line([(12, 23), (12, 12)], fill=WHITE, width=2)
    d.ellipse([6 + sway, 3, 18 + sway, 15], fill=rgba(col))
    d.arc([8 + sway, 5, 16 + sway, 13], 0, 300, fill=WHITE)


def _cane(d):
    d.line([(14, 23), (14, 9)], fill=WHITE, width=3)
    d.arc([8, 5, 16, 13], 180, 360, fill=WHITE, width=3)
    for y in (11, 15, 19):
        d.line([(13, y), (15, y - 1)], fill=(255, 90, 110, 255))


def _cupcake(d, sway=0):
    d.polygon([(6, 15), (18, 15), (16, 23), (8, 23)], fill=(255, 190, 120, 255))
    d.ellipse([5, 8 + sway, 19, 17 + sway], fill=(255, 170, 210, 255))
    d.ellipse([10, 4 + sway, 14, 8 + sway], fill=(255, 80, 110, 255))
    d.point([(8, 12 + sway), (15, 11 + sway), (12, 14 + sway)],
            fill=(120, 200, 255, 255))


def _gumdrop(d, col):
    d.pieslice([5, 10, 19, 34], 180, 360, fill=rgba(col))
    d.point([(9, 15), (14, 17)], fill=WHITE)


def _donut(d):
    d.ellipse([4, 12, 20, 24], fill=(220, 170, 110, 255))
    d.ellipse([4, 11, 20, 21], fill=(255, 160, 210, 255))
    d.ellipse([10, 15, 14, 18], fill=(0, 0, 0, 0))
    d.point([(7, 14), (16, 13), (13, 19)], fill=WHITE)


def _icecream(d, sway=0):
    d.polygon([(8, 14), (16, 14), (12, 24)], fill=(240, 190, 120, 255))
    d.ellipse([7 + sway, 6, 17 + sway, 16], fill=(170, 230, 200, 255))
    d.ellipse([9 + sway, 2, 15 + sway, 9], fill=(255, 180, 210, 255))


def _fern(d, sway=0):
    g = (90, 170, 100, 255)
    d.line([(12, 23), (12 + sway, 6)], fill=g)
    for y in range(8, 22, 3):
        d.line([(12, y), (7 + sway, y - 2)], fill=g)
        d.line([(12, y), (17 + sway, y - 2)], fill=g)


def _stump(d):
    d.rectangle([6, 14, 18, 23], fill=(160, 110, 80, 255))
    d.ellipse([6, 11, 18, 17], fill=(230, 190, 140, 255))
    d.ellipse([10, 13, 14, 15], outline=(190, 140, 100, 255))


def _snail(d, sway=0):
    d.rounded_rectangle([4 + sway, 19, 20, 23], 2, fill=(250, 220, 170, 255))
    d.ellipse([7, 9, 18, 20], fill=(240, 150, 120, 255))
    d.arc([9, 11, 16, 18], 0, 330, fill=(255, 220, 190, 255))
    d.line([(5 + sway, 19), (4 + sway, 15)], fill=(250, 220, 170, 255))
    d.point((4 + sway, 14), fill=PLUM)


def _acorn(d):
    d.ellipse([8, 13, 16, 23], fill=(200, 140, 80, 255))
    d.pieslice([7, 9, 17, 17], 180, 360, fill=(140, 100, 70, 255))
    d.line([(12, 9), (13, 7)], fill=(140, 100, 70, 255))


def _vent(d, sway=0):
    d.rectangle([7, 18, 17, 23], fill=(110, 70, 80, 255))
    for i, y in enumerate((14, 9, 4)):
        r = 2 + i
        d.ellipse([12 - r + sway * (i % 2), y - r, 12 + r + sway * (i % 2),
                   y + r], fill=(220, 210, 220, 180))


def _flameflower(d, sway=0):
    d.line([(12, 23), (12, 13)], fill=(150, 90, 80, 255))
    d.polygon([(12 + sway, 4), (17, 12), (12, 15), (7, 12)],
              fill=(255, 130, 60, 255))
    d.polygon([(12 + sway, 8), (14, 12), (12, 14), (10, 12)],
              fill=(255, 230, 120, 255))


def _star(d, col, y=10, s=1):
    import math
    pts = []
    for i in range(10):
        r = (7 if i % 2 == 0 else 3) * s
        a = -math.pi / 2 + i * math.pi / 5
        pts.append((12 + r * math.cos(a), y + 4 + r * math.sin(a)))
    d.polygon(pts, fill=rgba(col))
    d.point([(10, y + 4), (14, y + 4)], fill=PLUM)


def _puff(d, sway=0):
    d.ellipse([3, 14, 13, 23], fill=WHITE)
    d.ellipse([9, 12 + sway, 21, 23], fill=WHITE)
    d.ellipse([7, 9, 16, 19], fill=WHITE)


def _rainbow(d):
    for i, c in enumerate(((255, 120, 140), (255, 200, 110), (140, 230, 160),
                           (140, 190, 255))):
        d.arc([2 + i * 2, 8 + i * 2, 22 - i * 2, 36 - i * 2], 180, 360,
              fill=rgba(c), width=2)


def _bell(d, sway=0):
    d.pieslice([6 + sway, 8, 18 + sway, 26], 180, 360, fill=(255, 214, 90, 255))
    d.rectangle([6 + sway, 16, 18 + sway, 18], fill=(255, 214, 90, 255))
    d.ellipse([10 + sway, 17, 14 + sway, 21], fill=(230, 160, 60, 255))


def _feather(d, sway=0):
    d.ellipse([7 + sway, 6, 15 + sway, 22], fill=WHITE)
    d.line([(11 + sway, 8), (12, 23)], fill=(200, 200, 230, 255))


def _rack(d, sway=0):
    d.rectangle([6, 6, 18, 23], fill=(70, 80, 120, 255))
    for y in (9, 13, 17):
        d.line([(8, y), (16, y)], fill=(40, 50, 80, 255))
        d.point((15, y), fill=(130, 255, 200, 255) if (y + sway) % 2
                else (255, 150, 200, 255))


def _chip(d):
    d.rectangle([7, 12, 17, 22], fill=(60, 70, 100, 255))
    for x in (8, 11, 14, 17):
        d.line([(x, 10), (x, 23)], fill=(200, 200, 220, 255))
    d.rectangle([7, 12, 17, 22], fill=(60, 70, 100, 255))
    d.point([(10, 16), (14, 16)], fill=(130, 255, 200, 255))


def _wifi(d, sway=0):
    c = (130, 255, 200, 255)
    for r in (3, 6, 9):
        d.arc([12 - r, 18 - r - sway, 12 + r, 18 + r - sway], 220, 320, fill=c,
              width=1)
    d.point((12, 18 - sway), fill=c)
    d.line([(12, 19), (12, 23)], fill=(150, 150, 180, 255))


def _floppy(d):
    d.rectangle([6, 12, 18, 23], fill=(110, 150, 255, 255))
    d.rectangle([9, 12, 15, 16], fill=(220, 220, 240, 255))
    d.rectangle([8, 19, 16, 23], fill=WHITE)


def _cable(d, sway=0):
    d.arc([4, 14 + sway, 14, 24 + sway], 180, 360, fill=(255, 150, 200, 255),
          width=2)
    d.arc([12, 14, 22, 24], 0, 180, fill=(255, 150, 200, 255), width=2)


def _bubble_sign(d, sway=0):
    d.rounded_rectangle([3, 4 + sway, 21, 15 + sway], 4, fill=WHITE)
    d.polygon([(7, 15 + sway), (11, 15 + sway), (6, 19 + sway)], fill=WHITE)
    for x in (8, 12, 16):
        d.point((x, 10 + sway), fill=PLUM)


PROPS = {
    'feed': [
        lambda d, s: _flower(d, 12, (255, 120, 150), sway=s),
        lambda d, s: _flower(d, 12, (255, 255, 255), h=7, sway=s),
        lambda d, s: _tuft(d, (90, 180, 90), s),
        lambda d, s: _bush(d, (110, 200, 110), s),
        lambda d, s: _mushroom(d, (255, 100, 110), s),
        lambda d, s: _rock(d, (190, 186, 210)),
        lambda d, s: _flower(d, 12, (255, 214, 90), (180, 110, 60), h=13,
                             sway=s),
        lambda d, s: _sign(d, PLUM, sway=0),
    ],
    'comments': [
        lambda d, s: _bubble_sign(d, s),
        lambda d, s: _flower(d, 12, (220, 160, 255), sway=s),
        lambda d, s: _crystal(d, (200, 160, 255)),
        lambda d, s: _tuft(d, (170, 120, 220), s),
        lambda d, s: _bush(d, (180, 140, 230), s),
        lambda d, s: _heart(d, 6, 10 + s, (255, 120, 170), 2),
        lambda d, s: _mushroom(d, (255, 170, 230), s, small=True),
        lambda d, s: _rock(d, (150, 130, 190)),
    ],
    'beach': [
        lambda d, s: _starfish(d, (255, 160, 120)),
        lambda d, s: _shell(d),
        lambda d, s: _palm(d, s),
        lambda d, s: _sandcastle(d),
        lambda d, s: _crab(d, s),
        lambda d, s: _ball(d),
        lambda d, s: _tuft(d, (120, 190, 120), s),
        lambda d, s: _starfish(d, (255, 214, 110)),
    ],
    'desert': [
        lambda d, s: _cactus(d, sway=s),
        lambda d, s: _cactus(d, round_=True),
        lambda d, s: _tuft(d, (200, 170, 90), s),
        lambda d, s: _rock(d, (220, 150, 110)),
        lambda d, s: _bone(d),
        lambda d, s: _pot(d),
        lambda d, s: _flower(d, 12, (255, 130, 180), (110, 190, 110), sway=s),
        lambda d, s: _sign(d, PLUM, board=(230, 170, 110)),
    ],
    'ice': [
        lambda d, s: _snowman(d, s),
        lambda d, s: _crystal(d, (170, 230, 255)),
        lambda d, s: _pine(d, s),
        lambda d, s: _penguin(d, s),
        lambda d, s: _snowpile(d),
        lambda d, s: _igloo(d),
        lambda d, s: _snowflake(d, s),
        lambda d, s: _rock(d, (200, 220, 240)),
    ],
    'candy': [
        lambda d, s: _lollipop(d, (255, 120, 170), s),
        lambda d, s: _cane(d),
        lambda d, s: _cupcake(d, s),
        lambda d, s: _gumdrop(d, (140, 220, 160)),
        lambda d, s: _donut(d),
        lambda d, s: _icecream(d, s),
        lambda d, s: _lollipop(d, (140, 200, 255), s),
        lambda d, s: _gumdrop(d, (255, 214, 110)),
    ],
    'forest': [
        lambda d, s: _mushroom(d, (255, 100, 110), s),
        lambda d, s: _mushroom(d, (200, 140, 100), s, small=True),
        lambda d, s: _fern(d, s),
        lambda d, s: _flower(d, 12, (140, 190, 255), sway=s),
        lambda d, s: _stump(d),
        lambda d, s: _acorn(d),
        lambda d, s: _snail(d, s),
        lambda d, s: _bush(d, (80, 160, 100), s),
    ],
    'volcano': [
        lambda d, s: _rock(d, (110, 70, 90)),
        lambda d, s: _crystal(d, (255, 110, 120)),
        lambda d, s: _flameflower(d, s),
        lambda d, s: _bone(d),
        lambda d, s: _vent(d, s),
        lambda d, s: _mushroom(d, (255, 150, 70), s),
        lambda d, s: _crystal(d, (255, 190, 90)),
        lambda d, s: _tuft(d, (200, 110, 80), s),
    ],
    'clouds': [
        lambda d, s: _star(d, (255, 230, 120), y=8 + s),
        lambda d, s: _puff(d, s),
        lambda d, s: _rainbow(d),
        lambda d, s: _feather(d, s),
        lambda d, s: _bell(d, s),
        lambda d, s: _heart(d, 6, 10 + s, (255, 170, 200), 2),
        lambda d, s: _flower(d, 12, (255, 220, 240), sway=s),
        lambda d, s: _star(d, (190, 220, 255), y=12 + s, s=0.7),
    ],
    'server': [
        lambda d, s: _rack(d, s),
        lambda d, s: _chip(d),
        lambda d, s: _wifi(d, s),
        lambda d, s: _floppy(d),
        lambda d, s: _cable(d, s),
        lambda d, s: _crystal(d, (130, 255, 200)),
        lambda d, s: _heart(d, 6, 10 + s, (255, 150, 200), 2),
        lambda d, s: _tuft(d, (110, 250, 190), s),
    ],
}


# Extra props from Kenney's "Pixel Platformer" packs (CC0, kenney.nl), kept
# at their native pixel size and re-outlined in our plum. (pack, tile, sways)
KENNEY_PROPS = {
    'feed': [('farm', 20, 1), ('farm', 57, 1), ('farm', 58, 1),
             ('base', 124, 1), ('base', 125, 1), ('base', 128, 0),
             ('base', 106, 0), ('base', 85, 0)],
    'forest': [('base', 126, 1), ('base', 128, 0), ('farm', 75, 1),
               ('farm', 73, 1), ('farm', 74, 1), ('base', 124, 1),
               ('base', 105, 0), ('farm', 54, 0)],
    'beach': [('food', 82, 0), ('food', 83, 0), ('farm', 104, 1),
              ('farm', 105, 1), ('farm', 54, 0), ('base', 84, 0),
              ('base', 124, 1), ('farm', 106, 1)],
    'desert': [('base', 127, 0), ('farm', 104, 1), ('farm', 105, 1),
               ('farm', 106, 1), ('farm', 107, 1), ('farm', 108, 0),
               ('farm', 109, 0), ('base', 85, 0)],
    'ice': [('base', 145, 0), ('base', 126, 1), ('base', 148, 0),
            ('base', 149, 0), ('base', 144, 1), ('base', 106, 0),
            ('base', 86, 0), ('base', 145, 0)],
    'candy': [('food', 13, 0), ('food', 14, 0), ('food', 15, 0),
              ('food', 25, 1), ('food', 43, 0), ('food', 107, 0),
              ('food', 108, 0), ('food', 8, 1)],
    'comments': [('food', 89, 0), ('food', 80, 1), ('food', 81, 1),
                 ('base', 84, 0), ('base', 85, 0), ('base', 86, 0),
                 ('food', 85, 0), ('food', 86, 0)],
    # Only low, clearly decorative things: crates and barrels would look
    # like solid obstacles you can't actually stand on.
    'volcano': [('farm', 105, 1), ('farm', 106, 1), ('ind', 42, 0),
                ('ind', 64, 0), ('base', 128, 0), ('farm', 104, 1),
                ('farm', 107, 1), ('base', 85, 0)],
    'clouds': [('base', 144, 1), ('base', 145, 0), ('food', 25, 1),
               ('food', 107, 0), ('food', 108, 0), ('food', 14, 0),
               ('base', 106, 0), ('base', 124, 1)],
    'server': [('ind', 42, 0), ('ind', 64, 0), ('ind', 65, 0),
               ('ind', 73, 0), ('food', 89, 0), ('food', 86, 0),
               ('base', 84, 0), ('food', 85, 0)],
}

_KENNEY_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'kenney')
_KENNEY_OUTLINE = (67, 74, 95)


def kenney_tile(pack: str, tile: int) -> Image.Image:
    """One 18x18 Kenney tile, with its slate outline turned plum."""
    ids = open(os.path.join(_KENNEY_DIR, f'{pack}.txt')).read().split()
    i = ids.index(str(tile))
    sheet = Image.open(os.path.join(_KENNEY_DIR, f'{pack}.png')).convert('RGBA')
    a = np.array(sheet.crop((i * 18, 0, i * 18 + 18, 18)))
    m = (a[:, :, 0] == _KENNEY_OUTLINE[0]) & (a[:, :, 1] == _KENNEY_OUTLINE[1]) \
        & (a[:, :, 2] == _KENNEY_OUTLINE[2]) & (a[:, :, 3] > 0)
    a[m] = PLUM
    return Image.fromarray(a)


def _kenney_frames(pack: str, tile: int, sways: int) -> list[Image.Image]:
    k = kenney_tile(pack, tile)
    frames = []
    for f in range(2):
        im = Image.new('RGBA', (T, T))
        im.alpha_composite(k, ((T - 18) // 2, T - 18))
        if f and sways:
            # Lean the top half one pixel, like the hand-drawn plants.
            a = np.array(im)
            a[:T // 2] = np.roll(a[:T // 2], 1, axis=1)
            im = Image.fromarray(a)
        frames.append(im)
    return frames


def props_sheet(theme: str) -> Image.Image:
    """16 props x 2 sway frames, 24x24 each, bottom aligned: 8 drawn here
    and 8 from Kenney's packs."""
    hand = PROPS[theme]
    kenney = KENNEY_PROPS[theme]
    sheet = Image.new('RGBA', (T * 2 * (len(hand) + len(kenney)), T))
    for i, draw in enumerate(hand):
        for f in range(2):
            im = Image.new('RGBA', (T, T + 8))
            d = ImageDraw.Draw(im)
            draw(d, f)
            im = outline(im.crop((0, 0, T, T)))
            sheet.alpha_composite(im, ((i * 2 + f) * T, 0))
    for j, (pack, tile, sways) in enumerate(kenney):
        for f, im in enumerate(_kenney_frames(pack, tile, sways)):
            sheet.alpha_composite(im, (((len(hand) + j) * 2 + f) * T, 0))
    return sheet


# ============================================================= mid parallax

def mid_layer(theme: str) -> Image.Image:
    th = THEMES[theme]
    W, H = 480, 120
    img = Image.new('RGBA', (W, H))
    d = ImageDraw.Draw(img)
    base = mix(th['hill'], th['top'], .35)
    dark = darken(base, .12)
    k = th['deco']
    rnd = np.random.default_rng(sum(map(ord, theme)) + 11)
    x = 10
    while x < W - 20:
        h = int(rnd.integers(48, 90))
        if k in ('flowers', 'mushrooms', 'bubbles'):
            # Round trees.
            d.rectangle([x + 14, H - h + 20, x + 20, H], fill=dark)
            d.ellipse([x, H - h, x + 34, H - h + 34], fill=base)
            d.ellipse([x + 6, H - h + 4, x + 14, H - h + 10],
                      fill=lighten(base, .25))
            w = 44
        elif k == 'shells':
            d.line([(x + 10, H), (x + 16, H - h)], fill=(170, 130, 100, 255),
                   width=4)
            for dx in (-14, 0, 14):
                d.ellipse([x + 16 + dx - 10, H - h - 6, x + 16 + dx + 10,
                           H - h + 4], fill=(110, 200, 140, 255))
            w = 60
        elif k == 'cacti':
            d.rounded_rectangle([x + 10, H - h, x + 22, H], 6,
                                fill=(120, 190, 120, 255))
            d.rounded_rectangle([x, H - h + 20, x + 8, H - h + 40], 4,
                                fill=(120, 190, 120, 255))
            d.rounded_rectangle([x + 24, H - h + 14, x + 32, H - h + 30], 4,
                                fill=(120, 190, 120, 255))
            w = 70
        elif k == 'snow':
            for i, (wd, y) in enumerate(((10, 0), (14, 14), (18, 28))):
                d.polygon([(x + 18, H - h + y), (x + 18 - wd, H - h + y + 18),
                           (x + 18 + wd, H - h + y + 18)],
                          fill=(110, 170, 160, 255))
                d.line([(x + 18 - wd + 2, H - h + y + 17),
                        (x + 18 + wd - 2, H - h + y + 17)], fill=WHITE, width=2)
            d.rectangle([x + 16, min(H, H - h + 46), x + 20, H], fill=(130, 100, 90, 255))
            w = 42
        elif k == 'sprinkles':
            d.line([(x + 14, H), (x + 14, H - h + 20)], fill=WHITE, width=3)
            col = [(255, 150, 200), (150, 210, 255), (255, 220, 120)][x % 3]
            d.ellipse([x, H - h, x + 28, H - h + 28], fill=rgba(col))
            d.arc([x + 4, H - h + 4, x + 24, H - h + 24], 0, 300, fill=WHITE,
                  width=2)
            w = 46
        elif k == 'embers':
            d.polygon([(x, H), (x + 16, H - h), (x + 34, H)], fill=dark)
            d.polygon([(x + 12, H - h + 10), (x + 16, H - h), (x + 20, H - h + 10)],
                      fill=(255, 150, 90, 255))
            w = 46
        elif k == 'stars':
            d.ellipse([x, H - h, x + 40, H - h + 26], fill=WHITE)
            d.ellipse([x + 10, H - h - 10, x + 30, H - h + 14], fill=WHITE)
            d.rectangle([x + 4, H - h + 14, x + 36, H], fill=(240, 236, 255, 255))
            w = 56
        else:  # server antennas
            d.rectangle([x + 10, H - h, x + 14, H], fill=dark)
            d.ellipse([x + 7, H - h - 4, x + 17, H - h + 6],
                      fill=(255, 150, 200, 255))
            d.rectangle([x, H - 30, x + 26, H], fill=base)
            w = 40
        x += w + int(rnd.integers(10, 50))
    return img


# =================================================================== effects

def dust() -> Image.Image:
    sheet = Image.new('RGBA', (8 * 3, 8))
    d = ImageDraw.Draw(sheet)
    for f, r in enumerate((3, 2, 1)):
        cx = f * 8 + 4
        d.ellipse([cx - r, 4 - r, cx + r, 4 + r], fill=(255, 255, 255, 220))
    return sheet


def power_block() -> Image.Image:
    """A rainbow-ish '!' block that gives a power-up."""
    img = Image.new('RGBA', (T, T))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, T - 1, T - 1], 4, fill=(190, 140, 255, 255),
                        outline=PLUM)
    for i, c in enumerate([(255, 140, 190), (255, 214, 110), (140, 230, 180),
                           (140, 200, 255)]):
        d.line([(3, 3 + i), (T - 4, 3 + i)], fill=c)
    d.rectangle([10, 8, 13, 15], fill=WHITE)
    d.rectangle([10, 17, 13, 19], fill=WHITE)
    d.line([(9, 8), (9, 15)], fill=PLUM)
    return img


def powerups() -> Image.Image:
    """16x16 fight items: sunglasses, stonks, pizza, coffee, bomb."""
    sheet = Image.new('RGBA', (16 * 5, 16))
    # Deal-with-it pixel sunglasses.
    im = Image.new('RGBA', (16, 16))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 5, 15, 6], fill=(30, 30, 40, 255))
    d.rectangle([1, 6, 6, 10], fill=(30, 30, 40, 255))
    d.rectangle([9, 6, 14, 10], fill=(30, 30, 40, 255))
    d.point([(2, 7), (3, 8), (10, 7), (11, 8)], fill=WHITE)
    sheet.alpha_composite(outline(im), (0, 0))
    # Stonks: green arrow over a mini chart.
    im = Image.new('RGBA', (16, 16))
    d = ImageDraw.Draw(im)
    d.rectangle([1, 2, 14, 13], fill=(240, 250, 255, 255))
    d.line([(2, 12), (6, 8), (9, 10), (13, 4)], fill=(60, 200, 110, 255), width=2)
    d.polygon([(10, 3), (14, 3), (14, 7)], fill=(60, 200, 110, 255))
    sheet.alpha_composite(outline(im), (16, 0))
    # Pizza slice.
    im = Image.new('RGBA', (16, 16))
    d = ImageDraw.Draw(im)
    d.polygon([(2, 3), (14, 3), (8, 14)], fill=(255, 214, 110, 255))
    d.rectangle([2, 2, 14, 4], fill=(220, 150, 80, 255))
    for x, y in ((6, 6), (10, 6), (8, 9)):
        d.ellipse([x - 1, y - 1, x + 1, y + 1], fill=(230, 80, 90, 255))
    sheet.alpha_composite(outline(im), (32, 0))
    # Coffee cup with steam.
    im = Image.new('RGBA', (16, 16))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([3, 6, 11, 14], 2, fill=WHITE)
    d.rectangle([4, 7, 10, 8], fill=(150, 90, 60, 255))
    d.arc([10, 8, 14, 12], 270, 90, fill=WHITE, width=2)
    d.point([(5, 3), (6, 2), (8, 4), (9, 3)], fill=(220, 220, 230, 255))
    d.point([(6, 11), (8, 11)], fill=PLUM)
    sheet.alpha_composite(outline(im), (48, 0))
    # Cartoon bomb with a lit fuse.
    im = Image.new('RGBA', (16, 16))
    d = ImageDraw.Draw(im)
    d.ellipse([2, 4, 13, 15], fill=(50, 44, 70, 255))
    d.ellipse([4, 6, 7, 9], fill=(120, 110, 150, 255))
    d.rectangle([7, 2, 9, 4], fill=(90, 80, 110, 255))
    d.line([(9, 2), (11, 0)], fill=(200, 160, 110, 255))
    d.point([(12, 0), (11, 1)], fill=(255, 210, 80, 255))
    d.point([(13, 1)], fill=(255, 120, 60, 255))
    sheet.alpha_composite(outline(im), (64, 0))
    return sheet


def sunglasses_overlay() -> Image.Image:
    """Bigger glasses drawn on the character's face (24x8)."""
    im = Image.new('RGBA', (24, 8))
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 23, 1], fill=(20, 20, 28, 255))
    d.rectangle([1, 1, 10, 6], fill=(20, 20, 28, 255))
    d.rectangle([13, 1, 22, 6], fill=(20, 20, 28, 255))
    d.point([(3, 2), (4, 3), (15, 2), (16, 3)], fill=WHITE)
    return im


# ======================================================================= hats

HAT_W, HAT_H = 24, 18


def _hat_party(d):
    d.polygon([(6, 17), (18, 17), (12, 2)], fill=(255, 130, 180, 255))
    for y in (7, 11, 15):
        w = (y - 2) * 6 // 15
        d.line([(12 - w, y), (12 + w, y)], fill=(255, 230, 120, 255))
    d.ellipse([10, 0, 14, 4], fill=(140, 220, 255, 255))


def _hat_crown(d):
    d.polygon([(3, 17), (3, 6), (7, 11), (12, 3), (17, 11), (21, 6), (21, 17)],
              fill=(255, 210, 80, 255))
    d.line([(4, 14), (20, 14)], fill=(230, 160, 40, 255))
    for x, c in ((7, (255, 90, 120)), (12, (120, 200, 255)), (17, (140, 230, 160))):
        d.ellipse([x - 1, 13, x + 1, 15], fill=c + (255,))
    d.point([(12, 3), (3, 6), (21, 6)], fill=WHITE)


def _hat_propeller(d):
    d.pieslice([3, 7, 21, 27], 180, 360, fill=(120, 200, 255, 255))
    d.pieslice([3, 7, 21, 27], 180, 225, fill=(255, 120, 150, 255))
    d.pieslice([3, 7, 21, 27], 270, 315, fill=(255, 220, 110, 255))
    d.line([(12, 7), (12, 3)], fill=PLUM)
    d.ellipse([4, 1, 11, 4], fill=(255, 110, 140, 255))
    d.ellipse([13, 1, 20, 4], fill=(140, 220, 160, 255))


def _hat_cap(d):
    d.pieslice([4, 6, 20, 26], 180, 360, fill=(240, 80, 100, 255))
    d.rounded_rectangle([12, 14, 23, 17], 2, fill=(200, 50, 80, 255))
    d.point((12, 7), fill=WHITE)
    d.line([(8, 10), (11, 9)], fill=(255, 150, 160, 255))


def _hat_bow(d):
    d.polygon([(12, 12), (3, 6), (3, 17)], fill=(255, 130, 190, 255))
    d.polygon([(12, 12), (21, 6), (21, 17)], fill=(255, 130, 190, 255))
    d.ellipse([9, 9, 15, 15], fill=(255, 90, 160, 255))
    d.point([(5, 9), (19, 9)], fill=WHITE)


def _hat_halo(d):
    d.ellipse([3, 4, 21, 11], outline=(255, 230, 110, 255), width=2)
    d.point([(6, 5), (17, 5)], fill=WHITE)


def _hat_chef(d):
    d.rectangle([6, 11, 18, 17], fill=WHITE)
    for x in (4, 9, 14):
        d.ellipse([x, 2, x + 8, 12], fill=WHITE)
    d.line([(6, 13), (18, 13)], fill=(220, 220, 235, 255))


def _hat_witch(d):
    d.rounded_rectangle([1, 14, 23, 17], 2, fill=(130, 80, 180, 255))
    d.polygon([(6, 15), (18, 15), (15, 1), (19, 0)], fill=(150, 100, 210, 255))
    d.line([(7, 13), (17, 13)], fill=(255, 210, 90, 255), width=2)


def _hat_cowboy(d):
    d.rounded_rectangle([0, 13, 23, 17], 2, fill=(170, 110, 70, 255))
    d.rounded_rectangle([6, 4, 18, 15], 3, fill=(190, 130, 80, 255))
    d.line([(6, 12), (18, 12)], fill=(120, 70, 50, 255), width=2)
    d.line([(12, 4), (12, 7)], fill=(150, 100, 60, 255))


def _hat_flowers(d):
    d.line([(2, 15), (22, 15)], fill=(110, 190, 110, 255), width=2)
    for x, c in ((4, (255, 130, 180)), (9, (255, 230, 110)), (14, (160, 200, 255)),
                 (19, (255, 160, 120))):
        for dx, dy in ((-2, 0), (2, 0), (0, -2), (0, 2)):
            d.ellipse([x + dx - 1, 12 + dy - 1, x + dx + 1, 12 + dy + 1],
                      fill=c + (255,))
        d.point((x, 12), fill=(255, 250, 220, 255))


def _hat_tophat(d):
    d.rounded_rectangle([2, 14, 22, 17], 1, fill=(40, 34, 48, 255))
    d.rectangle([6, 1, 18, 15], fill=(52, 44, 62, 255))
    d.rectangle([6, 10, 18, 12], fill=(220, 60, 90, 255))
    d.line([(8, 2), (8, 8)], fill=(90, 80, 104, 255))


def _hat_viking(d):
    d.pieslice([4, 5, 20, 27], 180, 360, fill=(170, 176, 190, 255))
    d.line([(4, 15), (20, 15)], fill=(200, 150, 60, 255), width=2)
    d.line([(12, 5), (12, 14)], fill=(200, 150, 60, 255))
    for sx in (1, -1):
        x0 = 12 + sx * 8
        d.polygon([(x0, 12), (x0 + sx * 3, 9), (x0 + sx * 4, 2),
                   (x0 + sx * 1, 8)], fill=(250, 240, 214, 255))
    d.point((8, 8), fill=WHITE)


def _hat_pirate(d):
    d.polygon([(0, 15), (4, 8), (12, 4), (20, 8), (23, 15), (12, 12)],
              fill=(44, 38, 52, 255))
    d.line([(1, 15), (12, 12), (22, 15)], fill=(230, 190, 80, 255))
    d.ellipse([10, 6, 14, 10], fill=WHITE)
    d.point([(11, 7), (13, 7)], fill=(44, 38, 52, 255))


def _hat_beanie(d):
    d.pieslice([4, 5, 20, 25], 180, 360, fill=(120, 200, 170, 255))
    d.rectangle([4, 13, 20, 17], fill=(90, 170, 140, 255))
    for x in range(5, 20, 3):
        d.line([(x, 13), (x, 17)], fill=(70, 140, 115, 255))
    d.ellipse([9, 0, 15, 6], fill=(255, 240, 245, 255))
    d.point((10, 1), fill=WHITE)


def _hat_frog(d):
    d.pieslice([3, 6, 21, 28], 180, 360, fill=(120, 210, 110, 255))
    for x in (4, 14):
        d.ellipse([x, 2, x + 6, 8], fill=(120, 210, 110, 255))
        d.ellipse([x + 1, 3, x + 5, 7], fill=WHITE)
        d.rectangle([x + 2, 4, x + 3, 6], fill=(30, 26, 36, 255))
    d.point([(8, 14), (16, 14)], fill=(255, 150, 170, 255))


def _hat_mushroom(d):
    d.pieslice([1, 3, 23, 29], 180, 360, fill=(240, 70, 80, 255))
    d.rectangle([1, 15, 23, 17], fill=(255, 236, 214, 255))
    for x, y, r in ((6, 8, 2), (12, 5, 2), (18, 9, 2), (12, 12, 1)):
        d.ellipse([x - r, y - r, x + r, y + r], fill=WHITE)


HATS = [_hat_party, _hat_crown, _hat_propeller, _hat_cap, _hat_bow, _hat_halo,
        _hat_chef, _hat_witch, _hat_cowboy, _hat_flowers, _hat_tophat,
        _hat_viking, _hat_pirate, _hat_beanie, _hat_frog, _hat_mushroom]


def hats_sheet() -> Image.Image:
    sheet = Image.new('RGBA', (HAT_W * len(HATS), HAT_H))
    for i, draw in enumerate(HATS):
        im = Image.new('RGBA', (HAT_W, HAT_H))
        draw(ImageDraw.Draw(im))
        sheet.alpha_composite(outline(im), (i * HAT_W, 0))
    return sheet

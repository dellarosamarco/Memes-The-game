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
    'pigtail_dog': ((160, 7, 500, 556), 50, 1.0,
                    dict(colors=18, sat=1.2, contrast=1.15, levels=(0, 250),
                         legs=dict(color=(58, 40, 30), socks=(244, 244, 240),
                                   shoes=(22, 20, 26)))),
    'pearl_terrier': ((0, 0, 538, 660), 50, 0.62,
                      dict(colors=18, sat=1.15, contrast=1.15,
                           levels=(0, 255),
                           legs=dict(color=(236, 230, 226)))),
    'suit_dachshund': ((95, 20, 645, 452), 42, 1.0,
                       dict(colors=18, sat=1.15, contrast=1.15,
                            levels=(0, 245),
                            legs=dict(color=(26, 26, 32),
                                      shoes=(214, 40, 34), crocs=True))),
    'cheeks_dachshund': ((60, 30, 610, 610), 48, 0.6,
                         dict(colors=18, sat=1.15, contrast=1.15,
                              levels=(0, 245))),
    'snow_baby': ((0, 0, 341, 410), 48, 1.0,
                  dict(colors=20, sat=1.25, contrast=1.3, levels=(0, 255),
                       legs=dict(color=(196, 170, 214)))),
    'pink_monkey': ((125, 40, 592, 542), 46, 0.75,
                    dict(colors=20, sat=1.2, contrast=1.2, levels=(0, 230),
                         gamma=0.75, legs=dict(color=(70, 46, 36)))),
    'shrek_kid': ((0, 0, 690, 678), 48, 1.0,
                  dict(colors=18, sat=1.25, contrast=1.15, levels=(0, 255),
                       legs=dict(color=(34, 40, 92), shoes=(22, 20, 26)))),
    'ears_dog': ((20, 0, 640, 560), 46, 0.62,
                 dict(colors=20, sat=1.2, contrast=1.2, levels=(0, 250))),
    'rock_monkey': ((0, 0, 607, 700), 50, 1.0,
                    dict(colors=20, sat=1.2, contrast=1.15, levels=(0, 250),
                         legs=dict(color=(110, 62, 30)))),
    # Same monkey with an empty hand (shown while the rock is flying).
    'rock_monkey_empty': ((0, 0, 607, 700), 50, 1.0,
                          dict(colors=20, sat=1.2, contrast=1.15,
                               levels=(0, 250),
                               legs=dict(color=(110, 62, 30)))),
    'chill_dog': ((0, 0, 700, 430), 37, 0.8,
                  dict(colors=18, sat=1.15, contrast=1.15, levels=(0, 250),
                       legs=dict(color=(214, 180, 140)))),
    'drip_pig': ((0, 0, 566, 700), 50, 0.62,
                 dict(colors=20, sat=1.4, contrast=1.2, levels=(0, 245),
                      legs=dict(color=(214, 160, 150)))),
    'bowl_chick': ((0, 0, 700, 574), 44, 1.0,
                   dict(colors=18, sat=1.2, contrast=1.15, levels=(0, 255),
                        legs=dict(color=(240, 150, 40)))),
    'helmet_pigeon': ((0, 0, 306, 303), 48, 0.62,
                      dict(colors=18, sat=1.2, contrast=1.15, levels=(0, 250),
                           legs=dict(color=(206, 112, 112)))),
    'pietro_pigeon': ((0, 0, 250, 290), 48, 1.0,
                      dict(colors=16, sat=1.0, contrast=1.25, levels=(20, 240),
                           legs=dict(color=(44, 44, 50),
                                     shoes=(240, 240, 234)))),
    'bike_dog': ((0, 0, 340, 262), 38, 1.0,
                 dict(colors=18, sat=1.25, contrast=1.2, levels=(0, 245),
                      bike=True)),
    'sneaker_hen': ((0, 0, 330, 280), 40, 1.0,
                    dict(colors=20, sat=1.2, contrast=1.15, levels=(0, 250),
                         legs=dict(color=(240, 170, 60), dunks=True,
                                   shoes=(26, 26, 30)))),
    'gta_bean': ((0, 0, 624, 700), 50, 0.7,
                 dict(colors=20, sat=1.15, contrast=1.15, levels=(0, 250),
                      legs=dict(color=(92, 62, 44), shoes=(26, 22, 22)))),
    'masha_man': ((0, 0, 640, 638), 50, 0.8,
                  dict(colors=20, sat=1.15, contrast=1.15, levels=(0, 250),
                       legs=dict(color=(226, 182, 150),
                                 shoes=(196, 40, 150)))),
    'rock_patrick': ((200, 0, 683, 683), 50, 0.75,
                     dict(colors=18, sat=1.15, contrast=1.15, levels=(0, 255),
                          legs=dict(color=(240, 140, 130)))),
    'bottle_patrick': ((0, 60, 487, 700), 52, 0.75,
                       dict(colors=18, sat=1.0, contrast=1.15, levels=(0, 255),
                            legs=dict(color=(240, 140, 130)))),
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
    if 'whites' in t:
        # Tiny bright details (teeth, pearls) vanish when downscaled, so
        # they are fattened up first.
        thr, k = t['whites']
        w = rgb.convert('L').point(lambda v: 255 if v > thr else 0)
        rgb.paste((250, 248, 244), mask=w.filter(ImageFilter.MaxFilter(k)))
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


def pearls(d: ImageDraw.ImageDraw, cx: int, y: int, half: int):
    """The terrier's pearl necklace (a U of shiny beads)."""
    for dx in range(-half, half + 1, 3):
        dy = round(5 * (1 - (dx / half) ** 2))
        x = cx + dx - 1
        d.rectangle([x, y + dy, x + 1, y + dy + 1], fill=(176, 170, 186, 255))
        d.point([(x, y + dy)], fill=(255, 255, 255, 255))


def grin(d: ImageDraw.ImageDraw, x0: int, x1: int, y: int):
    """The human-teeth grin (teeth are too small to survive the downscale)."""
    mid = (x0 + x1) / 2
    for x in range(x0, x1 + 1):
        lift = 1 if abs(x - mid) > (x1 - x0) * 0.36 else 0
        top = y - lift
        d.point([(x, top - 1)], fill=(60, 26, 30, 255))
        tooth = (250, 250, 244, 255) if (x - x0) % 3 else (206, 204, 200, 255)
        d.rectangle([x, top, x, top + 2], fill=tooth)
        d.point([(x, top + 3)], fill=(206, 96, 112, 255))


def bicycle(d: ImageDraw.ImageDraw, top: int, frame: int):
    """The bike dog's little bicycle (wheels spin with the frame)."""
    metal, tyre = (196, 204, 212, 255), (40, 38, 46, 255)
    y = FH - 8
    for cx in (FW // 2 - 13, FW // 2 + 13):
        d.ellipse([cx - 6, y - 6, cx + 6, y + 6], outline=tyre, width=2)
        a = frame * 0.8 + (0 if cx < FW // 2 else 0.4)
        dx, dy = round(4 * np.cos(a)), round(4 * np.sin(a))
        d.line([(cx - dx, y - dy), (cx + dx, y + dy)], fill=metal)
        d.line([(cx + dy, y - dx), (cx - dy, y + dx)], fill=metal)
    d.line([(FW // 2 - 13, y), (FW // 2, y - 2), (FW // 2 + 13, y)],
           fill=metal, width=2)
    d.line([(FW // 2, y - 2), (FW // 2 - 3, top)], fill=metal, width=2)
    d.line([(FW // 2 + 13, y), (FW // 2 + 11, top - 2)], fill=metal, width=2)


def googly(d: ImageDraw.ImageDraw, cx: int, cy: int):
    """A big cartoon eye (Patrick's eyes are too small once downscaled)."""
    d.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=(250, 250, 244, 255),
              outline=(40, 30, 40, 255))
    d.rectangle([cx, cy - 1, cx + 1, cy], fill=(20, 16, 24, 255))


def chain(d: ImageDraw.ImageDraw, cx: int, y: int, half: int):
    """The pig's thick gold chain."""
    for dx in range(-half, half + 1):
        dy = round(5 * (1 - (dx / half) ** 2))
        gold = (255, 214, 64, 255) if dx % 2 else (196, 140, 24, 255)
        d.rectangle([cx + dx, y + dy, cx + dx, y + dy + 1], fill=gold)
    for dx in range(-half + 1, half, 4):
        dy = round(5 * (1 - (dx / half) ** 2))
        d.point([(cx + dx, y + dy)], fill=(255, 250, 200, 255))


def accessories(name, d, x, y, w, h):
    """Redrawn signature details, relative to the figure's box."""
    if name == 'ears_dog':
        grin(d, x + round(w * 0.37), x + round(w * 0.62), y + round(h * 0.74))
    if name == 'bottle_patrick':
        for ex in (0.29, 0.42):
            googly(d, x + round(w * ex), y + round(h * 0.48))
    if name == 'drip_pig':
        chain(d, x + w // 2, y + round(h * 0.78), round(w * 0.42))
    if name == 'pearl_terrier':
        pearls(d, x + w // 2, y + round(h * 0.66), round(w * 0.36))


def character_strip(name: str) -> Image.Image:
    fig = pixel_figure(name)
    legs = FIGURES[name][3].get('legs', {})
    col = legs['color'] + (255,) if 'color' in legs else leg_color(fig)
    socks = legs['socks'] + (255,) if 'socks' in legs else None
    shoes = legs['shoes'] + (255,) if 'shoes' in legs else shade(col, 0.75)
    strip = Image.new('RGBA', (FW * len(FRAMES), FH))
    for i, frame in enumerate(FRAMES):
        im = Image.new('RGBA', (FW, FH))
        d = ImageDraw.Draw(im)
        bob = 1 if frame in ('idle1', 'run1', 'run3') else 0
        fx = FW // 2 - fig.width // 2
        fy = FH - 8 - fig.height + 3 + bob - (2 if frame == 'jump' else 0)
        lift = LEG_LIFT.get(frame, (0, 0))
        shift = LEG_SHIFT.get(frame, (0, 0))
        if FIGURES[name][3].get('bike'):
            fy -= 7
            bicycle(d, fy + fig.height - 4, i)
            im.alpha_composite(fig, (fx, fy))
            strip.alpha_composite(outline(im), (i * FW, 0))
            continue
        for k, lx in enumerate([FW // 2 - 9, FW // 2 + 4]):
            x = lx + shift[k]
            bottom = FH - 2 - lift[k]
            d.rectangle([x, fy + fig.height - 6, x + 4, bottom], fill=col)
            if socks:
                d.rectangle([x, bottom - 3, x + 4, bottom - 2], fill=socks)
            if legs.get('dunks'):  # Nike Dunk "panda"
                d.rectangle([x - 1, bottom - 3, x + 6, bottom],
                            fill=(244, 244, 240, 255))
                d.rectangle([x + 1, bottom - 2, x + 4, bottom - 2], fill=shoes)
                d.rectangle([x + 4, bottom - 3, x + 6, bottom - 1], fill=shoes)
            elif legs.get('crocs'):  # Lightning McQueen crocs
                d.rectangle([x - 1, bottom - 2, x + 5, bottom], fill=shoes)
                d.point([(x + 4, bottom - 2)], fill=(255, 255, 255, 255))
                d.point([(x, bottom - 1)], fill=(255, 214, 64, 255))
            elif 'shoes' in legs:  # real shoes: a bit wider, toe forward
                d.rectangle([x, bottom - 1, x + 5, bottom], fill=shoes)
            else:
                d.rectangle([x, bottom - 1, x + 4, bottom], fill=shoes)
        im.alpha_composite(fig, (fx, fy))
        accessories(name, ImageDraw.Draw(im), fx, fy, fig.width, fig.height)
        if name == 'robber_dog':
            knife(ImageDraw.Draw(im), fx + fig.width - 9, fy + fig.height - 12)
        strip.alpha_composite(outline(im), (i * FW, 0))
    return strip


def portrait(name: str) -> Image.Image:
    """Bigger pixel portrait for menus (same technique, more pixels)."""
    big = pixel_figure(name, height=FIGURES[name][1] * 2)
    small = pixel_figure(name)
    layer = Image.new('RGBA', small.size)
    accessories(name, ImageDraw.Draw(layer), 0, 0, small.width, small.height)
    big.alpha_composite(layer.resize(big.size, Image.NEAREST))
    return outline(big)


def main():
    os.makedirs(OUT, exist_ok=True)
    for name in FIGURES:
        character_strip(name).save(os.path.join(OUT, f'{name}.png'))
        portrait(name).save(os.path.join(OUT, f'{name}_portrait.png'))
    pixel_world.write_all(OUT)
    print('sprites written to', OUT)


if __name__ == '__main__':
    main()

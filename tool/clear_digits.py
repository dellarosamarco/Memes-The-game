#!/usr/bin/env python3
"""Redraws the digits of Pixelify Sans that read badly at small sizes.

In the original font "2" and "5" look like "S" and "6" like "8" once the
text is small on a phone. This swaps them for plainer 5x7 pixel shapes.
Run once on the original fonts (it rewrites them in place):

  python3 tool/clear_digits.py assets/fonts/PixelifySans-400.ttf ...
"""
import sys

from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont

SHAPES = {
    'two': [
        '.###.',
        '#...#',
        '....#',
        '...#.',
        '..#..',
        '.#...',
        '#####',
    ],
    'five': [
        '#####',
        '#....',
        '####.',
        '....#',
        '....#',
        '#...#',
        '.###.',
    ],
    'six': [
        '..##.',
        '.#...',
        '#....',
        '####.',
        '#...#',
        '#...#',
        '.###.',
    ],
}


def main(path):
    font = TTFont(path)
    glyf = font['glyf']
    gs = font.getGlyphSet()
    # The frame of "0": its outer box and the thickness of its strokes.
    zero = glyf['zero']
    zero.recalcBounds(glyf)
    left, bottom, right, top = zero.xMin, zero.yMin, zero.xMax, zero.yMax
    coords, ends, _ = zero.getCoordinates(glyf)
    inner = coords[ends[0] + 1:]
    sx = min(x for x, _ in inner) - left
    sy = min(y for _, y in inner) - bottom
    cw, ch = (right - left) / 5, (top - bottom) / 7
    for name, rows in SHAPES.items():
        pen = TTGlyphPen(gs)
        for r, row in enumerate(rows):
            for c, px in enumerate(row):
                if px != '#':
                    continue
                # Cells are as thick as the font's strokes (bold is chunky).
                w, h = max(cw, sx), max(ch, sy)
                x0 = left + c * cw
                y1 = top - r * ch
                x0 = min(x0, right - w)
                y0 = max(y1 - h, bottom)
                y1 = y0 + h
                pts = [(x0, y0), (x0, y1), (x0 + w, y1), (x0 + w, y0)]
                pen.moveTo(tuple(map(round, pts[0])))
                for p in pts[1:]:
                    pen.lineTo(tuple(map(round, p)))
                pen.closePath()
        glyf[name] = pen.glyph()
        width, _ = font['hmtx'][name]
        glyf[name].recalcBounds(glyf)
        font['hmtx'][name] = (width, glyf[name].xMin)
    font.save(path)


if __name__ == '__main__':
    for p in sys.argv[1:]:
        main(p)

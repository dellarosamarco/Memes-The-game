#!/usr/bin/env python3
"""Cuts the CJK fonts down to the characters the translations use.

The full fonts (OFL, from Google Fonts) are 2-10 MB each; the game only
needs the few hundred characters of its Japanese, Korean and Chinese
texts. Run again after changing those translations.

Usage: python3 tool/subset_cjk_fonts.py DIR_WITH_FULL_FONTS
  (DotGothic16.ttf, NotoSansKR.ttf, NotoSansSC.ttf)
"""
import os
import sys

from fontTools import subset

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTS = {
    'DotGothic16': ['ja'],
    'NotoSansKR': ['ko'],
    'NotoSansSC': ['zh', 'ja'],
}
# Language names in the picker, shown in every language.
EXTRA = '日本語한국어中文Українська'


def used_chars(code: str) -> set:
    path = os.path.join(ROOT, 'lib', 'l10n', f'tr_{code}.dart')
    return set(open(path, encoding='utf-8').read())


def main(src: str):
    for font, codes in FONTS.items():
        chars = set(EXTRA)
        for c in codes:
            chars |= used_chars(c)
        # Basic Latin and punctuation too, so mixed lines stay consistent.
        chars |= {chr(c) for c in range(0x20, 0x7F)}
        chars |= {chr(c) for c in range(0x3000, 0x3100)}  # CJK punctuation, kana
        chars |= {chr(c) for c in range(0xFF00, 0xFFF0)}  # full-width forms
        opts = subset.Options()
        opts.layout_features = ['*']
        opts.name_IDs = ['*']
        font_obj = subset.load_font(os.path.join(src, f'{font}.ttf'), opts)
        sub = subset.Subsetter(opts)
        sub.populate(unicodes=[ord(c) for c in chars])
        sub.subset(font_obj)
        out = os.path.join(ROOT, 'assets', 'fonts', f'{font}-subset.ttf')
        subset.save_font(font_obj, out, opts)
        print(font, len(chars), 'chars ->', os.path.getsize(out) // 1024, 'KB')


if __name__ == '__main__':
    main(sys.argv[1])

#!/usr/bin/env python3
"""Builds lib/l10n/source_it.json: every translatable Italian text by key.

Texts in the code are written as tr('key', 'Testo italiano'); the meme,
hat, trophy and arena data come from test/l10n_source_test.dart (run with
`flutter test test/l10n_source_test.dart`, which writes build/l10n_data.json).

Usage: python3 tool/extract_strings.py
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def dart_string(lit: str) -> str:
    """The value of one Dart string literal (no interpolation used here)."""
    body = lit[1:-1]
    out, i = [], 0
    while i < len(body):
        c = body[i]
        if c == '\\':
            n = body[i + 1]
            out.append({'n': '\n', 't': '\t'}.get(n, n))
            i += 2
        else:
            out.append(c)
            i += 1
    return ''.join(out)


def literal_end(s: str, i: int) -> int:
    q = s[i]
    j = i + 1
    while s[j] != q:
        j += 2 if s[j] == '\\' else 1
    return j + 1


def code_strings() -> dict:
    found = {}
    for root, _, files in os.walk(os.path.join(ROOT, 'lib')):
        for f in files:
            if not f.endswith('.dart') or root.endswith('l10n'):
                continue
            s = open(os.path.join(root, f), encoding='utf-8').read()
            for m in re.finditer(r"\btr\(\s*'([\w.]+)',\s*", s):
                key, i, parts = m.group(1), m.end(), []
                while i < len(s) and s[i] in '\'"':
                    j = literal_end(s, i)
                    parts.append(dart_string(s[i:j]))
                    i = j
                    while s[i] in ' \n\t':
                        i += 1
                if not parts:
                    continue  # key built at runtime (models: see data file)
                text = ''.join(parts)
                if key in found and found[key] != text:
                    raise SystemExit(f'key {key} used with two texts')
                found[key] = text
    return found


def main():
    texts = code_strings()
    data = os.path.join(ROOT, 'build', 'l10n_data.json')
    texts.update(json.load(open(data, encoding='utf-8')))
    out = os.path.join(ROOT, 'lib', 'l10n', 'source_it.json')
    json.dump(dict(sorted(texts.items())), open(out, 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)
    print(len(texts), 'texts ->', out)


if __name__ == '__main__':
    main()

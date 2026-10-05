#!/usr/bin/env python3
"""Builds lib/game/levels.dart from a tiny level-construction DSL.

Jump reach: ~4 tiles up, ~4 tiles across. Keep gaps <= 3 and platforms
<= 3 tiles above the surface you jump from.
"""
import os

ROWS = 14
GROUND = 12  # top row of the ground


class L:
    def __init__(self, cols):
        self.cols = cols
        self.g = [[' '] * cols for _ in range(ROWS)]

    def put(self, c, r, ch):
        self.g[r][c] = ch

    def ground(self, c0, c1, top=GROUND):
        for c in range(c0, c1 + 1):
            for r in range(top, ROWS):
                self.g[r][c] = '#'

    def row(self, c0, c1, r, ch):
        for c in range(c0, c1 + 1):
            self.g[r][c] = ch

    def col(self, c, r0, r1, ch):
        for r in range(r0, r1 + 1):
            self.g[r][c] = ch

    def likes(self, c0, c1, r):
        self.row(c0, c1, r, 'o')

    def stairs(self, c0, height, top=GROUND, down=False):
        for i in range(height):
            c = c0 + (height - 1 - i if down else i)
            self.col(c, top - 1 - i, top - 1, 'B')

    def text(self):
        return '\n'.join(''.join(r) for r in self.g)


def level1():
    l = L(140)
    l.put(2, 11, 'P')
    l.ground(0, 30)
    l.likes(6, 8, 11)
    l.put(11, 8, '?'); l.put(12, 8, 'B'); l.put(13, 8, '?'); l.put(14, 8, 'B')
    l.likes(12, 13, 7)
    l.put(20, 11, 'n')
    l.likes(24, 26, 10)
    # gap 31-33
    l.ground(34, 56)
    l.row(38, 42, 9, '='); l.likes(39, 41, 8)
    l.put(46, 11, 'n'); l.put(53, 11, 'c')
    l.stairs(57, 3)  # 57..59, up to row 9
    l.ground(57, 59)
    # pit 60-62
    l.ground(63, 86)
    l.put(65, 11, 'K')
    l.put(73, 11, 'n'); l.put(80, 11, 'n')
    l.put(75, 8, '?'); l.put(76, 8, 'B'); l.put(77, 8, '?')
    l.likes(82, 84, 11)
    # pit 87-97 with floating platforms
    l.row(89, 91, 10, '='); l.likes(89, 91, 9)
    l.row(94, 96, 9, '='); l.likes(94, 96, 8)
    l.ground(98, 139)
    l.put(104, 11, 'c'); l.put(110, 11, 'n')
    l.row(106, 109, 8, 'B'); l.put(107, 8, '?'); l.likes(106, 109, 7)
    l.stairs(118, 4)
    l.ground(118, 121)
    l.row(122, 125, 8, 'B')
    l.likes(122, 125, 7)
    l.put(132, 11, 'F')
    return l


def level2():
    l = L(160)
    l.put(2, 11, 'P')
    l.ground(0, 24)
    l.put(9, 11, 'h')
    l.row(12, 15, 9, '='); l.likes(12, 15, 8)
    l.put(18, 11, '^'); l.put(19, 11, '^')
    l.put(22, 11, 'b')
    # gap 25-27
    l.ground(28, 50)
    l.put(31, 8, '?'); l.put(32, 8, '?'); l.put(33, 8, '?')
    l.put(36, 11, 'n'); l.put(40, 11, 'h')
    l.row(42, 44, 11, '^')
    l.row(41, 45, 8, '='); l.likes(41, 45, 7)
    l.put(48, 11, 'c')
    # gap 51-53
    l.ground(54, 60, top=10)
    l.likes(55, 59, 9)
    # gap 61-63
    l.ground(64, 90)
    l.put(66, 11, 'K')
    l.put(72, 11, 'b'); l.put(78, 11, 'h')
    l.row(74, 77, 8, 'B'); l.put(75, 8, '?'); l.put(76, 8, '?')
    l.row(80, 83, 11, '^')
    l.row(80, 83, 8, '='); l.likes(80, 83, 7)
    l.put(87, 11, 'c')
    # tall section with one-way ladder
    l.ground(91, 92, top=9)
    l.row(94, 97, 7, '='); l.likes(94, 97, 6)
    l.row(99, 102, 9, '=')
    l.put(100, 8, 'n')
    l.ground(104, 125)
    l.row(107, 109, 11, '^')
    l.put(110, 11, 'h'); l.put(116, 11, 'b'); l.put(120, 11, 'n')
    l.row(112, 114, 8, '='); l.likes(112, 114, 7)
    l.put(124, 8, '?')
    # gap 126-128
    l.ground(129, 159)
    l.put(131, 11, 'K')
    l.put(136, 11, 'c'); l.put(140, 11, 'h')
    l.stairs(144, 4)
    l.ground(144, 147)
    l.likes(148, 151, 7)
    l.put(154, 11, 'F')
    return l


def level3():
    l = L(170)
    l.put(2, 11, 'P')
    l.ground(0, 20)
    l.put(8, 11, 'n'); l.put(12, 11, 'c'); l.put(16, 11, 'h')
    l.row(10, 13, 8, '='); l.likes(10, 13, 7)
    # gap 21-23 with spikes floor
    l.ground(24, 30, top=11)
    l.row(26, 27, 10, '^')
    # gap 31-33
    l.ground(34, 60)
    l.put(37, 11, 'b'); l.put(44, 11, 'h'); l.put(50, 11, 'b')
    l.row(40, 43, 8, 'B'); l.put(41, 8, '?'); l.put(42, 8, '?')
    l.row(46, 48, 11, '^')
    l.row(46, 48, 8, '='); l.likes(46, 48, 7)
    l.put(56, 11, 'K')
    # floating platforms over a long pit 61-79
    l.row(63, 65, 10, '='); l.likes(63, 65, 9)
    l.row(68, 70, 8, '='); l.put(69, 7, 'c')
    l.row(73, 75, 9, '='); l.likes(73, 75, 8)
    l.row(77, 78, 10, '=')
    l.ground(80, 110)
    l.put(84, 11, 'h'); l.put(90, 11, 'n'); l.put(95, 11, 'b'); l.put(100, 11, 'h')
    l.row(86, 89, 8, '='); l.likes(86, 89, 7)
    l.row(92, 94, 11, '^')
    l.put(104, 8, '?'); l.put(105, 8, '?')
    l.put(108, 11, 'K')
    # Boss arena 111-150, gate at 151.
    l.ground(111, 169)
    l.row(116, 119, 8, '=')
    l.row(140, 143, 8, '=')
    l.row(127, 132, 6, '=')
    l.put(135, 11, 'A')
    l.col(151, 0, 11, 'G')
    l.likes(155, 160, 10)
    l.put(164, 11, 'F')
    return l


LEVELS = [
    ('feed', 'Il Feed', 'Scrolla verso il successo', 'feed', 120, level1),
    ('comments', 'Sezione Commenti', 'Attenti agli Hater', 'comments', 150,
     level2),
    ('server', 'Il Server', "Sconfiggi L\\'Algoritmo", 'server', 180, level3),
]


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = ["// GENERATED by tool/build_levels.py — edit that file instead.",
           "", "import 'level.dart';", "",
           "final List<LevelData> kLevels = ["]
    for lid, name, sub, theme, par, fn in LEVELS:
        text = fn().text()
        out.append('  LevelData(')
        out.append(f"    id: '{lid}',")
        out.append(f"    name: '{name}',")
        out.append(f"    subtitle: '{sub}',")
        out.append(f'    theme: LevelTheme.{theme},')
        out.append(f'    parTime: {par},')
        out.append("    map: '''")
        out.append(text)
        out.append("''',")
        out.append('  ),')
    out.append('];')
    with open(os.path.join(root, 'lib', 'game', 'levels.dart'), 'w') as f:
        f.write('\n'.join(out) + '\n')
    for lid, *_, fn in LEVELS:
        print(lid)
        print(fn().text())


if __name__ == '__main__':
    main()

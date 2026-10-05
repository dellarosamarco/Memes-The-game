#!/usr/bin/env python3
"""Generates the game's cute chiptune sound effects and music loops.

Everything is synthesized from scratch (square/triangle waves + noise), so
there are no third-party audio assets. Output: assets/audio/*.wav

Usage: python3 tool/generate_audio.py   (needs numpy)
"""
from __future__ import annotations

import os
import wave

import numpy as np

SR = 22050
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'assets', 'audio')

NOTE_NAMES = {'C': 0, 'C#': 1, 'D': 2, 'D#': 3, 'E': 4, 'F': 5, 'F#': 6,
              'G': 7, 'G#': 8, 'A': 9, 'A#': 10, 'B': 11}


def hz(note: str) -> float:
    """'A4' -> 440.0"""
    name, octave = note[:-1], int(note[-1])
    n = NOTE_NAMES[name] + (octave + 1) * 12
    return 440.0 * 2 ** ((n - 69) / 12)


# ---------------------------------------------------------------- oscillators

def _phase(freq, dur):
    f = np.broadcast_to(np.asarray(freq, dtype=float), (int(SR * dur),))
    return np.cumsum(f) / SR


def square(freq, dur, duty=0.5):
    ph = _phase(freq, dur) % 1.0
    return np.where(ph < duty, 1.0, -1.0)


def triangle(freq, dur):
    ph = _phase(freq, dur) % 1.0
    return 4 * np.abs(ph - 0.5) - 1


def noise(dur, seed=1):
    return np.random.default_rng(seed).uniform(-1, 1, int(SR * dur))


def env(n, attack=0.005, decay=0.0, sustain=1.0, release=0.05):
    """ADSR envelope over n samples."""
    t = np.arange(n) / SR
    total = n / SR
    e = np.ones(n) * sustain
    a = t < attack
    e[a] = t[a] / max(attack, 1e-6)
    d = (t >= attack) & (t < attack + decay)
    e[d] = 1 - (1 - sustain) * (t[d] - attack) / max(decay, 1e-6)
    r = t > total - release
    e[r] *= np.clip((total - t[r]) / max(release, 1e-6), 0, 1)
    return e


def slide(f0, f1, dur, curve=1.0):
    t = np.linspace(0, 1, int(SR * dur)) ** curve
    return f0 + (f1 - f0) * t


def vibrato(freq, dur, rate=12, depth=0.03):
    t = np.arange(int(SR * dur)) / SR
    return freq * (1 + depth * np.sin(2 * np.pi * rate * t))


def write(name: str, data: np.ndarray, volume=0.5):
    data = np.clip(data * volume, -1, 1)
    pcm = (data * 32767).astype('<i2')
    with wave.open(os.path.join(OUT, f'{name}.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def seq(*parts):
    return np.concatenate(parts)


def tone(note_or_hz, dur, wave_fn='square', duty=0.25, rel=0.03, att=0.004):
    f = hz(note_or_hz) if isinstance(note_or_hz, str) else note_or_hz
    n = int(SR * dur)
    if wave_fn == 'square':
        s = square(f, dur, duty)
    else:
        s = triangle(f, dur)
    return s * env(n, attack=att, release=rel)


# --------------------------------------------------------------------- SFX

def sfx():
    d = 0.13
    write('jump', square(slide(380, 820, d, 0.6), d, 0.25) *
          env(int(SR * d), release=0.06), 0.35)
    d = 0.12
    write('double_jump', square(slide(620, 1250, d, 0.6), d, 0.125) *
          env(int(SR * d), release=0.06), 0.3)
    write('like', seq(tone('B5', 0.05), tone('E6', 0.11, rel=0.08)), 0.3)
    d = 0.16
    write('stomp', triangle(slide(700, 180, d, 0.5), d) *
          env(int(SR * d), release=0.08) +
          noise(d, 3) * env(int(SR * d), release=0.12) * 0.25, 0.55)
    d = 0.32
    write('hurt', square(vibrato(slide(520, 160, d), d, 18, 0.06), d, 0.5) *
          env(int(SR * d), release=0.1), 0.3)
    d = 0.4
    write('spring', triangle(vibrato(slide(180, 950, d, 0.7), d, 22, 0.08), d)
          * env(int(SR * d), release=0.12), 0.6)
    parts = [tone(n, 0.05, duty=0.125) for n in
             ['C5', 'E5', 'G5', 'C6', 'E6', 'G6', 'C7']]
    arp = seq(*parts)
    whoosh = noise(0.08, 9) * env(int(SR * .08), release=.06) * .3
    arp[:len(whoosh)] += whoosh
    write('special', arp, 0.35)
    write('checkpoint', seq(tone('C6', .07), tone('E6', .07), tone('G6', .07),
                            tone('C7', .2, rel=.15)), 0.3)
    melody = [('G5', .1), ('C6', .1), ('E6', .1), ('G6', .2), ('E6', .1),
              ('G6', .45)]
    lead = seq(*[tone(n, l, duty=.25, rel=.05) for n, l in melody])
    bass = seq(*[tone(n, l, 'tri') for n, l in
                 [('C4', .3), ('G3', .1), ('C4', .2), ('E4', .1),
                  ('G4', .45)]])
    write('finish', lead[:len(bass)] * .7 + bass[:len(lead)] * .5, 0.4)
    write('block', seq(square(slide(260, 180, .06), .06, .5) *
                       env(int(SR * .06), release=.03)), 0.35)
    write('click', tone(1400, 0.035, duty=.5, rel=.02), 0.2)
    write('gameover', seq(tone('G5', .16), tone('F5', .16), tone('E5', .16),
                          tone('C5', .5, 'tri', rel=.3)), 0.35)
    d = 0.22
    write('boss_hit', noise(d, 5) * env(int(SR * d), release=.15) * .6 +
          square(slide(200, 70, d), d, .5) * env(int(SR * d), release=.15) * .5,
          0.5)
    write('boss_roar', square(vibrato(slide(140, 90, .7), .7, 9, .1), .7, .5)
          * env(int(SR * .7), attack=.05, release=.3), 0.3)


# --------------------------------------------------------------------- music

def render_track(bpm, melody, bass, chords, drums=True, lead_duty=0.25,
                 swing=0.0):
    """Notes are (name or None, beats). Chords: list of note lists per bar
    (arpeggiated in 16ths). All parts must span the same number of beats."""
    beat = 60 / bpm

    def line(notes, fn, duty=0.25, vol=1.0, rel=0.04):
        out = []
        for name, beats in notes:
            dur = beats * beat
            if name is None:
                out.append(np.zeros(int(SR * dur)))
            else:
                out.append(tone(name, dur, fn, duty=duty,
                                rel=min(rel, dur / 2)) * vol)
        return np.concatenate(out)

    lead = line(melody, 'square', lead_duty, 0.55)
    bassl = line(bass, 'tri', vol=0.8)
    arp = []
    for chord in chords:  # one bar = 4 beats = 16 sixteenths
        for i in range(16):
            arp.append(tone(chord[i % len(chord)], beat / 4, 'square', .125,
                            rel=.02) * 0.16)
    arp = np.concatenate(arp)
    n = min(len(lead), len(bassl), len(arp))
    mix = lead[:n] + bassl[:n] + arp[:n]
    if drums:
        hat = noise(0.03, 11) * env(int(SR * .03), release=.02) * 0.12
        kick = triangle(slide(150, 40, .1), .1) * env(int(SR * .1), release=.06) * .6
        step = int(SR * beat / 2)
        for i in range(0, n - len(kick), step):
            idx = i // step
            if idx % 4 == 0:
                mix[i:i + len(kick)] += kick
            mix[i:i + len(hat)] += hat
    return mix


def notes(s: str):
    """'C5:1 E5:.5 -:.5' -> [('C5',1), ('E5',.5), (None,.5)]"""
    out = []
    for tok in s.split():
        n, b = tok.split(':')
        out.append((None if n == '-' else n, float(b)))
    return out


def music():
    # Bouncy, happy level theme (8 bars in C major).
    level_melody = notes(
        'E5:.5 G5:.5 C6:.5 G5:.5 A5:1 G5:1 '
        'E5:.5 G5:.5 A5:.5 G5:.5 E5:1 D5:1 '
        'F5:.5 A5:.5 C6:.5 A5:.5 G5:1 E5:1 '
        'D5:.5 E5:.5 F5:.5 D5:.5 G5:2 '
        'E5:.5 G5:.5 C6:.5 G5:.5 A5:1 G5:1 '
        'A5:.5 C6:.5 D6:.5 C6:.5 A5:1 G5:1 '
        'F5:.5 E5:.5 D5:.5 F5:.5 E5:.5 D5:.5 C5:.5 D5:.5 '
        'C5:2 -:2')
    level_bass = notes(' '.join(['C3:1 G3:1 C3:1 G3:1'] * 1 +
                                ['A2:1 E3:1 A2:1 E3:1'] +
                                ['F2:1 C3:1 F2:1 C3:1'] +
                                ['G2:1 D3:1 G2:1 D3:1'] +
                                ['C3:1 G3:1 C3:1 G3:1'] +
                                ['F2:1 C3:1 F2:1 C3:1'] +
                                ['G2:1 D3:1 G2:1 B2:1'] +
                                ['C3:1 G2:1 C3:2']))
    chords = [['C5', 'E5', 'G5'], ['A4', 'C5', 'E5'], ['F4', 'A4', 'C5'],
              ['G4', 'B4', 'D5'], ['C5', 'E5', 'G5'], ['F4', 'A4', 'C5'],
              ['G4', 'B4', 'D5'], ['C5', 'E5', 'G5']]
    track = render_track(140, level_melody, level_bass, chords)
    write('music_level', track, 0.38)

    # Gentle, dreamy menu theme (F major, slower, no drums).
    menu_melody = notes(
        'A5:1 C6:1 A5:1 F5:1 G5:1 A5:1 G5:2 '
        'F5:1 A5:1 G5:1 E5:1 F5:2 -:2 '
        'A5:1 C6:1 D6:1 C6:1 A5:1 G5:1 F5:2 '
        'G5:1 A5:1 G5:1 E5:1 F5:3 -:1')
    menu_bass = notes(' '.join(['F3:2 C4:2', 'C3:2 G3:2', 'D3:2 A3:2',
                                'F3:2 C4:2', 'A#2:2 F3:2', 'F3:2 C4:2',
                                'C3:2 G3:2', 'F3:4']))
    menu_chords = [['F4', 'A4', 'C5'], ['C4', 'E4', 'G4'], ['D4', 'F4', 'A4'],
                   ['F4', 'A4', 'C5'], ['A#3', 'D4', 'F4'], ['F4', 'A4', 'C5'],
                   ['C4', 'E4', 'G4'], ['F4', 'A4', 'C5']]
    write('music_menu', render_track(96, menu_melody, menu_bass, menu_chords,
                                     drums=False, lead_duty=0.5), 0.34)

    # Boss theme: tense but still cute (A minor, faster).
    boss_melody = notes(
        'A5:.5 A5:.5 C6:.5 A5:.5 E6:1 D6:1 '
        'C6:.5 B5:.5 A5:.5 G5:.5 A5:2 '
        'F5:.5 F5:.5 A5:.5 F5:.5 C6:1 B5:1 '
        'G#5:.5 A5:.5 B5:.5 G#5:.5 E5:2')
    boss_bass = notes(' '.join(['A2:.5 A3:.5'] * 8 + ['F2:.5 F3:.5'] * 4 +
                               ['E2:.5 E3:.5'] * 4))
    boss_chords = [['A4', 'C5', 'E5'], ['A4', 'C5', 'E5'], ['F4', 'A4', 'C5'],
                   ['E4', 'G#4', 'B4']]
    track = render_track(160, boss_melody, boss_bass, boss_chords)
    write('music_boss', track, 0.36)


def main():
    os.makedirs(OUT, exist_ok=True)
    sfx()
    music()
    print('audio written to', OUT)


if __name__ == '__main__':
    main()

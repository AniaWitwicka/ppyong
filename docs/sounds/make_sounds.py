"""Synthesises the Ppyong game sounds (HRHTA-105) as mono 44.1 kHz WAVs.

Three families:
  A "marimba":      soft wooden mallet tones (fundamental + 4x overtone).
  B "pop":          bubbly pitch-swept sine "bloops" (the first set in the app).
  C "paper & bell": the set in the app now — bell wins, wooden misses,
                    paper swishes for touches.

Pitch tells the story: correct rises, wrong falls. Every note has a 2–3 ms
attack (no click, no silence at the start) and decays to near silence; the
mp3 step adds a short fade-out.
"""
import math
import random
import struct
import sys
import wave

RATE = 44100


def render(length_s, voices):
    n = int(RATE * length_s)
    out = [0.0] * n
    for v in voices:
        v(out)
    return out


def mallet(t0, f, decay, amp=1.0, overtone=0.25):
    """Marimba-ish note: fundamental + 4x overtone, exponential decay."""
    def add(buf):
        s0 = int(t0 * RATE)
        for i in range(s0, len(buf)):
            t = (i - s0) / RATE
            env = (1 - math.exp(-t * 1200)) * math.exp(-t * decay)
            if env < 1e-5 and t > 0.01:
                break
            x = math.sin(2 * math.pi * f * t)
            x += overtone * math.sin(2 * math.pi * 4 * f * t) * math.exp(-t * decay * 2)
            buf[i] += amp * env * x
    return add


def bloop(t0, f_start, f_end, dur, amp=1.0):
    """Pitch-swept sine 'pop' with a soft round envelope."""
    def add(buf):
        s0 = int(t0 * RATE)
        n = int(dur * RATE)
        phase = 0.0
        for k in range(n):
            i = s0 + k
            if i >= len(buf):
                break
            p = k / n
            # exponential sweep sounds natural to the ear
            f = f_start * (f_end / f_start) ** (p ** 0.6)
            phase += 2 * math.pi * f / RATE
            env = (1 - math.exp(-k / RATE * 900)) * (1 - p) ** 2.2
            x = math.sin(phase) + 0.12 * math.sin(2 * phase)
            buf[i] += amp * env * x
    return add


def bell(t0, f, decay=9, amp=1.0):
    """Glockenspiel-ish: fundamental + inharmonic partials that fade faster."""
    def add(buf):
        s0 = int(t0 * RATE)
        for i in range(s0, len(buf)):
            t = (i - s0) / RATE
            env = (1 - math.exp(-t * 2500)) * math.exp(-t * decay)
            if env < 1e-5 and t > 0.01:
                break
            x = (math.sin(2 * math.pi * f * t)
                 + 0.35 * math.sin(2 * math.pi * 2.76 * f * t) * math.exp(-t * decay * 2)
                 + 0.12 * math.sin(2 * math.pi * 5.40 * f * t) * math.exp(-t * decay * 4))
            buf[i] += amp * env * x
    return add


def click(f=2400, amp=1.0):
    def add(buf):
        for i in range(len(buf)):
            t = i / RATE
            env = (1 - math.exp(-t * 4000)) * math.exp(-t * 180)
            buf[i] += amp * env * math.sin(2 * math.pi * f * t)
    return add


def swish(dur=0.14, f0=700, f1=2600, amp=1.0):
    """Card-turn whoosh: noise through a band-pass whose centre sweeps up."""
    def add(buf):
        rng = random.Random(7)  # fixed seed: the same file every rebuild
        n = int(dur * RATE)
        y1 = y2 = x1 = x2 = 0.0
        for k in range(min(n, len(buf))):
            p = k / n
            w = 2 * math.pi * f0 * (f1 / f0) ** p / RATE
            al = math.sin(w) / (2 * 1.4)
            a0, a1, a2 = 1 + al, -2 * math.cos(w), 1 - al
            x = rng.uniform(-1, 1)
            y = (al * x - al * x2 - a1 * y1 - a2 * y2) / a0
            x2, x1, y2, y1 = x1, x, y1, y
            buf[k] += amp * math.sin(math.pi * p) ** 1.5 * y
    return add


C5, E5, G5, A5, C6, E6, G6, A3, E3, F3 = 523.25, 659.25, 783.99, 880.0, 1046.5, 1318.5, 1568.0, 220.0, 164.81, 174.61
C7 = 2093.0

SOUNDS = {
    'A': {
        'correct': (0.32, [mallet(0, C6, 22, 0.8), mallet(0.075, G6, 20, 1.0)]),
        'wrong': (0.30, [mallet(0, 329.63, 26, 1.0, 0.25), mallet(0.09, 261.63, 24, 0.9, 0.25)]),
        'tap': (0.05, [mallet(0, 1760, 120, 1.0, 0.1)]),
        'complete': (1.30, [mallet(0, C5, 9, 0.8), mallet(0.12, E5, 9, 0.8),
                            mallet(0.24, G5, 8, 0.85), mallet(0.38, C6, 4.5, 1.0),
                            mallet(0.38, G5, 5, 0.35)]),
    },
    'B': {
        'correct': (0.26, [bloop(0, 600, 1500, 0.11, 0.9), bloop(0.08, 900, 2100, 0.16, 1.0)]),
        'wrong': (0.28, [bloop(0, 440, 250, 0.26, 1.0)]),
        'tap': (0.05, [bloop(0, 1400, 1800, 0.045, 1.0)]),
        'complete': (1.20, [bloop(0, 450, 700, 0.16, 0.8), bloop(0.13, 560, 880, 0.16, 0.8),
                            bloop(0.26, 700, 1050, 0.16, 0.85), bloop(0.40, 880, 1400, 0.75, 1.0)]),
        # A batch done with more to come (HRHTA-109): the first three notes of
        # 'complete', last one held a little — a finish, but smaller.
        'batch': (0.58, [bloop(0, 450, 700, 0.14, 0.8), bloop(0.11, 560, 880, 0.14, 0.85),
                         bloop(0.22, 700, 1050, 0.34, 1.0)]),
    },    # C "paper & bell": the set in the app since 2026-11-09, picked by the owner
    # sound by sound — bell for wins, soft wood for misses, paper for touches.
    'C': {
        'correct': (0.60, [bell(0, C6 * 1.5, 7, 1.0)]),
        'wrong': (0.30, [mallet(0, 329.63, 26, 1.0, 0.25), mallet(0.09, 261.63, 24, 0.9, 0.25)]),
        'tap': (0.05, [swish(0.045, 1500, 3500, 1.0)]),
        'flip': (0.15, [swish()]),
        'complete': (1.20, [swish(0.22, 500, 3000, 0.8), bell(0.18, G6, 5, 0.8),
                            bell(0.26, C7, 3.5, 1.0), bell(0.34, E6 * 2, 4, 0.5)]),
        'batch': (0.60, [swish(0.16, 600, 2800, 0.7), bell(0.14, G6, 6, 1.0)]),
    },
}

# Peak level per sound (dBFS): wrong a bit quieter than correct, tap quiet.
PEAK_DB = {'correct': -3.0, 'wrong': -5.0, 'tap': -10.0, 'flip': -6.0, 'complete': -3.0, 'batch': -3.0}


def write(path, samples, peak_db):
    peak = max(abs(s) for s in samples) or 1.0
    gain = 10 ** (peak_db / 20) / peak
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, s * gain)) * 32767)) for s in samples))


if __name__ == '__main__':
    out_dir = sys.argv[1]
    for family, sounds in SOUNDS.items():
        for name, (length, voices) in sounds.items():
            write(f'{out_dir}/{family}_{name}.wav', render(length, voices), PEAK_DB[name])
    print('ok')

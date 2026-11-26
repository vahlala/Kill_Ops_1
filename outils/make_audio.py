"""Génère la musique et les effets sonores 8-bit de Kill Ops 1 (synthèse maison, libre de droits)."""
import numpy as np, subprocess, os, sys
from scipy.signal import lfilter
from scipy.io import wavfile

SR = 44100
OUT = sys.argv[1]
rng = np.random.default_rng(7)
os.makedirs(f"{OUT}/music", exist_ok=True)
os.makedirs(f"{OUT}/sfx", exist_ok=True)

def t_(d): return np.arange(int(SR * d)) / SR
def midi(n): return 440.0 * 2 ** ((n - 69) / 12)
NOTES = {'C':0,'C#':1,'Db':1,'D':2,'D#':3,'Eb':3,'E':4,'F':5,'F#':6,'Gb':6,'G':7,'G#':8,'Ab':8,'A':9,'A#':10,'Bb':10,'B':11}
def n(s):  # "A4" -> midi
    name, octv = s[:-1], int(s[-1])
    return 12 * (octv + 1) + NOTES[name]

def lowpass(x, a):  # a proche de 1 = plus doux
    return lfilter([1 - a], [1, -a], x)
def highpass(x, a):
    return x - lowpass(x, a)

def env(length, a=0.005, d=0.05, s=0.6, r=0.05):
    N = length; e = np.ones(N) * s
    A = min(int(a * SR), N); D = min(int(d * SR), N - A); R = min(int(r * SR), N)
    e[:A] = np.linspace(0, 1, A, endpoint=False)
    e[A:A + D] = np.linspace(1, s, D, endpoint=False)
    if R: e[N - R:] *= np.linspace(1, 0, R)
    return e

def osc(kind, freq, dur, duty=0.5, vib=0.0):
    t = t_(dur)
    f = freq * (1 + vib * np.sin(2 * np.pi * 5.5 * t) * np.clip(t * 3, 0, 1))
    ph = np.cumsum(f) / SR
    fr = ph % 1.0
    if kind == 'sq': return np.where(fr < duty, 1.0, -1.0)
    if kind == 'tri': return 4 * np.abs(fr - 0.5) - 1
    if kind == 'saw': return 2 * fr - 1
    if kind == 'sin': return np.sin(2 * np.pi * ph)

def noise(dur): return rng.uniform(-1, 1, int(SR * dur))

# ---------- batterie
def kick():
    t = t_(0.25); f = 45 + 110 * np.exp(-t * 30)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 14)
def snare():
    t = t_(0.18)
    return (0.7 * highpass(noise(0.18), 0.6) + 0.35 * np.sin(2 * np.pi * 190 * t)) * np.exp(-t * 22)
def hat(open_=False):
    d = 0.12 if open_ else 0.04; t = t_(d)
    return highpass(noise(d), 0.2) * np.exp(-t * (25 if open_ else 90)) * 0.5

# ---------- séquenceur
class Song:
    def __init__(self, bpm, bars):
        self.step = 60 / bpm / 4            # durée d'une double-croche
        self.N = int(round(self.step * 16 * bars * SR))
        self.buf = np.zeros(self.N + SR * 2)
    def add(self, sig, step_pos, gain=1.0):
        i = int(round(step_pos * self.step * SR))
        self.buf[i:i + len(sig)] += sig * gain
    def note(self, kind, m, step_pos, steps, gain, duty=0.5, vib=0.0, a=0.005, d=0.06, s=0.6, r=0.04, legato=0.95):
        dur = steps * self.step * legato
        sig = osc(kind, midi(m), dur, duty, vib) * env(int(SR * dur), a, d, s, r)
        self.add(sig, step_pos, gain)
    def render(self, lp=0.35):
        out = self.buf[:self.N].copy()
        out[:len(self.buf) - self.N] += self.buf[self.N:]     # la queue revient au début : boucle sans coupure
        out = lowpass(out, lp)
        return out
    def melody(self, kind, seq, start, gain, **kw):
        pos = start
        for tok in seq.split():
            name, steps = tok.split(':'); steps = int(steps)
            if name != '-':
                self.note(kind, n(name), pos, steps, gain, **kw)
            pos += steps
        return pos

def chord_notes(root, minor):
    return [root, root + (3 if minor else 4), root + 7]

def save_ogg(name, x, peak=0.85):
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    wav = f"/tmp/{name}.wav"
    wavfile.write(wav, SR, (x * 32767).astype(np.int16))
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "4", f"{OUT}/music/{name}.ogg"], check=True)
    os.remove(wav)

def save_wav(name, x, peak=0.8):
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    fade = min(len(x), int(0.004 * SR)); x[-fade:] *= np.linspace(1, 0, fade)
    wavfile.write(f"{OUT}/sfx/{name}.wav", 22050, (x[::2] * 32767).astype(np.int16))

# ================= MUSIQUE DU NIVEAU : 150 bpm, la mineur, Am F C G
def make_jeu():
    s = Song(150, 16)
    prog = [(n('A2'), True), (n('F2'), False), (n('C3'), False), (n('G2'), False)]
    for bar in range(16):
        root, minor = prog[bar % 4]
        b0 = bar * 16
        for k in range(8):   # basse en croches, octaves
            s.note('tri', root + (12 if k % 2 else 0), b0 + k * 2, 2, 0.55, s=0.8)
        # batterie
        for k in range(4):
            s.add(kick(), b0 + k * 4, 0.9 if k % 2 == 0 else 0.0)
        s.add(kick(), b0 + 10, 0.6)
        s.add(snare(), b0 + 4, 0.55); s.add(snare(), b0 + 12, 0.55)
        if bar % 4 == 3: s.add(snare(), b0 + 14, 0.35); s.add(snare(), b0 + 15, 0.4)
        for k in range(8): s.add(hat(k == 7), b0 + k * 2, 0.35)
        # accords en arpège très doux (fond)
        ch = chord_notes(root + 12, minor)
        if bar >= 4:
            for k in range(16):
                s.note('sq', ch[k % 3] + 12, b0 + k, 1, 0.06, duty=0.25, s=0.3)
    A = "A4:4 C5:2 E5:2 D5:3 C5:1 B4:2 C5:2 A4:4 F4:2 A4:2 C5:4 -:2 C5:2 E5:4 G5:2 E5:2 D5:4 C5:2 D5:2 B4:6 G4:2 B4:4 D5:4"
    B = "E5:4 A5:2 G5:2 E5:3 D5:1 C5:2 E5:2 F5:4 E5:2 D5:2 C5:2 A4:2 F4:4 G4:2 C5:2 E5:2 G5:2 E5:4 D5:2 C5:2 B4:4 D5:4 G5:4 F5:2 E5:2"
    pos = 4 * 16
    for seq in (A, B, A, B):
        s.melody('sq', seq, pos, 0.22, duty=0.5, vib=0.006, s=0.7); pos += 64
        if pos >= 16 * 16: break
    return s.render(0.3)

# ================= BOSS : 172 bpm, ré mineur harmonique, Dm Bb Gm A
def make_boss():
    s = Song(172, 16)
    prog = [(n('D2'), True), (n('A#1'), False), (n('G2'), True), (n('A2'), False)]
    for bar in range(16):
        root, minor = prog[bar % 4]
        b0 = bar * 16
        for k in range(16):  # basse en doubles-croches
            s.note('saw', root + (12 if k % 4 == 2 else 0), b0 + k, 1, 0.3, s=0.7, legato=0.8)
        for k in (0, 3, 6, 8, 11, 14):
            s.add(kick(), b0 + k, 0.9)
        s.add(snare(), b0 + 4, 0.6); s.add(snare(), b0 + 12, 0.6)
        if bar % 2 == 1: s.add(snare(), b0 + 15, 0.4)
        for k in range(16): s.add(hat(), b0 + k, 0.22 if k % 2 else 0.35)
        ch = chord_notes(root + 24, minor)
        for k in range(16):   # arpège rapide strident
            s.note('sq', ch[k % 3] + (12 if (k // 3) % 2 else 0), b0 + k, 1, 0.07, duty=0.125, s=0.4)
    A = "D5:2 F5:2 A5:4 G#5:2 A5:2 F5:4 D5:2 F5:2 A#5:4 A5:2 G5:2 F5:4 G5:2 A#5:2 D6:4 C6:2 A#5:2 A5:4 C#5:4 E5:4 A5:4 G5:2 E5:2"
    B = "D6:6 C6:2 A#5:4 A5:4 A#5:6 A5:2 G5:4 F5:4 G5:6 F5:2 E5:4 D5:4 E5:4 C#5:4 A4:8"
    pos = 4 * 16
    for seq in (A, B, A):
        s.melody('sq', seq, pos, 0.2, duty=0.25, vib=0.01, s=0.75); pos += 64
    return s.render(0.25)

# ================= MENU : 96 bpm, calme et mystérieux, Am Em F G
def make_menu():
    s = Song(96, 8)
    prog = [(n('A2'), True), (n('E2'), True), (n('F2'), False), (n('G2'), False)]
    for bar in range(8):
        root, minor = prog[bar % 4]
        b0 = bar * 16
        s.note('tri', root, b0, 8, 0.5, a=0.02, s=0.7, r=0.2)
        s.note('tri', root, b0 + 8, 6, 0.4, a=0.02, s=0.7, r=0.2)
        s.note('tri', root + 7, b0 + 14, 2, 0.35)
        ch = chord_notes(root + 24, minor)
        pattern = [0, 1, 2, 1, 0, 1, 2, 3]
        for k in range(16):
            idx = pattern[k % 8]
            m = ch[idx] if idx < 3 else ch[0] + 12
            s.note('sq', m, b0 + k, 1, 0.08, duty=0.25, a=0.002, d=0.1, s=0.15, r=0.05)
        s.add(kick(), b0, 0.6); s.add(kick(), b0 + 8, 0.4)
        s.add(snare(), b0 + 12, 0.18)
        for k in range(4): s.add(hat(), b0 + k * 4 + 2, 0.2)
    lead = "E5:8 D5:4 C5:4 B4:12 G4:4 C5:8 A4:4 C5:4 D5:16 E5:8 G5:4 E5:4 B4:12 D5:4 C5:6 B4:2 A4:8 G4:4 B4:4 A4:8"
    s.melody('tri', lead, 0, 0.32, vib=0.012, a=0.03, s=0.8, r=0.1)
    return s.render(0.45)

def make_jingle(seq, bpm, kind, chords):
    s = Song(bpm, 4)
    end = s.melody(kind, seq, 0, 0.35, duty=0.5, vib=0.01, s=0.8, r=0.15)
    for pos, notes_, steps in chords:
        for m in notes_: s.note('tri', n(m), pos, steps, 0.25, s=0.8, r=0.3)
    x = s.buf[:int(end * s.step * SR) + SR]
    return lowpass(x, 0.3)

save_ogg("menu", make_menu())
save_ogg("jeu", make_jeu())
save_ogg("boss", make_boss())
save_ogg("victoire", make_jingle("G4:2 C5:2 E5:2 G5:4 E5:2 G5:10", 140, 'sq',
         [(0, ['C3', 'G3'], 6), (6, ['C3', 'E3', 'G3'], 16)]))
save_ogg("defaite", make_jingle("E5:4 D#5:4 D5:4 C#5:12", 90, 'sq',
         [(0, ['A2', 'E3'], 12), (12, ['A2', 'C3'], 12)]))

# ================= EFFETS SONORES
def sweep(kind, f0, f1, dur, duty=0.5, curve=1.0):
    t = t_(dur); k = (t / dur) ** curve
    f = f0 * (f1 / f0) ** k
    ph = np.cumsum(f) / SR % 1
    if kind == 'sq': return np.where(ph < duty, 1.0, -1.0)
    if kind == 'tri': return 4 * np.abs(ph - 0.5) - 1
    return np.sin(2 * np.pi * ph)
def dec(dur, rate): return np.exp(-t_(dur) * rate)

sfx = {}
sfx["tir"] = lowpass(0.6 * sweep('sq', 900, 180, 0.09, 0.3) * dec(0.09, 30) + 0.5 * noise(0.09) * dec(0.09, 45), 0.2)
sfx["tir_lourd"] = lowpass(0.5 * sweep('sq', 500, 90, 0.11, 0.5) * dec(0.11, 22) + 0.8 * noise(0.11) * dec(0.11, 28), 0.35)
sfx["saut"] = lowpass(sweep('sq', 220, 660, 0.14, 0.25, 0.6) * dec(0.14, 10), 0.3)
sfx["degat"] = lowpass(sweep('sq', 420, 110, 0.25, 0.5) * dec(0.25, 8) * (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 30 * t_(0.25)))), 0.3)
sfx["mort_joueur"] = lowpass(np.concatenate([sweep('sq', 660, 80, 0.7, 0.5, 0.7) * dec(0.7, 3.5), np.zeros(1000)]), 0.35)
x = np.zeros(int(0.32 * SR))
for i, m in enumerate([n('C6'), n('E6'), n('G6'), n('C7')]):
    seg = osc('sq', midi(m), 0.08, 0.25) * dec(0.08, 15); st = int(i * 0.06 * SR); x[st:st + len(seg)] += seg
sfx["ramassage"] = lowpass(x, 0.25)
sfx["impact"] = lowpass(0.7 * noise(0.05) * dec(0.05, 70) + 0.4 * sweep('sq', 300, 120, 0.05) * dec(0.05, 60), 0.3)
sfx["mort_insecte"] = lowpass(0.6 * noise(0.22) * dec(0.22, 14) * (0.5 + 0.5 * np.sin(2 * np.pi * 45 * t_(0.22))) + 0.5 * sweep('sq', 800, 150, 0.22, 0.5) * dec(0.22, 12), 0.4)
sfx["crachat"] = lowpass(0.7 * noise(0.16) * dec(0.16, 16) * np.abs(np.sin(2 * np.pi * 25 * t_(0.16))) + 0.4 * sweep('sin', 300, 700, 0.16) * dec(0.16, 18), 0.5)
sfx["explosion"] = lowpass(noise(1.2) * dec(1.2, 3.2) + 0.8 * sweep('sin', 120, 30, 1.2) * dec(1.2, 4), 0.85)
roar = sweep('saw' if False else 'sq', 140, 70, 0.9, 0.5) * (0.6 + 0.4 * np.sin(2 * np.pi * 18 * t_(0.9)))
sfx["reine_cri"] = lowpass(0.6 * roar * env(int(0.9 * SR), 0.08, 0.2, 0.7, 0.3) + 0.4 * noise(0.9) * env(int(0.9 * SR), 0.05, 0.2, 0.5, 0.3), 0.6)
sfx["ui_deplacer"] = lowpass(osc('sq', 880, 0.04, 0.5) * dec(0.04, 50), 0.2)
sfx["ui_valider"] = lowpass(np.concatenate([osc('sq', 660, 0.05, 0.5) * dec(0.05, 30), osc('sq', 990, 0.08, 0.5) * dec(0.08, 25)]), 0.2)
for k, v in sfx.items():
    save_wav(k, v)
print("ok", sorted(sfx))

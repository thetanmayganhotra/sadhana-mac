# Renders the short singing-bowl bell (≈5 s) used before each exercise.
import math, wave, array, os, sys
SR, DUR, F = 44100, 5.0, 196.0
# partial ratio, amplitude, decay (1/s), beat (Hz)
P = [(1.0, 1.0, 0.95, 0.7), (2.71, 0.55, 1.6, 1.3), (5.15, 0.25, 2.6, 2.1), (8.4, 0.12, 4.0, 3.0)]
n = int(SR * DUR)
out = array.array('h')
for i in range(n):
    t = i / SR
    atk = min(1.0, t / 0.006)
    fade = min(1.0, (DUR - t) / 1.2)
    l = r = 0.0
    for ratio, amp, dec, beat in P:
        e = amp * math.exp(-dec * t) * atk * fade
        f = F * ratio
        l += e * math.sin(2 * math.pi * f * t)
        r += e * math.sin(2 * math.pi * (f + beat) * t + 0.3)
    out.append(int(max(-1, min(1, l * 0.36)) * 32767))
    out.append(int(max(-1, min(1, r * 0.36)) * 32767))
path = sys.argv[1]
w = wave.open(path, 'w'); w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
w.writeframes(out.tobytes()); w.close()

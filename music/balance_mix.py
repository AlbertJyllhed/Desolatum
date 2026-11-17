"""Balances the track volumes of a generated LMMS song by measuring, not by ear.

    python music/balance_mix.py SCRIPT VARIANT DICTNAME OUT.mmp OUT.wav "Track=-24,Other=p0.3" [rounds]

  SCRIPT    generator script, e.g. music/make_cave_music.py
  VARIANT   the variant argument that script takes, e.g. calm / combat / rumble
  DICTNAME  the volume table in the script to rewrite, e.g. CALM_VOLUMES
  OUT.mmp   where the script writes the project (normally music/<name>.mmp)
  OUT.wav   where the final full-mix render goes (keep it out of the Godot project)
  targets   per track: "-24" = average loudness in dB while the track is sounding,
            "p0.3" = peak level (use this for short hits like hats, where the
            average is misleading). Tracks not listed keep their volume.
            Pass "X=-99" to only render and measure without changing anything.
  rounds    how many measure-and-adjust passes (default 2; 0 = just measure)

Each round renders every track solo (with the master limiter bypassed, so the
reading is honest), scales its volume in DICTNAME toward its target and writes
the table back into SCRIPT. Then it renders the full mix and prints the level
per section, the peak, the number of clipped samples and the loop seam (last
half bar vs first half bar).

Volumes scale linearly, which works for plain tracks and for mixer faders
(Song(mixer=True)). It does NOT work for track volume on distorted tracks: the
distortion flattens it. That's why the combat song uses mixer faders.

Run it from a scratch folder: it writes tmp.mmp and solo.wav to the current directory.
"""
import array
import math
import re
import subprocess
import sys
import wave

LMMS = r"C:\Program Files\LMMS\lmms.exe"
script, variant, dname, out_mmp, out_wav, tspec = sys.argv[1:7]
rounds = int(sys.argv[7]) if len(sys.argv) > 7 else 2
TARGET = {kv.split("=")[0]: kv.split("=")[1] for kv in tspec.split(",") if "=" in kv}


def gen() -> str:
    subprocess.run([sys.executable, script, variant, out_mmp], check=True, capture_output=True)
    return open(out_mmp, encoding="utf-8").read()


def render(xml: str, out: str):
    open("tmp.mmp", "w", encoding="utf-8").write(xml)
    subprocess.run([LMMS, "-r", "tmp.mmp", "-f", "wav", "-o", out], capture_output=True, timeout=500)
    w = wave.open(out)
    sr = w.getframerate()
    a = array.array('h', w.readframes(w.getnframes()))
    w.close()
    return sr, [(a[i] + a[i + 1]) / 65536 for i in range(0, len(a), 2)]


def db(s) -> float:
    return 20 * math.log10(math.sqrt(sum(x * x for x in s) / max(len(s), 1)) + 1e-9)


def active_db(s, sr) -> float:
    """Average loudness over the half-second blocks where the track is actually sounding."""
    blk = sr // 2
    levels = [db(s[i:i + blk]) for i in range(0, len(s) - blk, blk)]
    on = [lv for lv in levels if lv > -70]
    return 10 * math.log10(sum(10 ** (lv / 10) for lv in on) / len(on)) if on else -99


for rnd in range(rounds):
    src = gen()
    code = open(script, encoding="utf-8").read()
    block = code.split(dname + " = {")[1].split("}")[0]
    vols = {n: int(v) for n, v in re.findall(r'"([A-Za-z ]+)": (\d+)', block)}
    new = {}
    for n in vols:
        x = re.sub(r'<track muted="0" type="0" name="(?!' + re.escape(n) + '")',
                   '<track muted="1" type="0" name="', src)
        x = x.replace('name="ladspaeffect" on="1"', 'name="ladspaeffect" on="0"')   # bypass limiter
        sr, s = render(x, "solo.wav")
        a = active_db(s, sr)
        pk = max(abs(v) for v in s)
        t = TARGET.get(n)
        if t is None:
            nv = vols[n]
        elif t.startswith("p"):
            nv = max(3, min(200, round(vols[n] * float(t[1:]) / max(pk, 1e-6))))
        else:
            nv = max(3, min(200, round(vols[n] * 10 ** ((float(t) - a) / 20))))
        print(f"round{rnd} {n:14s} vol {vols[n]:>3} active {a:6.1f} dB peak {pk:.2f} -> {nv}", flush=True)
        new[n] = nv
    lines = [f'"{n}": {v},' for n, v in new.items()]
    body = "\n    " + "\n    ".join(" ".join(lines[i:i + 4]) for i in range(0, len(lines), 4)) + "\n"
    code = code.replace(dname + " = {" + block + "}",
                        dname + " = {" + block.split("\n")[0] + body + "}", 1)
    open(script, "w", encoding="utf-8", newline="\n").write(code)

src = gen()
sr, m = render(src, out_wav)
bpm = float(re.search(r'bpm="(\d+)"', src).group(1))
bars = int(re.search(r'lp1pos="(\d+)"', src).group(1)) // 192
bar = sr * 240 / bpm
print("FULL secs", round(len(m) / sr, 1), "peak", round(max(abs(x) for x in m), 2),
      "clipped", sum(1 for x in m if abs(x) >= 0.999))
step = max(1, bars // 8)
for b in range(0, bars, step):
    s = m[int(b * bar):int((b + step) * bar)]
    print(f" bars {b + 1:>2}-{b + step:<2} {db(s):6.1f} dB peak {max(abs(x) for x in s):.2f}")
print(" seam: end", round(db(m[int((bars - 0.5) * bar):int(bars * bar)]), 1),
      "start", round(db(m[:int(0.5 * bar)]), 1))

"""Generates LMMS 1.2.2 projects (.mmp) for the Desolatum cave level.

    calm   - cave ambience with a low, slow beat. Keeps reminding the player they are alone.
             E minor (Phrygian F for darkness), 70 BPM, 32 bars (~110 s).
    combat - the same song as a never-ending onslaught for enemy waves.
             E minor, 140 BPM, 64 bars (~110 s): double tempo, so chord changes line up with calm.

Both cave tracks share key, chords and loop length, so the game can crossfade between them
at the same playback position. The whole mix goes through a bitcrusher on the master channel,
like the ship hub theme.

Usage (from the project root):
    python music/make_cave_music.py calm music/cave_calm.mmp
    python music/make_cave_music.py combat music/cave_combat.mmp
    python music/make_cave_music.py rumble music/chaos_rumble.mmp   (the warning sound before a wave)
This overwrites the .mmp, so any changes made by hand in LMMS will be lost.
"""
import random
import sys
from xml.sax.saxutils import quoteattr

BEAT = 48            # LMMS ticks per beat
BAR = BEAT * 4

def k(midi: int) -> int:
    """MIDI note -> LMMS key (LMMS A4 = 57, MIDI A4 = 69)."""
    return midi - 12

# ---------------------------------------------------------------- shared harmony
# Four chords over an E pedal; each lasts 1/4 of the loop.
E_PEDAL = 40                       # E2
CHORDS = [
    [52, 55, 59, 66],              # Em9            E G B F#
    [53, 57, 60, 64],              # Fmaj7/E        F A C E   (dark b2)
    [57, 60, 64, 71],              # Am(add9)/E     A C E B
    [53, 57, 59, 64],              # Fmaj7#11/E     F A B E   (tension back into Em)
]
CALL = [(0, 1.5, 67), (1.5, 3, 64)]   # G4 -> E4: a call with no answer but its own echo

# ---------------------------------------------------------------- instruments
SINE, TRI, SAW, SQUARE, MOOGSAW, EXP, NOISE = 0, 1, 2, 3, 4, 5, 6
LOWPASS, HIPASS, BANDPASS = 0, 1, 2

def triosc(oscs):
    a = {"modalgo1": 2, "modalgo2": 2, "modalgo3": 2}
    for i, o in enumerate(oscs):
        a.update({f"wavetype{i}": o["wave"], f"vol{i}": o["vol"], f"coarse{i}": o.get("coarse", 0),
                  f"finel{i}": o.get("finel", 0), f"finer{i}": o.get("finer", 0),
                  f"pan{i}": o.get("pan", 0), f"phoffset{i}": o.get("phase", 0),
                  f"stphdetun{i}": 0, f"userwavefile{i}": ""})
    attrs = " ".join(f"{n}={quoteattr(str(v))}" for n, v in a.items())
    return f'<instrument name="tripleoscillator"><tripleoscillator {attrs}/></instrument>'

def kicker(startfreq, endfreq, decay, dist=0.0, distend=0.0, noise=0.0, click=0.3, slope=0.1, env=0.2):
    """LMMS Kicker drum synth. decay is in ms."""
    return (f'<instrument name="kicker"><kicker version="1" startfreq="{startfreq}" endfreq="{endfreq}" '
            f'decay="{decay}" decay_numerator="4" decay_denominator="4" syncmode="0" dist="{dist}" '
            f'distend="{distend}" noise="{noise}" click="{click}" slope="{slope}" env="{env}" gain="1" '
            f'startnote="0" endnote="0"/></instrument>')

def env(tag, att=0.0, dec=0.0, sus=0.0, rel=0.1, amt=0.0, lamt=0.0, lspd=0.1):
    # LMMS: times are knob values (seconds ~ v*v*5); sus=0 means full sustain level.
    return (f'<{tag} pdel="0" att="{att}" hold="0" dec="{dec}" sus="{sus}" rel="{rel}" amt="{amt}" '
            f'lpdel="0" latt="0" lspd="{lspd}" lamt="{lamt}" lshp="0" x100="0" ctlenvamt="0" '
            f'userwavefile="" lfosyncmode="0"/>')

def eldata(fcut=14000, fres=0.5, ftype=LOWPASS, vol_env="", cut_env="", wet=1):
    return (f'<eldata fres="{fres}" ftype="{ftype}" fcut="{fcut}" fwet="{wet}">{vol_env or env("elvol")}'
            f'{cut_env or env("elcut")}{env("elres")}</eldata>')

def _effect(name, wet, controls_xml):
    return (f'<effect name="{name}" on="1" wet="{wet}" gate="0" autoquit="8000" '
            f'autoquit_numerator="4" autoquit_denominator="4" syncmode="0">{controls_xml}<key/></effect>')

def reverb(wet, size=0.85, color=9000):
    ctl = f'input_gain="0" size="{size}" color="{color}" output_gain="0"'
    return _effect("reverbsc", wet, f'<ReverbSCControls {ctl}/><reverbsccontrols {ctl}/>')

def delay(wet, seconds, feedback=0.35):
    ctl = f'DelayTimeSamples="{seconds}" FeebackAmount="{feedback}" LfoFrequency="2" LfoAmount="0" OutGain="0"'
    return _effect("delay", wet, f'<Delay {ctl}/><DelayControls {ctl}/>')

def bitcrush(wet, rate, levels):
    """rate: target sample rate in Hz; levels: quantisation steps (256 = 8-bit, 32 = 5-bit)."""
    ctl = (f'ingain="0" innoise="0" outgain="0" outclip="0" rate="{rate}" stereodiff="0" '
           f'levels="{levels}" rateon="1" depthon="1"')
    return _effect("bitcrush", wet, f'<bitcrushcontrols {ctl}/><BitcrushControls {ctl}/>')

def limiter(gain_db, limit_db=-0.5, release_ms=50):
    """LADSPA Fast Lookahead Limiter (ships with LMMS): pushes the mix up without clipping."""
    return ('<effect name="ladspaeffect" on="1" wet="1" gate="0" autoquit="8000" autoquit_numerator="4" '
            'autoquit_denominator="4" syncmode="0"><ladspacontrols ports="3">'
            f'<port00 data="{gain_db}"/><port01 data="{limit_db}"/><port02 data="{release_ms}"/>'
            '</ladspacontrols><key><attribute value="fast_lookahead_limiter_1913.so" name="file"/>'
            '<attribute value="fastLookaheadLimiter" name="plugin"/></key></effect>')

# ---------------------------------------------------------------- song building
class Song:
    def __init__(self, bpm: int, bars: int, mixer: bool = False, track_vol: int = 60):
        """mixer=True gives every track its own FX mixer channel: the volume passed to add()
        then sets that channel's fader (after the track's effects, 100 = 0 dB), and every
        track plays at track_vol, which sets how hard it drives its distortion."""
        self.bpm, self.bars = bpm, bars
        self.beat_s = 60.0 / bpm
        self.tracks = []
        self.mixer, self.track_vol = mixer, track_vol
        self.channels = []          # (name, fader %) for mixer channels 1..n

    def note(self, bar, beat, length_beats, midi, vol=100, pan=0):
        return dict(pos=int(bar * BAR + beat * BEAT), len=max(1, int(length_beats * BEAT)),
                    key=k(midi), vol=vol, pan=pan)

    def chord_at(self, bar):
        return CHORDS[int(bar * len(CHORDS) // self.bars)]

    def add(self, name, vol, instrument_xml, eldata_xml, effects, notes):
        fxch, track_vol = 0, vol
        if self.mixer:
            self.channels.append((name, vol))
            fxch, track_vol = len(self.channels), self.track_vol
        notes_xml = "\n".join(
            f'          <note pan="{n["pan"]}" key="{n["key"]}" vol="{n["vol"]}" pos="{n["pos"]}" len="{n["len"]}"/>'
            for n in sorted(notes, key=lambda n: n["pos"]))
        self.tracks.append(f'''      <track muted="0" type="0" name={quoteattr(name)} solo="0">
        <instrumenttrack pan="0" fxch="{fxch}" pitchrange="1" pitch="0" basenote="57" vol="{track_vol}">
          {instrument_xml}
          {eldata_xml}
          <chordcreator chord="0" chordrange="1" chord-enabled="0"/>
          <arpeggiator arptime="100" arprange="1" arpmode="0" arp-enabled="0" arp="0" arpdir="0" arpgate="100" syncmode="0"/>
          <midiport inputcontroller="0" fixedoutputvelocity="-1" inputchannel="0" outputcontroller="0" writable="0" outputchannel="1" fixedinputvelocity="-1" fixedoutputnote="-1" outputprogram="1" basevelocity="63" readable="0"/>
          <fxchain numofeffects="{len(effects)}" enabled="{1 if effects else 0}">{"".join(effects)}</fxchain>
        </instrumenttrack>
        <pattern muted="0" steps="16" name={quoteattr(name)} pos="0" len="{self.bars * BAR}" type="1">
{notes_xml}
        </pattern>
      </track>''')

    def write(self, path, notes_text, master_fx):
        end = self.bars * BAR
        channels = "".join(
            f'\n      <fxchannel soloed="0" num="{i}" muted="0" volume="{fader / 100:.3f}" name={quoteattr(n)}>'
            f'<fxchain numofeffects="0" enabled="0"/><send amount="1" channel="0"/></fxchannel>'
            for i, (n, fader) in enumerate(self.channels, 1))
        project = f'''<?xml version="1.0"?>
<!DOCTYPE lmms-project>
<lmms-project version="1.0" creator="LMMS" creatorversion="1.2.2" type="song">
  <head timesig_numerator="4" mastervol="100" timesig_denominator="4" bpm="{self.bpm}" masterpitch="0"/>
  <song>
    <trackcontainer width="600" x="5" y="5" maximized="0" height="300" visible="1" type="song" minimized="0">
{chr(10).join(self.tracks)}
    </trackcontainer>
    <fxmixer width="543" x="5" y="310" maximized="0" height="333" visible="1" minimized="0">
      <fxchannel soloed="0" num="0" muted="0" volume="1" name="Master">
        <fxchain numofeffects="{len(master_fx)}" enabled="1">{"".join(master_fx)}</fxchain>
      </fxchannel>{channels}
    </fxmixer>
    <controllers/>
    <timeline lp0pos="0" lp1pos="{end}" lpstate="1"/>
    <projectnotes width="400" x="700" y="10" maximized="0" height="300" visible="0" minimized="0"><![CDATA[{notes_text}]]></projectnotes>
  </song>
</lmms-project>
'''
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(project)
        print("wrote", path, f"({self.bars} bars, {self.bars * 4 * self.beat_s:.1f} s)")

# ---------------------------------------------------------------- calm
CALM_VOLUMES = {  # track volumes, balanced from solo renders
    "Cave Drone": 14, "Sub Pedal": 14, "Low Rumble": 69, "Low Beat": 98,
    "Distant Tap": 200, "Water Drips": 128, "Lonely Call": 78,
}

def build_calm() -> Song:
    s = Song(bpm=70, bars=32)
    v = CALM_VOLUMES
    quarter = s.bars // len(CHORDS)

    # long dark chords, one per quarter of the loop
    pad = []
    for i, chord in enumerate(CHORDS):
        for j, m in enumerate(chord):
            pad.append(s.note(i * quarter, 0, quarter * 4, m, vol=80, pan=[-40, -15, 15, 40][j]))
    s.add("Cave Drone", v["Cave Drone"],
          triosc([dict(wave=SAW, vol=28, finel=-12, finer=12),
                  dict(wave=SQUARE, vol=15, finel=9, finer=-9, phase=90),
                  dict(wave=TRI, vol=35, coarse=-12)]),
          eldata(550, 0.8, vol_env=env("elvol", att=0.35, rel=0.8, amt=1),
                 cut_env=env("elcut", lamt=0.2, lspd=0.02)),
          [reverb(0.6, size=0.96, color=4000)], pad)

    s.add("Sub Pedal", v["Sub Pedal"],
          triosc([dict(wave=SINE, vol=60, coarse=-12), dict(wave=TRI, vol=25), dict(wave=SINE, vol=0)]),
          eldata(350, 0.7, vol_env=env("elvol", att=0.2, rel=0.5, amt=1)),
          [], [s.note(0, 0, s.bars * 4, E_PEDAL, vol=90)])

    # deep cave rumble: low-passed noise (no resonance, so it doesn't moan) plus a slowly
    # beating low E, with a very slow volume swell like the ground shifting far away
    s.add("Low Rumble", v["Low Rumble"],
          triosc([dict(wave=NOISE, vol=70), dict(wave=SINE, vol=25, coarse=-12, finel=-4, finer=4),
                  dict(wave=SINE, vol=15, coarse=-12, finel=3, finer=-3)]),
          eldata(140, 0.3, vol_env=env("elvol", rel=0.5, amt=1, lamt=0.35, lspd=0.012)),
          [reverb(0.3, size=0.9, color=1500)], [s.note(0, 0, s.bars * 4, E_PEDAL, vol=100)])

    # low, slow heartbeat-like beat; drops out for two bars so the silence is felt
    beat = []
    for bar in range(s.bars):
        if bar in (16, 17):
            continue
        for b in (0, 2):
            beat.append(s.note(bar, b, 0.5, 33, vol=95))
            beat.append(s.note(bar, b + 0.375, 0.5, 33, vol=55))
    s.add("Low Beat", v["Low Beat"],
          kicker(85, 32, 520, dist=0.4, distend=0.2, noise=0.05, click=0.15, slope=0.2, env=0.25),
          eldata(400, 0.7), [bitcrush(0.5, 8000, 128), reverb(0.35, size=0.92, color=2500)], beat)

    # faint tap on the backbeat, like stone settling far away
    taps = [s.note(bar, b, 0.25, 69, vol=70 if b == 3 else 45)
            for bar in range(s.bars) if bar not in (16, 17) for b in (1, 3)]
    s.add("Distant Tap", v["Distant Tap"],
          kicker(400, 180, 90, dist=0.6, noise=0.8, click=0.6, slope=0.06, env=0.1),
          eldata(wet=0),
          [bitcrush(0.7, 7000, 64), reverb(0.6, size=0.95, color=5000)], taps)

    # water drips at random spots, always from E minor pentatonic, high up
    rng = random.Random(7)
    drips = []
    t = 0.75
    while t < s.bars * 4 - 2:
        drips.append(s.note(0, t, 0.25, rng.choice([88, 91, 93, 95, 98, 100]),
                            vol=rng.randint(45, 90), pan=rng.randint(-70, 70)))
        if rng.random() < 0.25:     # sometimes a second drop right after
            drips.append(s.note(0, t + 0.25, 0.25, rng.choice([91, 95, 98]), vol=40, pan=rng.randint(-70, 70)))
        t += rng.choice([1.5, 2.25, 3, 3.5, 4.75, 6])
    s.add("Water Drips", v["Water Drips"],
          triosc([dict(wave=SINE, vol=70), dict(wave=SINE, vol=20, coarse=12), dict(wave=TRI, vol=0)]),
          eldata(6000, 0.5, vol_env=env("elvol", dec=0.18, sus=1, rel=0.12, amt=1)),
          [bitcrush(1.0, 11025, 64), delay(0.3, round(s.beat_s * 0.75, 4), 0.35),
           reverb(0.7, size=0.96, color=7000)], drips)

    # the lonely call: once every 8 bars, answered only by its own echo
    calls = [s.note(bar, b, ln, m, vol=80) for bar in (3, 11, 19, 27) for b, ln, m in CALL]
    s.add("Lonely Call", v["Lonely Call"],
          triosc([dict(wave=TRI, vol=50), dict(wave=SQUARE, vol=10, finel=5, finer=-5),
                  dict(wave=SINE, vol=20, coarse=12)]),
          eldata(1300, 0.6, vol_env=env("elvol", att=0.15, dec=0.5, sus=0.3, rel=0.8, amt=1)),
          [bitcrush(0.5, 12000, 128), delay(0.45, round(s.beat_s * 1.5, 4), 0.55),
           reverb(0.65, size=0.96, color=5000)], calls)
    return s

# ---------------------------------------------------------------- combat
COMBAT_VOLUMES = {  # mixer fader levels (100 = 0 dB), balanced from solo renders
    "Cave Drone": 12, "Onslaught Bass": 18, "Chug": 34, "Kick": 43,
    "Snare": 83, "Hats": 96, "Crash": 184, "Clanks": 54,
    "Siren": 12, "Alarm": 34, "Call Lead": 24, "Riser": 92,
}
COMBAT_LIMITER_GAIN = 12  # dB pushed into the master limiter: louder and more squashed = more aggressive

def distort(drive_db, rate=8000, levels=64, clip_db=-3):
    """Bitcrush driven into its own output clipper: hard-clipped, crushed distortion."""
    ctl = (f'ingain="{drive_db}" innoise="0" outgain="0" outclip="{clip_db}" rate="{rate}" stereodiff="0" '
           f'levels="{levels}" rateon="1" depthon="1"')
    return _effect("bitcrush", 1, f'<bitcrushcontrols {ctl}/><BitcrushControls {ctl}/>')

# Riff patterns, one character per 16th note:
#   X = power chord on E, A = power chord on the section's accent note, x = palm-muted E, . = rest
RIFFS = {
    "drive":  "X.xxX.xxA.xxX.xA",
    "stab":   "X..X..X..X..A...",      # 3-3-3-3-4 against the beat
    "gallop": "X.xxX.xxX.xxA.AA",
    "push":   "XxXxA.XxXxA.XXAA",
    "blast":  "XxXxXxXxAxAxXxXx",
    "slam":   "X.......A.......",      # half-time hits left to ring
    "stop":   "X.xxX.xxA.......",      # cuts out for beats 3-4: the hole before the next hit
}

# Each 16-bar section (one chord) has its own groove and riffs to pick from.
SECTIONS = [
    dict(groove="assault", riffs=["drive", "drive", "stab"], fills=["gallop", "push"]),
    dict(groove="grind",   riffs=["stab", "gallop", "drive"], fills=["push", "gallop"]),
    dict(groove="dbeat",   riffs=["blast"], fills=["push"]),          # last 4 bars become a slam
    dict(groove="onslaught", riffs=["push", "gallop", "drive"], fills=["gallop", "push"]),
]

CALL_MOTIFS = [  # the calm track's lonely call, bent out of shape: (beat, beats, midi)
    [(0, 3, 67), (3, 5, 64)],                   # G E   (as in calm)
    [(0, 3, 67), (3, 5, 65)],                   # G F   (b2 - wrong, threatening)
    [(0, 2, 70), (2, 6, 69)],                   # Bb A
    [(0, 1.5, 67), (1.5, 1.5, 64), (3, 5, 65)], # G E F
]

def build_combat() -> Song:
    s = Song(bpm=140, bars=64, mixer=True)
    v = COMBAT_VOLUMES
    quarter = s.bars // len(CHORDS)           # 16 bars per chord = 8 calm bars
    rng = random.Random(23)
    accents = [0, 1, 5, 1]                     # E, F, A, F above the pedal, per section

    # ---- decide the riff for every bar: varied per 4-bar phrase, never the same loop twice
    bar_riff, bar_groove = [], []
    for sec, cfg in enumerate(SECTIONS):
        for phrase in range(4):
            main = rng.choice(cfg["riffs"])
            alt = rng.choice([r for r in cfg["riffs"] if r != main] or [main])
            fill = rng.choice(cfg["fills"])
            plan = [main, main, alt, fill]
            groove = cfg["groove"]
            if cfg["groove"] == "dbeat" and phrase == 3:
                plan, groove = ["slam", "slam", "slam", "push"], "slam"
            if phrase == 3 and sec != 3:
                plan[3] = "stop"               # every section ends on a hole, then crashes back in
            bar_riff += plan
            bar_groove += [groove] * 4

    # ---- same chords as calm, now distorted
    pad = []
    for i, chord in enumerate(CHORDS):
        for j, m in enumerate(chord):
            pad.append(s.note(i * quarter, 0, quarter * 4, m, vol=85, pan=[-40, -15, 15, 40][j]))
    s.add("Cave Drone", v["Cave Drone"],
          triosc([dict(wave=SAW, vol=32, finel=-14, finer=14),
                  dict(wave=SAW, vol=25, finel=10, finer=-10, phase=90),
                  dict(wave=SQUARE, vol=25, coarse=-12)]),
          eldata(1400, 1.0, vol_env=env("elvol", att=0.2, rel=0.6, amt=1),
                 cut_env=env("elcut", lamt=0.3, lspd=0.08)),
          [distort(6, 10000, 128), reverb(0.35, size=0.9, color=5000)], pad)

    # ---- riff: distorted chugs, with the bass locked to them and filling every gap
    chugs, bass = [], []
    for bar in range(s.bars):
        acc = accents[bar // quarter]
        riff = bar_riff[bar]
        cutout = riff in ("stop", "slam")
        octave = 0
        for step, ch in enumerate(RIFFS[riff]):
            b = step * 0.25
            if ch in "XA":
                root = 52 + (acc if ch == "A" else 0)
                ln = 1.8 if riff == "slam" else 0.22
                for iv in (0, 7, 12):
                    chugs.append(s.note(bar, b, ln, root + iv, vol=100 if step % 4 == 0 else 88))
                octave = 12 - octave            # bass jumps octaves on every big hit
                bass.append(s.note(bar, b, ln, E_PEDAL + (acc if ch == "A" else 0) + octave, vol=100))
            elif ch == "x":
                chugs.append(s.note(bar, b, 0.18, 52, vol=60))
                bass.append(s.note(bar, b, 0.2, E_PEDAL, vol=80))
            elif not cutout:
                bass.append(s.note(bar, b, 0.2, E_PEDAL, vol=60))
    s.add("Chug", v["Chug"],
          triosc([dict(wave=SAW, vol=45, finel=-10, finer=10), dict(wave=SQUARE, vol=35, finel=9, finer=-9),
                  dict(wave=SAW, vol=30, coarse=-12)]),
          eldata(3000, 1.5, vol_env=env("elvol", dec=0.2, sus=0.4, rel=0.03, amt=1)),
          [distort(18, 7000, 48), reverb(0.15, size=0.8, color=4000)], chugs)
    s.add("Onslaught Bass", v["Onslaught Bass"],
          triosc([dict(wave=SAW, vol=50), dict(wave=SQUARE, vol=40, coarse=-12),
                  dict(wave=SAW, vol=20, finel=8, finer=-8)]),
          eldata(1600, 2.5, vol_env=env("elvol", dec=0.2, sus=0.5, rel=0.03, amt=1)),
          [distort(12, 7000, 64)], bass)

    # ---- drums: a different groove per section, fills and holes at phrase ends
    kicks, snares, hats, crashes = [], [], [], []
    for bar in range(s.bars):
        g, riff = bar_groove[bar], bar_riff[bar]
        K = lambda b, vol=100: kicks.append(s.note(bar, b, 0.25, 33, vol=vol))
        S = lambda b, vol=100: snares.append(s.note(bar, b, 0.25, 57, vol=vol))
        H = lambda b, vol=70: hats.append(s.note(bar, b, 0.25, 69, vol=vol, pan=rng.randint(-40, 40)))
        if g == "assault":
            for b in (0, 0.75, 1.5, 2, 2.75, 3.5): K(b)
            S(1); S(3)
            for i in range(16): H(i * 0.25, 90 if i % 2 else 55)
        elif g == "grind":
            for i in range(16): K(i * 0.25, 95 if i % 2 == 0 else 72)
            S(1); S(3)
            for i in range(8): H(i * 0.5, 85)
        elif g == "dbeat":                     # driving D-beat: kick 1, 3, 3-and; snare only on 2 and 4
            K(0); S(1); K(2); K(2.5, 90); S(3)
            for i in range(8): H(i * 0.5, 95 if i % 2 == 0 else 70)
        elif g == "slam":
            K(0); K(0.25, 80); K(2.75, 90); S(2)
            crashes.append(s.note(bar, 0, 4, 69, vol=100))
        elif g == "onslaught":
            for i in range(16): K(i * 0.25, 95 if i % 2 == 0 else 75)
            S(1); S(3); S(3.75, 70)
            for i in range(16): H(i * 0.25, 90 if i % 2 else 60)
            if bar % 2 == 0:
                crashes.append(s.note(bar, 0, 4, 69, vol=90))
        if riff == "stop":                     # hole: drums cut on beat 3, one flam, then silence
            kicks[:] = [n for n in kicks if not (n["pos"] >= bar * BAR + 2 * BEAT and n["pos"] < (bar + 1) * BAR)]
            snares[:] = [n for n in snares if not (n["pos"] >= bar * BAR + 2 * BEAT and n["pos"] < (bar + 1) * BAR)]
            hats[:] = [n for n in hats if not (n["pos"] >= bar * BAR + 2 * BEAT and n["pos"] < (bar + 1) * BAR)]
            S(3.5, 70); S(3.75, 100)
        elif bar % 4 == 3 and g != "slam":     # fill over the last beat, picked at random
            fill = rng.choice(["roll", "unison", "kicks"])
            snares[:] = [n for n in snares if n["pos"] < bar * BAR + 3 * BEAT or n["pos"] >= (bar + 1) * BAR]
            if fill == "roll":
                for i in range(4): S(3 + i * 0.25, 60 + i * 13)
            elif fill == "unison":
                for b in (3, 3.5, 3.75): K(b); S(b)
            else:
                for i in range(4): K(3 + i * 0.25, 100)
                S(3.75)
        if bar % quarter == 0:
            crashes.append(s.note(bar, 0, 4, 69, vol=100))

    s.add("Kick", v["Kick"],
          kicker(160, 40, 220, dist=1.4, distend=0.8, noise=0.1, click=0.45, slope=0.3, env=0.2),
          eldata(wet=0), [distort(4, 11025, 256)], kicks)
    s.add("Snare", v["Snare"],
          kicker(240, 130, 200, dist=0.9, noise=0.9, click=0.5, slope=0.06, env=0.6),
          eldata(wet=0), [distort(8, 9000, 96), reverb(0.3, size=0.88, color=6000)], snares)
    s.add("Hats", v["Hats"],
          kicker(150, 40, 50, dist=0.8, noise=1, click=0.4, slope=0.06, env=0.2),
          eldata(7000, 0.5, ftype=HIPASS), [bitcrush(0.6, 12000, 256)], hats)
    s.add("Crash", v["Crash"],
          kicker(400, 300, 1600, dist=0.3, noise=1, click=0.5, slope=0.06, env=0.5),
          eldata(3500, 0.5, ftype=HIPASS), [bitcrush(0.8, 9000, 128), reverb(0.4, size=0.9)], crashes)

    # ---- metal: irregular hammering, denser later, plus an anvil on the backbeat in the grinding parts
    clanks = []
    for bar in range(s.bars):
        g = bar_groove[bar]
        p = 0.08 if bar < quarter else 0.12 if bar < 2 * quarter else 0.18
        for i in range(16):
            if rng.random() < p:
                clanks.append(s.note(bar, i * 0.25, 0.25, rng.choice([73, 76, 78, 80, 83, 85]),
                                     vol=rng.randint(65, 100), pan=rng.randint(-70, 70)))
        if g in ("grind", "onslaught"):
            clanks += [s.note(bar, b, 0.25, 80, vol=60) for b in (1, 3)]
    s.add("Clanks", v["Clanks"],
          triosc([dict(wave=SQUARE, vol=80), dict(wave=SQUARE, vol=60, coarse=7, finel=13, finer=-17),
                  dict(wave=NOISE, vol=50)]),
          eldata(wet=0, vol_env=env("elvol", dec=0.2, sus=1, rel=0.15, amt=1)),
          [bitcrush(0.9, 8000, 64), delay(0.25, round(s.beat_s * 0.75, 4), 0.4),
           reverb(0.45, size=0.92, color=5000)], clanks)

    # ---- tritone siren tones over the second half: Bb against the E pedal, then B against F
    siren = [s.note(32, 0, 32, 70, vol=80), s.note(40, 0, 32, 70, vol=80), s.note(40, 0, 32, 76, vol=70),
             s.note(48, 0, 64, 71, vol=85), s.note(52, 0, 48, 77, vol=75)]
    s.add("Siren", v["Siren"],
          triosc([dict(wave=SQUARE, vol=40), dict(wave=SAW, vol=30, finel=12, finer=-12),
                  dict(wave=SINE, vol=0)]),
          eldata(1800, 1.5, vol_env=env("elvol", att=0.5, rel=0.5, amt=1),
                 cut_env=env("elcut", lamt=0.25, lspd=0.2)),
          [distort(6, 9000, 128), reverb(0.4, size=0.9)], siren)

    # ---- alarm: a frantic E/F trill (32nd notes) over the slam bars and through the last section
    alarm = []
    for bar in [b for b in range(s.bars) if bar_groove[b] == "slam"] + list(range(49, 62, 4)):
        for i in range(16):
            alarm.append(s.note(bar, i * 0.125, 0.12, 76 if i % 2 == 0 else 77, vol=85))
    s.add("Alarm", v["Alarm"],
          triosc([dict(wave=SQUARE, vol=50), dict(wave=SQUARE, vol=30, coarse=12), dict(wave=SINE, vol=0)]),
          eldata(3000, 1.0, vol_env=env("elvol", rel=0.05, amt=1)),
          [bitcrush(1.0, 7000, 32), reverb(0.3, size=0.85)], alarm)

    # ---- the lonely call, now shouted and bent out of shape at irregular moments
    calls = []
    for bar in range(1, s.bars - 2, 4):
        if bar_groove[bar] == "slam" or rng.random() < 0.3:
            continue
        up = 12 if bar >= 3 * quarter else 0
        for b, ln, m in rng.choice(CALL_MOTIFS):
            calls.append(s.note(bar, b, ln, m + up, vol=95))
    s.add("Call Lead", v["Call Lead"],
          triosc([dict(wave=SQUARE, vol=45), dict(wave=SAW, vol=30, finel=7, finer=-7),
                  dict(wave=SQUARE, vol=15, coarse=-12)]),
          eldata(2400, 1.2, vol_env=env("elvol", att=0.03, dec=0.4, sus=0.25, rel=0.3, amt=1)),
          [distort(10, 9000, 64), delay(0.3, round(s.beat_s * 0.75, 4), 0.4),
           reverb(0.35, size=0.9)], calls)

    # ---- noise riser over the last 2 bars, throwing the loop straight back into bar 1
    s.add("Riser", v["Riser"],
          triosc([dict(wave=NOISE, vol=60), dict(wave=SAW, vol=20, coarse=12), dict(wave=SINE, vol=0)]),
          eldata(300, 2.0, vol_env=env("elvol", att=0.75, rel=0.05, amt=1),
                 cut_env=env("elcut", att=0.8, sus=0, amt=1)),
          [bitcrush(0.7, 8000, 128)], [s.note(s.bars - 2, 0, 8, 76, vol=100)])
    return s

# ---------------------------------------------------------------- chaos warning rumble
RUMBLE_VOLUMES = {"Rumble Noise": 70, "Sub Swell": 40, "Footfalls": 80}

def build_rumble() -> Song:
    """10 s sound effect for the warning before a wave: a low rumble that swells while
    distant footfalls speed up. Same crushed style and low E as the cave songs."""
    s = Song(bpm=96, bars=4)                   # 4 bars at 96 BPM = 10 s
    v = RUMBLE_VOLUMES
    length = s.bars * 4
    s.add("Rumble Noise", v["Rumble Noise"],
          triosc([dict(wave=NOISE, vol=70), dict(wave=NOISE, vol=0), dict(wave=SINE, vol=0)]),
          eldata(140, 0.6, vol_env=env("elvol", att=1.25, rel=0.4, amt=1),
                 cut_env=env("elcut", att=1.3, sus=0, amt=0.35)),   # opens up as it builds
          [bitcrush(0.7, 8000, 128), reverb(0.4, size=0.9, color=2000)], [s.note(0, 0, length, 57)])
    s.add("Sub Swell", v["Sub Swell"],
          triosc([dict(wave=SINE, vol=60, coarse=-12, finel=-5, finer=5), dict(wave=TRI, vol=20),
                  dict(wave=SINE, vol=0)]),
          eldata(300, 0.5, vol_env=env("elvol", att=1.2, rel=0.4, amt=1)),
          [], [s.note(0, 0, length, E_PEDAL)])
    # footfalls: 1 per bar, then 2, then 4, then 8 - getting closer and faster
    steps = []
    for bar, count in enumerate((1, 2, 4, 8)):
        for i in range(count):
            steps.append(s.note(bar, i * 4 / count, 0.5, 33, vol=40 + bar * 18 + i * 2))
    s.add("Footfalls", v["Footfalls"],
          kicker(90, 32, 380, dist=0.7, distend=0.3, noise=0.15, click=0.1, slope=0.25, env=0.3),
          eldata(500, 0.6), [bitcrush(0.8, 6000, 96), reverb(0.5, size=0.94, color=2500)], steps)
    return s

VARIANTS = {  # name -> (builder, project notes, master channel effects)
    "calm": (build_calm, "Desolatum - Cave level, calm. E minor, 70 BPM, 32 bars. Cave ambience "
             "with a low slow beat; a lonely call every 8 bars. Master Bitcrush 16 kHz / 8-bit / 75% wet.",
             [bitcrush(0.75, 16000, 256)]),
    "combat": (build_combat, "Desolatum - Cave level, enemy waves. E minor, 140 BPM, 64 bars; same chords "
               "and length as calm, so the two can crossfade in sync. Master Bitcrush 16 kHz / 8-bit / 75% wet, "
               "then a Fast Lookahead Limiter (+COMBAT_LIMITER_GAIN dB in, -0.5 dB ceiling).",
               [bitcrush(0.75, 16000, 256), limiter(COMBAT_LIMITER_GAIN)]),
    "rumble": (build_rumble, "Desolatum - chaos warning rumble (sound effect, 10 s). Low rumble swelling "
               "over distant footfalls that speed up. Export without looping: the tail should ring out.",
               [bitcrush(0.75, 16000, 256), limiter(4)]),
}

if __name__ == "__main__":
    if len(sys.argv) != 3 or sys.argv[1] not in VARIANTS:
        sys.exit(f"usage: python make_cave_music.py [{'|'.join(VARIANTS)}] OUT.mmp")
    build, text, master_fx = VARIANTS[sys.argv[1]]
    text = text.replace("COMBAT_LIMITER_GAIN", str(COMBAT_LIMITER_GAIN))
    build().write(sys.argv[2], text + ' Loop markers cover the whole song; export with '
                  '"Export between loop markers" for a seamless game loop.', master_fx)

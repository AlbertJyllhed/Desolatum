"""Generates an LMMS 1.2.2 project (.mmp) for the Desolatum ship hub theme.

Draft 2: dark, lo-fi industrial ambience rather than a melody piece.
Key: B minor (with a Phrygian C for darkness). 60 BPM, 4/4, 32 bars (~128 s), loops bar 1 -> 33.
Long drone chords over a low B pedal, air noise, a slow distant machine pulse,
rare metallic clanks, two distant beacon pings, and a few sparse echo notes.
The whole mix goes through a bitcrusher on the master channel for a gritty, low-quality sound.
The single warm moment is the Gmaj7 at bars 25-28.

Usage (from the project root):
    python music/make_ship_hub.py music/ship_hub_theme.mmp
This overwrites the .mmp, so any changes made by hand in LMMS will be lost.
"""
import sys
from xml.sax.saxutils import quoteattr

BPM = 60
BEAT = 48            # LMMS ticks per beat
BAR = BEAT * 4
BARS = 32
beat_s = 60.0 / BPM

def k(midi: int) -> int:
    """MIDI note -> LMMS key (LMMS A4 = 57, MIDI A4 = 69)."""
    return midi - 12

# ---------------------------------------------------------------- harmony
# (start bar, length in bars, pad voicing MIDI, bass root MIDI)
CHORDS = [
    (0, 4,  [50, 54, 57, 61], 47),   # Bm9          D F# A C#  / B
    (4, 4,  [48, 55, 59, 64], 47),   # Cmaj7/B      C G B E    / B  (dark b2)
    (8, 4,  [52, 55, 59, 66], 47),   # Em9/B        E G B F#   / B
    (12, 4, [50, 54, 57, 61], 47),   # Bm9
    (16, 4, [50, 54, 57, 61], 47),   # Bm9
    (20, 4, [48, 55, 59, 64], 47),   # Cmaj7/B
    (24, 4, [50, 55, 59, 66], 43),   # Gmaj7        D G B F#   / G  (the warm moment)
    (28, 4, [54, 59, 61, 66], 42),   # F#sus4       F# B C# F# / F# (leads back to Bm)
]

def note(bar: float, beat: float, length_beats: float, midi: int, vol: int = 100, pan: int = 0):
    return dict(pos=int(bar * BAR + beat * BEAT), len=int(length_beats * BEAT),
                key=k(midi), vol=vol, pan=pan)

def pad_notes():
    out = []
    for start, n, voicing, _ in CHORDS:
        for j, m in enumerate(voicing):
            out.append(note(start, 0, n * 4, m, vol=80, pan=[-35, -12, 12, 35][j]))
    return out

def bass_notes():
    return [note(start, 0, n * 4, root, vol=90) for start, n, _, root in CHORDS]

def air_notes():
    # one note for the whole song: constant ventilation hiss, so the loop point is seamless
    return [note(0, 0, BARS * 4, 57, vol=100)]

def pulse_notes():
    # distant machinery: a soft double thump every 2 bars, dropping out for the warm moment
    out = []
    for bar in range(0, BARS, 2):
        if 24 <= bar < 28:
            continue
        out.append(note(bar, 0, 0.5, 35, vol=90))
        out.append(note(bar, 0.75, 0.5, 35, vol=60))
    return out

CLANKS = [  # (bar, beat, midi, vol, pan) - irregular on purpose
    (2, 2.5, 78, 70, -50), (6, 1.0, 73, 55, 40), (10, 3.25, 80, 65, 60),
    (13, 0.5, 71, 50, -30), (18, 2.0, 76, 70, 50), (22, 3.5, 74, 55, -60),
    (29, 1.25, 79, 60, 30),
]

def clank_notes():
    return [note(b, bt, 0.25, m, vol=v, pan=p) for b, bt, m, v, p in CLANKS]

def beacon_notes():
    # the old bell, now just two distant pings
    return [note(7, 2, 1, 66, vol=70), note(23, 2, 1, 59, vol=70)]

ECHO = [  # sparse notes, more a memory of a melody than a tune: (bar, beat, beats, midi)
    (17, 0, 4, 66), (18, 0, 2, 64), (18, 2, 6, 62),       # F# E D  over Bm
    (25, 0, 3, 62), (25, 3, 1, 66), (26, 0, 8, 69),       # D F# A  over Gmaj7 (the warm lift)
    (29, 0, 4, 59), (30, 0, 7, 61),                       # B C#    over F#sus4
]

def echo_notes():
    return [note(b, bt, ln, m, vol=75) for b, bt, ln, m in ECHO]

# ---------------------------------------------------------------- instruments
SINE, TRI, SAW, SQUARE, MOOGSAW, EXP, NOISE = 0, 1, 2, 3, 4, 5, 6
LOWPASS, HIPASS, BANDPASS, MOOG = 0, 1, 2, 6

def triosc(oscs):
    a = {"modalgo1": 2, "modalgo2": 2, "modalgo3": 2}
    for i, o in enumerate(oscs):
        a.update({f"wavetype{i}": o["wave"], f"vol{i}": o["vol"], f"coarse{i}": o.get("coarse", 0),
                  f"finel{i}": o.get("finel", 0), f"finer{i}": o.get("finer", 0),
                  f"pan{i}": o.get("pan", 0), f"phoffset{i}": o.get("phase", 0),
                  f"stphdetun{i}": o.get("stph", 0), f"userwavefile{i}": ""})
    return "<tripleoscillator " + " ".join(f"{n}={quoteattr(str(v))}" for n, v in a.items()) + "/>"

def env(tag, att=0.0, dec=0.0, sus=0.0, rel=0.1, amt=0.0, lamt=0.0, lspd=0.1):
    # LMMS: times are knob values (seconds ~ v*v*5); sus=0 means full sustain level.
    return (f'<{tag} pdel="0" att="{att}" hold="0" dec="{dec}" sus="{sus}" rel="{rel}" amt="{amt}" '
            f'lpdel="0" latt="0" lspd="{lspd}" lamt="{lamt}" lshp="0" x100="0" ctlenvamt="0" '
            f'userwavefile="" lfosyncmode="0"/>')

def eldata(fcut, fres, ftype=LOWPASS, vol_env="", cut_env=""):
    return (f'<eldata fres="{fres}" ftype="{ftype}" fcut="{fcut}" fwet="1">{vol_env}'
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

def track(name, vol, osc_xml, eldata_xml, effects, notes, pan=0):
    notes_xml = "\n".join(
        f'          <note pan="{n["pan"]}" key="{n["key"]}" vol="{n["vol"]}" pos="{n["pos"]}" len="{n["len"]}"/>'
        for n in sorted(notes, key=lambda n: n["pos"]))
    return f'''      <track muted="0" type="0" name={quoteattr(name)} solo="0">
        <instrumenttrack pan="{pan}" fxch="0" pitchrange="1" pitch="0" basenote="57" vol="{vol}">
          <instrument name="tripleoscillator">{osc_xml}</instrument>
          {eldata_xml}
          <chordcreator chord="0" chordrange="1" chord-enabled="0"/>
          <arpeggiator arptime="100" arprange="1" arpmode="0" arp-enabled="0" arp="0" arpdir="0" arpgate="100" syncmode="0"/>
          <midiport inputcontroller="0" fixedoutputvelocity="-1" inputchannel="0" outputcontroller="0" writable="0" outputchannel="1" fixedinputvelocity="-1" fixedoutputnote="-1" outputprogram="1" basevelocity="63" readable="0"/>
          <fxchain numofeffects="{len(effects)}" enabled="{1 if effects else 0}">{"".join(effects)}</fxchain>
        </instrumenttrack>
        <pattern muted="0" steps="16" name={quoteattr(name)} pos="0" len="{BARS * BAR}" type="1">
{notes_xml}
        </pattern>
      </track>'''

VOLUMES = {  # track volumes, balanced from solo renders
    "Hull Drone": 34,
    "Sub Pedal": 15,
    "Air Vents": 67,
    "Machine Pulse": 83,
    "Metal Clanks": 200,
    "Beacon": 33,
    "Echo Tone": 36,
}

tracks = [
    track("Hull Drone", VOLUMES["Hull Drone"],
          triosc([dict(wave=SAW, vol=30, finel=-11, finer=11),
                  dict(wave=SQUARE, vol=18, finel=7, finer=-7, phase=90),
                  dict(wave=SAW, vol=28, coarse=-12, finel=4, finer=-4)]),
          eldata(700, 0.8, ftype=LOWPASS,
                 vol_env=env("elvol", att=0.35, sus=0, rel=0.75, amt=1),
                 cut_env=env("elcut", lamt=0.18, lspd=0.025)),     # slow breathing filter
          [reverb(0.5, size=0.9, color=6000)], pad_notes()),
    track("Sub Pedal", VOLUMES["Sub Pedal"],
          triosc([dict(wave=SINE, vol=60, coarse=-12), dict(wave=TRI, vol=30),
                  dict(wave=SAW, vol=6, finel=5, finer=-5)]),
          eldata(400, 0.8, vol_env=env("elvol", att=0.2, sus=0, rel=0.5, amt=1)),
          [], bass_notes()),
    track("Air Vents", VOLUMES["Air Vents"],
          triosc([dict(wave=NOISE, vol=60), dict(wave=NOISE, vol=0), dict(wave=SINE, vol=0)]),
          eldata(800, 2.0, ftype=LOWPASS,
                 vol_env=env("elvol", att=0, sus=0, rel=0.5, amt=1),
                 cut_env=env("elcut", lamt=0.3, lspd=0.015)),
          [reverb(0.35, size=0.8, color=4000)], air_notes()),
    track("Machine Pulse", VOLUMES["Machine Pulse"],
          triosc([dict(wave=SINE, vol=70), dict(wave=SQUARE, vol=20, coarse=-12),
                  dict(wave=NOISE, vol=6)]),
          eldata(260, 1.0, ftype=LOWPASS, vol_env=env("elvol", att=0.02, dec=0.35, sus=1, rel=0.3, amt=1)),
          [bitcrush(0.6, 6000, 64), reverb(0.55, size=0.92, color=3000)], pulse_notes()),
    track("Metal Clanks", VOLUMES["Metal Clanks"],
          triosc([dict(wave=SQUARE, vol=80), dict(wave=SQUARE, vol=60, coarse=7, finel=13, finer=-17),
                  dict(wave=NOISE, vol=50)]),
          eldata(2500, 2.0, ftype=BANDPASS, vol_env=env("elvol", att=0, dec=0.25, sus=1, rel=0.2, amt=1)),
          [bitcrush(1.0, 8000, 32), delay(0.35, round(beat_s * 0.75, 4), 0.45),
           reverb(0.7, size=0.95, color=5000)], clank_notes()),
    track("Beacon", VOLUMES["Beacon"],
          triosc([dict(wave=SINE, vol=70), dict(wave=SQUARE, vol=10, coarse=12), dict(wave=TRI, vol=0)]),
          eldata(1800, 0.7, vol_env=env("elvol", att=0, dec=0.65, sus=1, rel=0.6, amt=1)),
          [bitcrush(1.0, 9000, 32), delay(0.35, round(beat_s * 1.5, 4), 0.5),
           reverb(0.65, size=0.95, color=5000)], beacon_notes()),
    track("Echo Tone", VOLUMES["Echo Tone"],
          triosc([dict(wave=TRI, vol=50), dict(wave=SQUARE, vol=12, finel=6, finer=-6),
                  dict(wave=SINE, vol=25, coarse=-12)]),
          eldata(900, 0.6, vol_env=env("elvol", att=0.4, sus=0.1, dec=0.6, rel=0.7, amt=1)),
          [delay(0.25, round(beat_s * 0.75, 4), 0.4), reverb(0.6, size=0.92, color=6000)], echo_notes()),
]

end = BARS * BAR
project = f'''<?xml version="1.0"?>
<!DOCTYPE lmms-project>
<lmms-project version="1.0" creator="LMMS" creatorversion="1.2.2" type="song">
  <head timesig_numerator="4" mastervol="100" timesig_denominator="4" bpm="{BPM}" masterpitch="0"/>
  <song>
    <trackcontainer width="600" x="5" y="5" maximized="0" height="300" visible="1" type="song" minimized="0">
{chr(10).join(tracks)}
    </trackcontainer>
    <fxmixer width="543" x="5" y="310" maximized="0" height="333" visible="1" minimized="0">
      <fxchannel soloed="0" num="0" muted="0" volume="1" name="Master">
        <fxchain numofeffects="1" enabled="1">{bitcrush(0.75, 16000, 256)}</fxchain>
      </fxchannel>
    </fxmixer>
    <controllers/>
    <timeline lp0pos="0" lp1pos="{end}" lpstate="1"/>
    <projectnotes width="400" x="700" y="10" maximized="0" height="300" visible="0" minimized="0"><![CDATA[Desolatum - Ship Hub theme (draft 2). Dark lo-fi industrial ambience. B minor, {BPM} BPM, {BARS} bars. Master channel has a Bitcrush (16 kHz, 8-bit, 75% wet) for the gritty sound. Loop markers cover the whole song; export with "Export between loop markers" for a seamless game loop.]]></projectnotes>
  </song>
</lmms-project>
'''

with open(sys.argv[1], "w", encoding="utf-8", newline="\n") as f:
    f.write(project)
print("wrote", sys.argv[1], f"({BARS} bars, {BARS * 4 * beat_s:.1f} s)")

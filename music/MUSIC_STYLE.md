# Desolatum music style guide

Instructions for Claude (and anyone else) making new music or sound effects for
Desolatum that match the existing songs. Read this before writing a new song.

## The sound

- **Late-90s sci-fi shooter mood**, inspired by the feel of Half-Life 1's
  soundtrack: dark, industrial, lo-fi. Take the *style* only. Never copy or
  imitate a real game's actual music, themes or melodies.
- **Bit-crushed and low quality on purpose.** Everything goes through a
  bitcrusher on the master channel (16 kHz, 8-bit, 75% wet). Some tracks get a
  harder crush of their own (5-6 bit, 6-9 kHz).
- **Ambience over melody.** Long drones and textures carry the songs. Melody is
  rare and short: a two-note call, a few sparse notes. Never a lead melody that
  runs through the whole song.
- **Dark harmony**: minor keys with a Phrygian flat 2 (Cmaj7 over a B pedal in
  B minor, Fmaj7 over an E pedal in E minor). Chords sit over a low pedal note
  that never moves. A single warmer chord can give a hint of hope.
- **Loneliness**: calls that are only answered by their own echo, silences
  where the beat drops out, distant sounds with big crushed reverbs.
- **Combat is aggressive and relentless**: distorted power-chord chugs, a
  16th-note bass, industrial drums, metal clanks, tritone sirens, and a heavy
  master limiter. It must feel like a never-ending onslaught, but **not
  formulaic**: vary riffs per 4-bar phrase, give each section its own groove,
  add fills and sudden holes.

### What the user liked and disliked (from feedback on the drafts)

| Liked | Disliked |
|---|---|
| Dark, slow, bit-crushed ambience (ship hub draft 2) | Bright, melodic, bell-heavy music (ship hub draft 1) |
| A low, steady rumble under the cave music | Resonant, moaning "cave wind" (band-passed noise with a sweep) |
| Distorted chugs, aggressive combat | Combat that's too tame or too formulaic (same 1-bar loop for 64 bars) |
| Melody that stays audible through the combat | A constant blast-beat snare (every 16th): too intense |
| Clean structure: sections that change, holes before the next hit | |

When a draft is too much in one place, ask which part. The user first blamed
the chug, then found it was the drums in one section.

## How the music is made

The songs aren't arranged by hand. Python scripts in `music/` write LMMS 1.2.2
projects (`.mmp`, plain XML), and LMMS renders them from the command line.
This makes every number reviewable and lets a song be changed by editing code.

| Script | Makes |
|---|---|
| `music/make_ship_hub.py` | `ship_hub_theme.mmp`: ship hub, B minor, 60 BPM, 32 bars (128 s) |
| `music/make_cave_music.py calm` | `cave_calm.mmp`: cave level, E minor, 70 BPM, 32 bars (109.7 s) |
| `music/make_cave_music.py combat` | `cave_combat.mmp`: cave enemy waves, E minor, 140 BPM, 64 bars (109.7 s) |
| `music/make_cave_music.py rumble` | `chaos_rumble.mmp`: 10 s warning sound before a wave |
| `music/balance_mix.py` | Measures and rebalances a song's track volumes (see its docstring) |

Running a generator overwrites its `.mmp`, so hand edits made in LMMS are
lost. Either change the script, or tune by hand in LMMS and stop running it.

`make_cave_music.py` is the most complete toolkit: a `Song` class (notes,
tracks, optional per-track mixer channels, writing the project) and helpers
for TripleOscillator (`triosc`), Kicker drums (`kicker`), envelopes (`env`,
`eldata`) and effects (`reverb`, `delay`, `bitcrush`, `distort`, `limiter`).
Reuse it for new songs: add a `build_<name>()` function, a volume table and an
entry in `VARIANTS`.

### Workflow for a new song

1. Ask what it's for, the mood, and which existing song it should match. Ask
   about anything that changes the feel before building it.
2. Write the builder: harmony first (pedal note plus 4 chords), then layers.
3. Generate the `.mmp`, check the XML parses, render with LMMS and measure it.
4. Balance with `balance_mix.py` from a scratch folder. Check: no clipping, the
   section levels, and the loop seam.
5. Give the user the `.mmp` and a WAV render to listen to, and say what to
   listen for. You can't hear the result; measurements only show levels.
6. Iterate on their feedback. Keep each change small and say what changed.
7. When it's approved, export the game file (see below).

### Commands

```bash
python music/make_cave_music.py calm music/cave_calm.mmp
"/c/Program Files/LMMS/lmms.exe" render music/cave_calm.mmp -f wav -o <scratch>/cave_calm.wav
"/c/Program Files/LMMS/lmms.exe" render music/cave_calm.mmp -l -f ogg -b 160 -o sounds/music/cave_calm.ogg
```

`-l` ("render as a loop") cuts the reverb tail so the file is exactly one loop
long. Use it for songs, not for one-shot sound effects like the rumble.

## Mix targets

- Ambient songs (hub, cave calm): about **-18 dB** average, peaks under 0.8, no clipping.
- Combat: about **-10.5 dB**, held at the limiter's ceiling (0.94) with no
  clipping, about 7.5 dB louder than calm. Master chain is bitcrush, then the
  Fast Lookahead Limiter at +12 dB in, -0.5 dB ceiling.
- Typical solo levels (average while the track sounds): drone -21 to -24, sub
  -24, rumble -27, kick -17 to -21, snare -20 to -24, sparse effects (drips,
  clanks, beacon) -27 to -33, calls and leads -23 to -27.
- Keep the loop seam within about 2 dB (last half bar vs first half bar).

## Instrument recipes that worked

- **Drone pad**: two detuned saws (fine detune ±9 to ±14 cents) plus a square
  or triangle an octave down. Low-pass at 550-1400 Hz, slow LFO on the cutoff
  (`lamt` 0.2-0.3, `lspd` 0.02-0.08), long attack and release, big reverb.
- **Sub pedal**: sine an octave down plus a quiet triangle, low-pass 350-400 Hz.
- **Low rumble**: noise low-passed at about 140 Hz with **no resonance**, plus
  a slowly beating low sine pair, with a very slow LFO swell on the volume.
- **Heartbeat beat**: Kicker 85→32 Hz, 520 ms, light distortion, crushed
  (8 kHz), two hits ("lub-dub", the second softer, a 16th later).
- **Water drips**: short sine blips from the minor pentatonic, high octave,
  crushed (11 kHz, 6-bit), delay and a huge reverb, random timing from a seeded RNG.
- **Lonely call**: triangle plus a little square, two notes (G→E), a 1.5-beat
  delay with 0.55 feedback so the echo is the only answer.
- **Metal clanks**: two detuned squares (one a fifth up) plus noise, short
  decay, hard crush (8 kHz, 5-bit), delay and reverb, irregular timing.
- **Combat chug**: two detuned saws plus a square, power chord (root, fifth,
  octave), heavily distorted with `distort(18, 7000, 48)`, low-pass 3 kHz.
- **Combat drums** (Kicker): kick 160→40 Hz, 220 ms, dist 1.4; snare 240→130
  Hz, noise 0.9; hats as short noise through a high-pass at 7 kHz; crash as
  long noise through a high-pass.
- Use a seeded `random.Random(n)` for anything random, so a song regenerates the same.

## LMMS 1.2.2 file quirks (learned the hard way)

- **Note numbers**: LMMS key = MIDI note - 12 (LMMS A4 = 57).
- **Ticks**: 48 per beat, 192 per bar.
- **Envelope times** are knob values: seconds ≈ value² × 5 (0.6 is about 1.8 s).
- **Sustain is inverted**: `sus="0"` means full sustain level, `sus="1"` decays to silence.
- **Effect settings element names**: `ReverbSCControls` (`input_gain`, `size`,
  `color`, `output_gain`), `Delay` / `DelayControls` (`DelayTimeSamples` is in
  seconds, `FeebackAmount` is spelled that way), `bitcrushcontrols` (`rate` in
  Hz; `levels` is the number of steps, 256 = 8-bit; plus `rateon`, `depthon`,
  `ingain`, `outclip`). The helpers write both spellings where unsure.
- **Distortion**: bitcrush with a high `ingain` and `outclip` around -3 dB
  hard-clips (that's `distort()`).
- **Limiter**: LADSPA `fast_lookahead_limiter_1913.so`, plugin
  `fastLookaheadLimiter`, ports 0 = input gain dB, 1 = ceiling dB, 2 = release.
- **Moog filter (ftype 6) with resonance can blow up** and clip hard. Use the
  normal low-pass (ftype 0).
- **Don't crush a quiet signal**: a band-pass filter before a 5-bit crush
  rounded a drum down to silence. Crush before filtering, or use more levels.
- **Track volume is applied before the track's effects.** On a distorted track
  it only changes how hard the distortion is driven, not the loudness. For
  songs with distortion, use `Song(mixer=True)`: every track gets its own mixer
  channel and the volume table sets the faders.
- The project's own `<fxchannel>` entries need `<send amount="1" channel="0"/>` to reach the master.
- `lmms --help` lists the render options; WAV renders are handy for measuring
  with Python's `wave` module (no numpy is installed).

## Music in the game

- `autoload/music_player.gd` (the `MusicPlayer` autoload) plays everything on a
  "Music" bus it creates if missing. A song with the same streams keeps
  playing across scenes. Songs fade in over 1.5 s.
- **Two layers**: calm and combat play in sync from the same start; enemy waves
  (`GameEvents.wave_updated`) crossfade between them over 1.5 s (equal power).
  The two files **must be the same length to the sample**. Build combat at
  double tempo with twice the bars so the chord changes line up.
- Before a wave (`GameEvents.chaos_warning`) the combat layer creeps in to 20%.
- Pause muffles the music (quieter, low-pass, lo-fi crunch); death does it
  harder and sags the pitch to 80% until the next scene.
- Biome levels get their music from `BiomeData` (`calm_music`,
  `combat_music`). Other scenes use a `MusicCue` node
  (`systems/audio/music_cue.gd`). Scenes with no music keep the current song.
- Game files live in `sounds/music/*.ogg` (songs) and `sounds/*.ogg` (effects).
  `MusicPlayer` turns looping on itself, so no import settings are needed.

## Existing songs at a glance

- **Ship hub** (`make_ship_hub.py`): B minor, 60 BPM. Hull Drone (Bm9,
  Cmaj7/B, Em9/B, then one warm Gmaj7, F#sus4 back), Sub Pedal on B, Air
  Vents hiss, Machine Pulse double thump every 2 bars, Metal Clanks, two
  Beacon pings, sparse Echo Tone notes.
- **Cave calm**: E minor, 70 BPM, chords 8 bars each (Em9, Fmaj7/E,
  Am(add9)/E, Fmaj7#11/E) over an E pedal. Low Rumble, a heartbeat Low Beat
  plus a Distant Tap (both drop out for bars 17-18), Water Drips, a Lonely
  Call every 8 bars.
- **Cave combat**: the same chords at 140 BPM, 16 bars each. Four sections
  with their own grooves: Assault (syncopated kicks), Grind (double-kick),
  D-beat (snare only on 2 and 4, then half-time slams with an alarm trill),
  Onslaught. Riffs picked per phrase from a set, random fills, holes at section
  ends, bent versions of the lonely call, tritone sirens, a noise riser into the loop.
- **Chaos rumble** (effect, 10 s): low noise opening up, a sub swell on E,
  crushed footfalls speeding up (1, 2, 4, then 8 per bar).

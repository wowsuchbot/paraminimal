# Sound Layer Design

The sonic architecture of Paraminimal — what it sounds like, layer by layer.

## Overview

Paraminimal produces music through three independent but coordinated sound layers. Each layer has its own role in the texture, its own scheduling logic, and its own relationship to the composition state.

```
Layer          Role                    Entry     Rhythm
─────────────────────────────────────────────────────────
Drone          Harmonic foundation     0s        Continuous
Melodic        Motif-driven melody     +6s       Euclidean grid
Textural       Sparse sonic fragments  +12s      Sparse Euclidean grid
```

The staggered entry (0s, +6s, +12s) is intentional — it mirrors how acoustic music begins. The foundation arrives first, the voice enters, then the atmosphere.

---

## 1. Drone Layer

### 1.1 Role

The drone is the harmonic bed. It establishes the tonal center, the register, and the overall energy level. It doesn't play notes — it sustains pitches. It's the ground the melody walks on.

### 1.2 Voices

The drone consists of two sub-voices:

**Pad voice** — sustained chord tones using a warm, slightly detuned synthesizer.
- Synth: `prophet` — a sawtooth-based pad with slow attack and long release
- Voices: 3–4 pitches from the current chord shape
- Detune: slight (3–8 cents between voices) for warmth and width
- Filter: low-pass, cutoff modulated by epoch energy (higher energy = brighter)

**Sub voice** — a deep, nearly sub-audible foundation.
- Synth: `dark_ambience` — filtered noise + sine wave combination
- Pitch: root, two octaves below the chord
- Role: weight and depth. Barely audible on small speakers, essential on full systems.
- Stagger: the sub voice fades in 18s after audio start, the pad voice at 25s. This prevents the initial moment from being overwhelming.

### 1.3 Chord Shapes

Chord voice selection is determined by the epoch's `chord_shape` field, which maps to period:

| Period | Chord Shape | Voices (scale degrees) | Character |
|--------|------------|----------------------|-----------|
| Deep Night | `:cluster` | Root + b3 + b5 + bb7 (0, 3, 6, 10) | Dense, ambiguous, dark |
| Dawn | `:open_fifth` | Root + fifth (0, 7) | Open, spacious, luminous |
| Morning | `:triad` | Root + third + fifth (0, 4, 7) | Clear, stable, bright |
| Afternoon | `:sixth` | Root + third + fifth + sixth (0, 4, 7, 9) | Warm, flowing, extended |
| Twilight | `:seventh` | Root + third + fifth + seventh (0, 4, 7, 10) | Wistful, unresolved, jazz-tinged |
| Night | `:suspended` | Root + fourth + fifth (0, 5, 7) | Floating, tense, expectant |

Voice pitches are computed by adding the chord degree intervals to the root MIDI note. The root MIDI note is derived from the epoch root (0–11) mapped to the appropriate octave for the drone register (typically octave 2–3, MIDI 36–48).

### 1.4 Register

The drone occupies the low-mid register:
- Pad voice: MIDI 48–60 (octaves 3–4)
- Sub voice: MIDI 24–36 (octave 1–2)

This leaves the upper register (MIDI 60–84) clear for the melodic layer and the mid register (MIDI 36–60) for textural material.

### 1.5 Modulation

The drone responds to form cycles:
- Energy modulation → filter cutoff (brighter during form peaks, darker during troughs)
- Density modulation → voice count or detune amount (slightly more complex during peaks)
- Transition zones → voices may begin gliding toward target pitches before the period change

The drone does not respond to phase gating. It sustains continuously.

---

## 2. Melodic Layer

### 2.1 Role

The melodic layer is the primary voice of the composition. It carries motifs — the pitch and rhythmic material that gives the music its identity. It's what a listener hums.

### 2.2 Voices

The melodic layer uses a single monophonic voice:

- Synth: `pretty_bell` — a bright, percussive tone with fast attack and medium release
- Alternative (higher energy periods): `pluck` — sharper attack, shorter decay
- Monophonic: one note at a time. Notes can overlap (legato) but the synth doesn't play chords.

### 2.3 Scheduling

Melodic notes are scheduled at Euclidean rhythm onsets. The scheduling flow:

```
Euclidean pattern (k onsets in n steps)
  → at each onset: MotifEngine selects next motif degree
  → degree is converted to MIDI pitch (root + scale[degree] + octave)
  → note is scheduled with motif rhythm duration
```

The motif degrees cycle through the current motif's `scale_degrees` array. When the motif completes, the MotifEngine applies the next transformation (retrograde, inversion, etc.) and the motif plays again in its transformed form.

### 2.4 Register

The melodic voice occupies the upper-mid to high register:
- Base register: MIDI 60–72 (octaves 4–5)
- Range: may extend ±1 octave based on form energy
- Higher form energy → tendency toward upper register
- Lower form energy → tendency toward lower register, closer to the drone

The register is not fixed — it drifts with the form cycle, creating a sense of the melody rising and falling.

### 2.5 Phrase Structure

Motifs naturally create phrases. A phrase is one complete cycle through a motif's scale_degrees. Between phrases:
- A short rest occurs (one Euclidean step with no onset, or a phase rest)
- The MotifEngine may apply a transformation
- The next phrase begins with the transformed motif

This creates the sense of "call and response" — a phrase, a breath, a variation, a breath.

### 2.6 Period-Specific Behavior

| Period | Synth | Register Tendency | Phrase Length | Note Density |
|--------|-------|------------------|---------------|-------------|
| Deep Night | `pretty_bell` (soft) | Low (48–60) | Short (3–5 notes) | Very sparse |
| Dawn | `pretty_bell` | Rising (55–72) | Growing (4–7 notes) | Increasing |
| Morning | `pluck` | High (60–79) | Full (5–8 notes) | Active |
| Afternoon | `pretty_bell` | Mid-high (55–76) | Medium (5–7 notes) | Moderate |
| Twilight | `pretty_bell` (warm) | Falling (48–69) | Shortening (4–6 notes) | Decreasing |
| Night | `pretty_bell` (dark) | Low (43–65) | Brief (3–5 notes) | Sparse |

---

## 3. Textural Layer

### 3.1 Role

The textural layer provides atmospheric detail — fragments, echoes, harmonic dust. It's not meant to be followed as a line. It fills space, creates depth, and adds color without competing with the melody.

### 3.2 Voices

The textural layer uses a single voice with two available timbres:

- `blade` — a bright, metallic texture with fast attack and long decay. Good for sparse, percussive accents.
- `dsaw` — a detuned sawtooth with slow attack and medium release. Good for sustained, atmospheric swells.

Timbre selection is based on period character:
- Sparse periods (deep night, night): `dsaw` — atmospheric
- Dense periods (morning, afternoon): `blade` — punctual
- Transitional periods (dawn, twilight): alternates or blends

### 3.3 Scheduling

Like the melodic layer, textural events are scheduled at Euclidean rhythm onsets. But the textural Euclidean pattern is much sparser:

- Fewer onsets (k=1–3 vs k=3–7)
- Longer step durations (800–2000ms vs 400–1000ms)
- Longer note durations (sustained fragments vs melodic notes)

At each textural onset, the system plays a fragment — a small group of notes (1–3 pitches) from the current scale. Fragments are not motifs — they're simpler material:

```
fragment:
  pitches: scale degrees [0, 4] or [2, 7, 9] or [0]
  duration: 2–5 seconds (long, sustained)
  dynamics: soft (0.3–0.5 of melodic velocity)
```

Fragment pitch selection uses the epoch's scale but doesn't follow motif logic. It's quasi-random within the scale, biased toward intervals that complement the current drone chord.

### 3.4 Register

The textural layer occupies the mid register, overlapping with both the drone and melodic layers:
- Range: MIDI 36–72 (octaves 2–5)
- Typically centers around MIDI 48–60
- May extend higher during dense periods
- Stays lower during sparse periods

The overlap is intentional — texture should feel like it's emerging from the drone and occasionally reaching up toward the melody.

### 3.5 Phase Dependency

The textural layer is the most phase-dependent. It may be inactive for long stretches (8–22s phase periods with 30–50% active ratio). When it's inactive, the space is audible — the drone and melody exist alone, and the listener notices the absence of texture.

This creates a layered perception:
1. Drone alone (first 6s, or during textural rests)
2. Drone + melody (after 6s, during textural rests)
3. Full texture (when all three are active)

---

## 4. Synthdef Inventory

### 4.1 Required Synthdefs

These are the SuperSonic synthdefs the system needs:

| Name | Type | Attack | Release | Role |
|------|------|--------|---------|------|
| `prophet` | Pad (saw) | Slow (2–4s) | Long (4–8s) | Drone pad voice |
| `dark_ambience` | Noise+sine | Very slow (5–10s) | Very long (8–15s) | Drone sub voice |
| `pretty_bell` | Bell/pluck | Fast (5–20ms) | Medium (0.5–2s) | Melodic voice (general) |
| `pluck` | Pluck | Very fast (1–5ms) | Short (0.2–0.8s) | Melodic voice (high energy) |
| `blade` | Metallic | Fast (10–50ms) | Long (1–4s) | Textural (sparse accents) |
| `dsaw` | Detuned saw | Medium (0.5–2s) | Medium (1–3s) | Textural (atmosphere) |

### 4.2 Parameter Mapping

Each synthdef receives parameters from the composition state:

**Common parameters (all synths):**
- `freq` — MIDI-to-frequency converted pitch
- `amp` — gain, scaled by layer energy and form energy
- `pan` — stereo position (subtle, ±0.3)

**Drone-specific:**
- `cutoff` — low-pass filter frequency, mapped from form energy
- `detune` — voice detune in cents (prophet only)
- `attack` / `release` — scaled by period character (longer for sparse periods)

**Melodic-specific:**
- `velocity` — note accent, scaled by form density and Euclidean position
- `legato` — note overlap amount

**Textural-specific:**
- `density` — controls filter openness or reverb amount
- `spread` — stereo width for multi-pitch fragments

### 4.3 Synthdef Loading

Synthdefs are loaded at audio initialization (user gesture). All six are loaded upfront. The browser doesn't need to load new synthdefs during playback — it just sends different parameters to the loaded synths.

Period changes don't require new synthdefs. They require new parameters. This keeps the audio startup fast and the runtime stable.

---

## 5. Staggered Entry Sequence

### 5.1 Timeline

When the user presses "Start Audio Runtime":

```
t=0s    AudioContext starts
t=0s    Drone pad voice fades in (attack: 2–4s)
t=6s    Melodic layer becomes eligible for scheduling
        First motif phrase begins at next Euclidean onset
t=12s   Textural layer becomes eligible for scheduling
        First fragment appears at next textural Euclidean onset
t=18s   Drone sub voice fades in (dark_ambience, attack: 5–10s)
t=25s   Drone pad reaches full sustain
```

### 5.2 Rationale

The staggered entry prevents the initial moment from being overwhelming. The listener first hears just the harmonic foundation. Then the melody enters — a single voice, sparse. Then texture fills the space. Finally the sub voice adds depth.

This mirrors how acoustic ensembles begin: the bass instruments sustain, the melody enters, the percussion colors, the room resonates.

### 5.3 Implementation

The stagger is controlled by the server-side composition state. The epoch payload includes a `layer_ready` timestamp for each layer:

```json
{
  "audio_start_time": "2026-04-28T16:45:00Z",
  "layers": {
    "drone": {"ready_at_offset_s": 0, "sub_ready_at_offset_s": 18},
    "melodic": {"ready_at_offset_s": 6},
    "textural": {"ready_at_offset_s": 12}
  }
}
```

The browser tracks the audio start time and only schedules notes for layers that have passed their ready offset.

---

## 6. Register Map

Visual representation of how the three layers occupy frequency space:

```
MIDI    Note    Register
84      C6      ────────────────────────── melodic peak
80      G5      ───────────── melodic
76      E5      ───────────── melodic
72      C5      ─────── melodic ── textural peak
68      G4      ─────── melodic ── textural
64      E4      ── textural ── melodic
60      C4      ── textural ── drone pad ── melodic base
56      G3      ── textural ── drone pad
52      E3      ── drone pad ── textural base
48      C3      ── drone pad ── drone sub
44      G2      ── drone sub
40      E2      ── drone sub
36      C2      ── drone sub base
```

The overlap zones are where the music gets interesting — the drone and texture blend, the melody dips into the drone's space, texture reaches up toward the melody.

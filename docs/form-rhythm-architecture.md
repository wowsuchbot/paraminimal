# Form & Rhythm Architecture

The meso-structure of Paraminimal — how music breathes within a period.

## Overview

The composition time hierarchy has four levels. Each level operates at a different timescale and controls a different aspect of the musical material.

```
Period (hours)           — what tonal world we're in
  └─ Epoch (15 min)      — which specific scale, root, energy, density
      └─ Form cycle (~20s) — breathing rhythm of density and energy
          └─ Phase (3–22s)  — gating and shaping within a layer
```

Periods and epochs are documented in `composition-framework.md` and `current-state.md`. This document covers form cycles, phase periods, and the Euclidean rhythm system.

---

## 1. Form Cycles

### 1.1 Purpose

Form cycles are the meso-level pulse of the music. They prevent the texture from being static within an epoch. Energy and density don't stay at their epoch value — they oscillate around it in a slow, organic wave.

A listener doesn't consciously hear "a 20-second cycle." They feel the music breathing — swelling and contracting, dense then sparse, active then still.

### 1.2 Parameters

Each form cycle is characterized by:

- **Duration** — approximately 20 seconds. Not metronomic. The actual period drifts slightly based on the epoch's character to avoid mechanical repetition.
- **Density envelope** — controls how much sonic material is present. Ranges from 0.0 to 1.0, centered on the epoch's density value.
- **Energy envelope** — controls how active the material is. Ranges from 0.0 to 1.0, centered on the epoch's energy value.
- **Phase offset** — the form cycle doesn't start at zero when an epoch begins. It inherits a phase from the epoch seed so there's no audible "reset" at epoch boundaries.

### 1.3 Envelope Shape

The density and energy envelopes use a sinusoidal modulation clamped by smoothstep.

```
raw = sin(progress * 2π) * amplitude
clamped = smoothstep(low, high, epoch_value + raw * range)
```

Where:
- `progress` is 0.0–1.0 through the form cycle
- `amplitude` is 0.3–0.5 (how far the oscillation swings)
- `range` scales the oscillation relative to the epoch value
- `smoothstep` prevents values from clipping at 0 or 1 and softens the peaks

This produces a wave that rises and falls around the epoch's baseline. During high-energy epochs, the wave peaks are higher. During low-energy epochs, the whole wave sits lower but still oscillates.

### 1.4 Period-Specific Behavior

Form cycle behavior is modulated by the current period:

| Period | Form Amplitude | Form Character |
|--------|---------------|----------------|
| Deep Night | Very low (0.15) | Nearly flat. Subtle drifts. Near-stasis is the point. |
| Dawn | Rising (0.25→0.4) | Oscillation grows as energy rises. Breathing begins. |
| Morning | Full (0.4) | Clear swelling and contracting. Active, audible cycles. |
| Afternoon | Moderate (0.35) | Flowing, less pronounced than morning. Melodic focus means density stays higher. |
| Twilight | Falling (0.4→0.2) | Oscillation diminishes. Cycles become more subtle as energy drops. |
| Night | Low-tense (0.2) | Small amplitude but the center of oscillation is tense. The breathing is shallow but anxious. |

### 1.5 Computation

Form state is computed by the epoch layer. It is not a separate process — it's a function of epoch state + elapsed time.

```
form_state(epoch, now):
  cycle_duration = base_duration(epoch.period) + drift(epoch.seed, now)
  cycle_progress = (now - epoch.start) mod cycle_duration
  density = envelope(epoch.density, cycle_progress, epoch.period, :density)
  energy = envelope(epoch.energy, cycle_progress, epoch.period, :energy)
  {cycle_progress, density, energy}
```

This is pure and deterministic — given the same epoch and timestamp, it always returns the same form state. No server-side mutable state needed.

---

## 2. Phase Periods

### 2.1 Purpose

Phase periods are the micro-level gating within each sound layer. They control when a layer is active and when it rests. This creates the rhythmic character of the music — the space between sounds.

### 2.2 Per-Layer Configuration

Each sound layer (drone, melodic, textural) has its own phase configuration:

**Drone layer:**
- Phase period: continuous (no gating)
- The drone doesn't pulse. It sustains and evolves slowly.
- Energy and density modulation come from the form cycle, not phase gating.

**Melodic layer:**
- Phase period: 3–8 seconds
- Active ratio: 60–80% (the melody plays most of the time, with short rests)
- The phase creates breathing room between motifs
- Phase length scales with epoch energy: higher energy = shorter rests (more continuous melody)

**Textural layer:**
- Phase period: 8–22 seconds
- Active ratio: 30–50% (texture is sparse — present then absent)
- The longer phase period means texture appears in waves
- Phase length inversely scales with epoch density: higher density = shorter rests (more frequent texture)

### 2.3 Phase Gating

Phase gating uses a simple LFO (low-frequency oscillator) model:

```
active?(layer, now, epoch):
  phase_duration = layer_config.phase_range(epoch)
  active_ratio = layer_config.active_ratio(epoch)
  phase_progress = (now mod phase_duration) / phase_duration
  phase_progress < active_ratio
```

When a layer is in its inactive phase:
- Melodic layer: rests — no notes scheduled, previous notes ring out
- Textural layer: fades — existing texture decays, no new material

The drone layer ignores phase gating entirely.

### 2.4 Phase Interaction with Form Cycles

Phase periods and form cycles interact. During the peak of a form cycle (high density/energy):
- Melodic phase rests are shorter
- Textural active ratio increases

During the trough:
- Melodic rests are longer
- Textural active ratio decreases

This is achieved by modulating the phase parameters with the form cycle's density and energy values:

```
effective_rest = base_rest * (1.0 - form_density * 0.5)
effective_active_ratio = base_active_ratio + (form_density - 0.5) * 0.2
```

---

## 3. Euclidean Rhythm System

### 3.1 Purpose

Euclidean rhythms (Bjorklund algorithm) provide the rhythmic skeleton for the melodic and textural layers. They distribute a number of onsets (k) as evenly as possible across a number of steps (n).

The musical value of Euclidean rhythms:
- They produce patterns that feel organic and groove-oriented
- Small parameter changes create large rhythmic variation
- They connect to global rhythmic traditions (clave, tala, sub-Saharan polyrhythm)
- They're deterministic — same k and n always produce the same pattern

### 3.2 Algorithm

The Bjorklund algorithm distributes k onsets across n steps:

```
bjorklund(k, n):
  if k == 0: return [0] * n
  if k == n: return [1] * n
  // Standard Bjorklund: iteratively group and distribute
  // Returns list of n values, each 0 or 1
```

Implementation detail: the algorithm should be pure Elixir, no side effects. It should accept k and n and return a list of 0s and 1s.

### 3.3 Layer-Specific Ranges

**Melodic layer:**
- k (onsets): 3–7
- n (steps): 8–15
- Step duration: 400–1000ms (scaled by epoch energy)
- Higher energy → more onsets, shorter steps, faster tempo
- Lower energy → fewer onsets, longer steps, slower tempo

**Textural layer:**
- k (onsets): 1–3
- n (steps): 10–23
- Step duration: 800–2000ms (scaled by epoch density)
- Higher density → more onsets relative to steps
- Lower density → fewer onsets, more space

### 3.4 Parameter Selection

Euclidean parameters are selected deterministically from epoch state:

```
melodic_euclidean(epoch):
  energy = form_state.energy
  k = floor(3 + energy * 4)           # 3–7
  n = floor(8 + energy * 7)           # 8–15
  step_ms = floor(1000 - energy * 600) # 400–1000ms
  {k, n, step_ms}

textural_euclidean(epoch):
  density = form_state.density
  k = floor(1 + density * 2)          # 1–3
  n = floor(10 + density * 13)        # 10–23
  step_ms = floor(2000 - density * 1200) # 800–2000ms
  {k, n, step_ms}
```

### 3.5 Euclidean vs. Motifs

Euclidean rhythms and motifs serve different roles:

- **Euclidean rhythms** determine *when* material sounds — the rhythmic grid
- **Motifs** determine *what* sounds — the pitch and rhythmic contour of each event

They coexist: the Euclidean pattern triggers motif events at its onset positions. At each onset, the MotifEngine selects a motif (or fragment) and schedules it through SuperSonic.

Think of it as:
- Euclidean = the pulse, the grid, "is there a note here?"
- Motif = the content, "what note goes here?"

During a form cycle trough, the Euclidean pattern may have fewer onsets (lower k), creating more space. During a peak, more onsets fill the grid. The motifs themselves also change — simpler during troughs, more elaborate during peaks.

### 3.6 Additive Permutation (Rhythmic Rotation)

A technique borrowed from Messiaen: rotate the Euclidean pattern by shifting it one step forward each cycle. This creates rhythmic development without changing the underlying pattern.

```
rotate(pattern, steps):
  # Shift pattern left by `steps` positions, wrap around
```

Rotation amount is determined by the epoch seed. Each epoch uses a fixed rotation offset so the pattern is stable within an epoch but changes between epochs. This is a subtle form of development — the groove shifts without the listener consciously tracking it.

### 3.7 Period-Specific Rhythmic Character

| Period | Melodic k | Melodic n | Textural k | Textural n | Character |
|--------|-----------|-----------|------------|------------|-----------|
| Deep Night | 2–3 | 8–11 | 1–2 | 12–18 | Sparse pulses, long rests |
| Dawn | 3–4 | 8–12 | 1–2 | 10–16 | Unfolding, lightly syncopated |
| Morning | 5–7 | 10–15 | 2–3 | 12–20 | Steady, active, clear pulse |
| Afternoon | 4–6 | 10–14 | 2–3 | 11–18 | Flowing, medium-density groove |
| Twilight | 3–5 | 9–13 | 1–2 | 12–17 | Loosening, phrase-led motion |
| Night | 2–4 | 8–12 | 1–2 | 10–15 | Slow, tense, spacious |

---

## 4. Integration Flow

How form cycles, phase periods, and Euclidean rhythms connect:

```
Epoch state (scale, root, energy, density, period)
  │
  ├─ Form cycle (modulates energy/density over ~20s)
  │     └─ form_energy, form_density (0.0–1.0, oscillating)
  │
  ├─ Phase periods (per-layer gating)
  │     ├─ Drone: always active
  │     ├─ Melodic: 3–8s cycles, gated by form_density
  │     └─ Textural: 8–22s cycles, gated by form_density
  │
  ├─ Euclidean patterns (per-layer rhythmic grids)
  │     ├─ Melodic: k=3-7, n=8-15, step=400-1000ms
  │     └─ Textural: k=1-3, n=10-23, step=800-2000ms
  │
  └─ Motif engine (pitch content per onset)
        └─ Selected motif → transformed → scheduled note
```

The server computes all of this and sends a compact payload to the browser. The browser receives the current state and schedules audio accordingly. The meso-structure (form cycles, phases, Euclidean) is computed server-side — the browser only receives the result.

### Audio Scheduling Payload

The composition payload pushed to the browser includes:

```json
{
  "epoch_id": "2026-04-28T16:45Z",
  "period": "afternoon",
  "scale": "dorian",
  "root": 5,
  "root_name": "F",
  "energy": 0.62,
  "density": 0.55,
  "form": {
    "cycle_progress": 0.73,
    "form_energy": 0.71,
    "form_density": 0.58
  },
  "layers": {
    "drone": {
      "active": true,
      "pitches": [53, 57, 60, 65],
      "energy": 0.65
    },
    "melodic": {
      "active": true,
      "phase_active": true,
      "euclidean": {"k": 5, "n": 12, "step_ms": 650, "rotation": 2},
      "next_motif": {"degrees": [0, 2, 4, 7, 4, 2], "rhythm": [1, 0.5, 0.5, 1, 0.5, 2]},
      "register": [60, 72]
    },
    "textural": {
      "active": true,
      "phase_active": false,
      "euclidean": {"k": 2, "n": 14, "step_ms": 1200, "rotation": 0},
      "fragment": {"degrees": [0, 7], "rhythm": [1, 3]},
      "register": [48, 60]
    }
  },
  "transition": {
    "zone": "core",
    "progress": 0.0
  }
}
```

The browser's SuperSonic hook receives this and schedules accordingly:
- Drone: sustain chord at given pitches
- Melodic: if phase active, step through Euclidean pattern and trigger motif notes at onsets
- Textural: if phase active, step through Euclidean pattern and trigger fragment notes at onsets

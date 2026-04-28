# Motif Lineage & Strange Loops

How Paraminimal creates long-form musical coherence through cross-period motif referencing.

## Overview

A strange loop, in the Hofstadterian sense, is a system that, when you follow it downward through levels of abstraction, brings you back to where you started — but at a different level. In Paraminimal, this means a motif composed for dawn reappears at midnight, transformed through a chain of operations, so the listener who pays attention across hours recognizes the echo.

This document covers the data structure for tracking motif lineage, the rules for cross-period referencing, and how the strange loop manifests in the musical output.

---

## 1. Motif Data Structure

### 1.1 Base Motif

```elixir
defmodule Paraminimal.Composition.Motif do
  @moduledoc "A musical motif defined in scale degrees and relative rhythm."

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          scale_degrees: [integer()],
          rhythm: [float()],
          period_affinity: atom(),
          energy_range: {float(), float()},
          transformation_tendency: [atom()],
          octave_offset: integer(),
          tags: [atom()]
        }

  defstruct [
    :id,
    :name,
    :scale_degrees,
    :rhythm,
    :period_affinity,
    :energy_range,
    :transformation_tendency,
    :octave_offset,
    :tags
  ]
end
```

### 1.2 Lineage Entry

Every time a motif is used in performance, a lineage entry is recorded:

```elixir
defmodule Paraminimal.Composition.MotifLineage do
  @moduledoc "Tracks the chain of transformations applied to a motif."

  @type transformation :: %{
          type: atom(),
          params: map()
        }

  @type t :: %__MODULE__{
          source_motif_id: String.t(),
          current_degrees: [integer()],
          current_rhythm: [float()],
          transformations: [transformation()],
          generation: non_neg_integer(),
          period: atom(),
          epoch_id: String.t(),
          timestamp: DateTime.t()
        }

  defstruct [
    :source_motif_id,
    :current_degrees,
    :current_rhythm,
    :transformations,
    :generation,
    :period,
    :epoch_id,
    :timestamp
  ]
end
```

- `source_motif_id` — the original base motif this lineage traces back to
- `current_degrees` / `current_rhythm` — the motif as it currently sounds (after all transformations)
- `transformations` — ordered list of every transformation applied, from oldest to newest
- `generation` — how many transformations have been applied (0 = original, 1 = one transformation, etc.)
- `period` / `epoch_id` / `timestamp` — where and when this lineage entry was created

---

## 2. Transformation Operations

### 2.1 Canon Operations

These are the standard contrapuntal transformations, applied to the motif's scale degrees and rhythm:

**Retrograde** — reverse the pitch sequence.

```
input:  [0, 2, 4, 7, 4, 2]
output: [2, 4, 7, 4, 2, 0]
```

Rhythm is also reversed:

```
input:  [1, 0.5, 0.5, 1, 0.5, 2]
output: [2, 0.5, 1, 0.5, 0.5, 1]
```

**Inversion** — mirror the intervals around the first degree.

```
input:  [0, 2, 4, 7, 4, 2]
intervals: [0, +2, +2, +3, -3, -2]
output: [0, -2, -4, -7, -4, -2]
normalized: [0, 10, 8, 5, 8, 10]  (mod 12, wrapped to positive)
```

Rhythm is unchanged.

**Augmentation** — stretch all durations by a factor (typically 2x).

```
input rhythm:  [1, 0.5, 0.5, 1, 0.5, 2]
output rhythm: [2, 1, 1, 2, 1, 4]
```

Pitches are unchanged.

**Diminution** — compress all durations by a factor (typically 0.5x).

```
input rhythm:  [1, 0.5, 0.5, 1, 0.5, 2]
output rhythm: [0.5, 0.25, 0.25, 0.5, 0.25, 1]
```

Pitches are unchanged.

**Transposition** — shift all scale degrees by a fixed amount.

```
input:  [0, 2, 4, 7, 4, 2]
shift:  +3
output: [3, 5, 7, 10, 7, 5]
```

Rhythm is unchanged.

**Rhythmic rotation** — rotate the rhythm pattern by n positions.

```
input:   [1, 0.5, 0.5, 1, 0.5, 2]
rotate:  2
output:  [0.5, 1, 0.5, 2, 1, 0.5]
```

Pitches are unchanged.

### 2.2 Compound Transformations

Transformations can be composed. A motif that has been retrograded and then augmented is:

```
generation 0: [0, 2, 4, 7, 4, 2] / [1, 0.5, 0.5, 1, 0.5, 2]
generation 1 (retrograde): [2, 4, 7, 4, 2, 0] / [2, 0.5, 1, 0.5, 0.5, 1]
generation 2 (augmentation): [2, 4, 7, 4, 2, 0] / [4, 1, 2, 1, 1, 2]
```

The lineage records each step:

```elixir
%MotifLineage{
  source_motif_id: "dawn_rising_3",
  current_degrees: [2, 4, 7, 4, 2, 0],
  current_rhythm: [4, 1, 2, 1, 1, 2],
  transformations: [
    %{type: :retrograde, params: %{}},
    %{type: :augmentation, params: %{factor: 2.0}}
  ],
  generation: 2
}
```

### 2.3 Period Transformation Tendencies

Each period prefers certain transformations. This isn't a hard constraint — it's a weighting that affects selection probability:

| Period | Preferred Transformations | Avoids |
|--------|--------------------------|--------|
| Deep Night | Inversion, Retrograde, Diminution | Augmentation (would make sparse material even sparser) |
| Dawn | Augmentation, Transposition (upward) | Diminution (material is already sparse) |
| Morning | Transposition, Rhythmic rotation | Inversion (would darken a bright period) |
| Afternoon | Augmentation, Transposition, Rhythmic rotation | Retrograde (breaks melodic flow) |
| Twilight | Retrograde, Inversion, Diminution | Augmentation (would overextend a fading period) |
| Night | Inversion, Retrograde | Augmentation, Transposition (upward) |

---

## 3. Cross-Period Referencing

### 3.1 The Strange Loop Mechanism

The strange loop is not always active. It operates on a longer timescale than individual epochs or periods. The mechanism:

1. **Motif pools are period-specific** — each period has its own set of 3–5 base motifs. During normal operation, only the current period's motifs are used.

2. **Cross-period references happen during transitions** — when the system transitions from one period to another, the MotifEngine may select a motif from a *different* period, transformed to fit the new context.

3. **The reference is tracked in lineage** — the lineage entry records both the source motif (from the other period) and the transformation that adapted it.

4. **Recognition happens across hours** — a listener who heard the dawn motif at 6am may hear its echo at midnight, inverted and diminished. The structure is the same; the expression is different.

### 3.2 Cross-Period Reference Rules

References don't happen randomly. They follow rules:

**Temporal distance** — the system prefers to reference motifs from periods that are temporally distant:
- Dawn references Night and Deep Night motifs
- Morning references Twilight and Night motifs
- Afternoon references Dawn and Morning motifs
- Twilight references Morning and Afternoon motifs
- Night references Dawn and Afternoon motifs
- Deep Night references Twilight and Dawn motifs

This creates a circular pattern: dawn→night→dawn, morning→twilight→morning. The loop closes.

**Complementarity** — the referenced motif should have contrasting character to the current period:
- A bright period references a dark motif (transformed to fit)
- A sparse period references a dense motif (thinned to fit)
- A tense period references a stable motif (destabilized to fit)

The transformation is what bridges the gap — an inversion or retrograde can dramatically change the character of a motif without losing its structural identity.

**Transformation chain length** — cross-period references are always at least generation 1 (one transformation applied). The further the temporal distance, the more transformations are applied:
- Adjacent periods (±1): 1 transformation
- Skip-one periods (±2): 1–2 transformations
- Opposite periods (±3): 2–3 transformations

### 3.3 Selection Probability

Cross-period references are not the default. Most of the time, the current period's own motifs play. The probability of a cross-period reference:

```
base_probability = 0.0  # default: use current period's motifs

# During transitions, probability increases
if in_transition_zone:
  base_probability += 0.3  # 30% chance of cross-period reference during transition

# Some transitions are more likely to trigger references
if transition_strategy == :canon_handoff:
  base_probability += 0.4  # canon handoff explicitly uses cross-period material

# Scale distance affects probability
if scale_distance > 0.6:
  base_probability += 0.1  # distant scales benefit from familiar material

final_probability = min(base_probability, 0.7)  # cap at 70%
```

This means:
- Normal playback: always current period motifs (0% cross-period)
- During transition: 30–40% chance of cross-period reference
- During canon handoff: 70% chance (the strategy explicitly demands it)

### 3.4 Example

Dawn (5–8am) is transitioning to Morning (8–12am). The transition strategy selected is `canon_handoff`.

1. The MotifEngine looks at Dawn's motif pool: `["dawn_rising_1", "dawn_rising_2", "dawn_luminous_1"]`
2. It looks at Morning's motif pool: `["morning_active_1", "morning_active_2", "morning_bright_1"]`
3. For canon_handoff, it selects a motif from the *opposite* side — a Night motif, because Night is the temporal opposite of Dawn.
4. Night's motif pool: `["night_mysterious_1", "night_dark_1", "night_tense_1"]`
5. It selects `"night_mysterious_1"` (scale degrees: `[0, 1, 5, 7, 10]`)
6. It applies two transformations: retrograde + transposition (+4)
7. Result: `[6, 5, 1, -1, 0]` → normalized → `[6, 5, 1, 11, 0]`
8. This transformed motif now plays in Morning's Dorian context, but its DNA is from Night

The lineage entry records:

```elixir
%MotifLineage{
  source_motif_id: "night_mysterious_1",
  source_period: :night,
  current_degrees: [6, 5, 1, 11, 0],
  current_rhythm: [2, 0.5, 1, 1, 2],
  transformations: [
    %{type: :retrograde, params: %{}},
    %{type: :transposition, params: %{shift: 4}}
  ],
  generation: 2,
  target_period: :morning,
  target_scale: "dorian",
  epoch_id: "2026-04-28T08:00Z"
}
```

---

## 4. Motif Engine Flow

### 4.1 Selection Process

For each melodic phrase (every time the motif completes a full cycle):

```
1. Check: are we in a transition zone?
   ├─ Yes: calculate cross-period reference probability
   │   ├─ Cross-period reference selected:
   │   │   ├─ Select source period (temporal distance rules)
   │   │   ├─ Select motif from source pool (PRNG)
   │   │   ├─ Apply transformations (period tendency + distance)
   │   │   └─ Record lineage entry
   │   └─ Current period motif selected:
   │       ├─ Select motif from current pool (PRNG or round-robin)
   │       └─ Possibly apply transformation (PRNG, weighted by tendency)
   └─ No: select from current period pool
       ├─ Select motif (round-robin or PRNG)
       └─ Possibly apply transformation (PRNG, weighted by tendency)
```

### 4.2 Round-Robin vs. PRNG

Motif selection within a period uses a hybrid approach:

- **Round-robin** is the default — cycle through the period's motifs in order. This ensures all motifs are heard.
- **PRNG override** happens when the MotifEngine decides to skip ahead or repeat. This is triggered by:
  - Form cycle energy peak → may select a more active motif
  - Form cycle energy trough → may select a simpler motif
  - Cross-period reference → PRNG selects from the source pool

### 4.3 Transformation Application

After motif selection, the engine decides whether to apply a transformation:

```
transformation_probability = 0.0

# Base probability: some transformations happen naturally
transformation_probability += 0.15  # 15% base chance per phrase

# Period tendency increases probability for preferred transformations
if period prefers [inversion, retrograde]:
  transformation_probability += 0.1

# Form energy affects transformation likelihood
if form_energy > 0.7:
  transformation_probability += 0.1  # high energy → more variation

# Cap at 50% — most phrases play untransformed
transformation_probability = min(transformation_probability, 0.5)
```

When a transformation is applied, the type is selected from the period's preferred transformations, weighted by PRNG.

---

## 5. Lineage in the Audio Payload

### 5.1 What the Browser Receives

The browser doesn't need the full lineage history. It receives the current motif state:

```json
{
  "melodic": {
    "motif": {
      "degrees": [6, 5, 1, 11, 0],
      "rhythm": [2, 0.5, 1, 1, 2],
      "source_id": "night_mysterious_1",
      "generation": 2,
      "is_cross_period": true
    }
  }
}
```

The browser uses this to schedule notes. It doesn't need to know the transformation history — that's for the server to track and for the UI to display.

### 5.2 UI Display

The viz rack doesn't currently have a dedicated lineage display. Future phases may add:
- A small indicator showing when a cross-period reference is active
- A "lineage badge" showing the source period of the current motif
- An optional expanded view showing the full transformation chain

This is Phase 6+ work — not needed for initial audio.

---

## 6. Lineage Persistence

### 6.1 Storage

Motif lineage entries are stored in Postgres as part of the epoch record:

```elixir
# Schema: epochs
field :motif_lineage, {:array, :map}  # array of lineage entries for this epoch
```

Each epoch records which motifs were played and what transformations were applied. This enables:
- Historical analysis of motif usage patterns
- Reconstruction of the musical narrative for a given time range
- "Moment NFTs" that capture not just the scale/energy state but the motif lineage

### 6.2 Querying

```elixir
# All epochs that used a specific source motif
Epoch |> where(fragment("motif_lineage @> '[{"source_motif_id": "dawn_rising_1"}]'"))

# All cross-period references in the last 24 hours
Epoch
|> where(inserted_at: > ~N[-1, 0, 0, 0, 0, 0])
|> where(fragment("motif_lineage @> '[{"is_cross_period": true}]'"))
```

### 6.3 Strange Loop Detection

A strange loop is detected when a motif's lineage traces back through multiple periods and returns to its source period in a transformed state:

```
dawn_rising_1 (generation 0, period: dawn)
  → retrograde (generation 1, period: morning)
    → inversion (generation 2, period: twilight)
      → transposition (generation 3, period: night)
        → retrograde (generation 4, period: deep_night)
          → augmentation (generation 5, period: dawn) ← loop closes
```

The system can detect these loops and flag them for UI display or logging. The detection is straightforward: check if `source_period == current_period` and `generation >= 4`.

---

## 7. Design Principles

### 7.1 Subtlety Over Obviousness

The strange loop should be a discovery, not a gimmick. A casual listener doesn't need to know it's happening. A listener who pays attention across hours might notice echoes and connections. A listener who studies the system can trace the full lineage.

This means:
- Cross-period references don't happen every transition (30–40% probability)
- Transformations are substantial enough to disguise the source
- No UI element says "you're hearing a motif from dawn!" (at least initially)

### 7.2 Musical Coherence Over Formal Correctness

The system should never produce music that sounds bad just to fulfill a strange loop. If a cross-period reference would produce unmusical results (wrong register, jarring intervals, incompatible rhythm), the engine should fall back to a current-period motif.

Lineage tracking is a feature of the system, not a constraint on it. The music comes first.

### 7.3 Emergence Over Prescription

The ideal strange loop is one that emerges naturally from the rules, not one that's explicitly composed. The system defines the rules (period affinities, transformation tendencies, cross-period probabilities) and lets the loops emerge from those rules over the course of a day.

This means the specific loops that form on any given day are partially determined by the PRNG seed, which is determined by the date. Different days produce different loops. Some days may have no detectable loops at all. Some days may have several.

# Deterministic Seeding

How Paraminimal produces controlled randomness that is consistent, reproducible, and musical.

## Overview

Paraminimal is deterministic. Two servers started at the same UTC time produce the same music. This is a core design principle — it enables synchronization, replay, and the "shared experience" that makes the system meaningful.

But music needs variation. Within an epoch, motifs transform, rhythms rotate, fragments shift. This variation must be seeded — derived from a stable source so it's consistent across listeners but still feels alive.

---

## 1. Seeding Architecture

### 1.1 Hierarchy of Seeds

Seeds flow downward through the composition hierarchy:

```
UTC time
  └─ epoch_id (date + hour + 15-min bucket)
      ├─ root selection (stable_hash of date + hour + period)
      ├─ scale selection (stable_hash of epoch_id + period + :scale)
      ├─ form cycle phase offset (stable_hash of epoch_id + :form)
      └─ intra-epoch PRNG seed (stable_hash of epoch_id + :prng)
          ├─ motif transformation selection
          ├─ Euclidean rotation offset
          ├─ textural fragment pitch selection
          ├─ register drift
          └─ rhythmic micro-variations
```

Each level is deterministic given the level above it. No external randomness is introduced at any point.

### 1.2 Two Seeding Mechanisms

**Stable hash** — used for discrete, categorical decisions:
- Root pitch class (0–11)
- Scale selection (index into candidate list)
- Chord shape (fixed per period, no hash needed)
- Form phase offset
- Intra-epoch PRNG seed

The stable hash uses SHA256 of the term, converted to an unsigned integer, then modded to the required range:

```elixir
def stable_hash(term, modulo) do
  term
  |> :erlang.term_to_binary()
  |> then(&:crypto.hash(:sha256, &1))
  |> :binary.decode_unsigned()
  |> Integer.mod(modulo)
end
```

This is already implemented in `Paraminimal.Composition.Epoch`.

**PRNG** — used for continuous, sequential decisions within an epoch:
- Which motif transformation to apply next
- Which register offset to use
- Which fragment pitches to select
- Micro-timing variations

The PRNG is Mulberry32, a lightweight 32-bit state generator with good statistical properties for creative applications. It's fast, deterministic, and produces musically useful distributions.

### 1.3 Why Two Mechanisms?

Stable hash is stateless — you can compute any value independently. You don't need to compute root before scale, or scale before PRNG seed. Each is independently deterministic from UTC time.

PRNG is stateful — you draw values in sequence, and the sequence depends on previous draws. This is important for intra-epoch decisions where the order matters (motif A then transformation B then fragment C).

The combination means:
- Epoch-level decisions (root, scale, form offset) can be computed in any order
- Intra-epoch decisions (motif sequence, fragment selection) follow a deterministic progression

---

## 2. Mulberry32 PRNG

### 2.1 Algorithm

Mulberry32 is a 32-bit state generator:

```elixir
defmodule Paraminimal.Composition.PRNG do
  @moduledoc "Mulberry32 deterministic PRNG for intra-epoch variation."

  defstruct [:state]

  @spec new(integer()) :: %__MODULE__{}
  def new(seed) do
    %__MODULE__{state: seed |> band(0xFFFFFFFF)}
  end

  @spec next(%__MODULE__{}) :: {float(), %__MODULE__{}}
  def next(%__MODULE__{state: state}) do
    new_state =
      state
      |> bxor(bsr(state, 16))
      |> mul(0x45D9F3B)
      |> band(0xFFFFFFFF)
      |> bxor(bsr(state, 16))
      |> mul(0x45D9F3B)
      |> band(0xFFFFFFFF)
      |> bxor(bsr(state, 16))

    value = (bxor(bsr(new_state, 16), new_state) >>> 0) / 0x100000000
    {%__MODULE__{state: new_state}, value}
  end

  @spec next_int(%__MODULE__{}, pos_integer()) :: {integer(), %__MODULE__{}}
  def next_int(prng, max) do
    {value, prng2} = next(prng)
    {floor(value * max), prng2}
  end

  @spec next_range(%__MODULE__{}, number(), number()) :: {float(), %__MODULE__{}}
  def next_range(prng, min, max) do
    {value, prng2} = next(prng)
    {min + value * (max - min), prng2}
  end
end
```

### 2.2 Properties

- Period: 2³² — effectively infinite for epoch-length sequences
- State: single 32-bit integer
- Output: float in [0.0, 1.0)
- Deterministic: same seed → same sequence
- Portable: identical output in Elixir and JavaScript (critical for browser-side scheduling that must match server intent)

### 2.3 JavaScript Port

The browser-side PRNG must produce identical sequences to the server. Here's the JS equivalent:

```javascript
function mulberry32(seed) {
  let state = seed | 0;
  return function() {
    state = (state + 0x6D2B79F5) | 0;
    let t = Math.imul(state ^ (state >>> 15), 1 | state);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
```

The browser receives the PRNG seed as part of the composition payload and initializes its local Mulberry32 with it. This ensures that any browser-side micro-scheduling (timing jitter, subtle parameter variation) stays consistent with the server's intent.

---

## 3. Intra-Epoch Seeding

### 3.1 PRNG Seed Derivation

Each epoch gets a single PRNG seed, derived deterministically:

```elixir
prng_seed = stable_hash({epoch_id, :prng}, 0xFFFFFFFF)
```

This seed is constant for the entire epoch. All intra-epoch variation draws from this single PRNG stream.

### 3.2 Seeded Decisions

The PRNG stream is consumed in a defined order. This order is part of the specification — changing it would change the music.

**Per form cycle:**
1. Form duration drift (±0–2s variation on the base 20s)
2. Form amplitude adjustment (±10% variation on period base amplitude)
3. Density envelope jitter (small perturbation on the smoothstep curve)

**Per melodic phrase (each complete motif cycle):**
4. Next transformation type (if the MotifEngine has multiple candidates)
5. Register offset for this phrase (±0–3 semitones from base register)
6. Rhythmic micro-variation (±5% on Euclidean step duration, per step)

**Per textural fragment:**
7. Fragment pitch degrees (which scale degrees to use for the fragment)
8. Fragment duration variation (±20% on base duration)
9. Fragment velocity (0.3–0.5 range, randomly selected)

**Per transition event:**
10. Strategy selection (when multiple strategies are viable)
11. Transition pacing variation (internal timing of the transition acts)

### 3.3 PRNG Independence Between Epochs

Each epoch gets its own PRNG seed, so the variation within one epoch is completely independent of variation within another epoch. There's no "carry-over" of PRNG state between epochs.

This means:
- Restarting the server mid-epoch produces the same variation
- A listener who joins mid-epoch gets the same variation (the PRNG seed is in the payload)
- Epochs are independently reproducible

### 3.4 PRNG and Determinism Testing

Tests should verify:
- Same epoch_id produces same PRNG seed
- Same PRNG seed produces same sequence of values
- The sequence is consumed in the documented order
- Elixir and JavaScript implementations produce identical values for the same seed

---

## 4. Seeding in the Audio Payload

### 4.1 What the Browser Receives

The browser receives the PRNG seed as part of the composition payload:

```json
{
  "epoch_id": "2026-04-28T16:45Z",
  "prng_seed": 2847293847,
  "form": {
    "phase_offset": 0.37,
    "duration_base_ms": 20000,
    "duration_drift_ms": 1200
  },
  "melodic": {
    "register_offset": 2,
    "euclidean_rotation": 3,
    "step_duration_variation": 0.03
  }
}
```

### 4.2 What the Browser Does With It

The browser initializes a local Mulberry32 with the PRNG seed. It uses this for:
- Micro-timing variation on Euclidean steps (small jitter to avoid mechanical precision)
- Velocity variation on individual notes
- Any client-side scheduling that needs to be deterministic but not server-computed

The server computes the macro decisions (which motif, which transformation, which pitches). The browser adds micro-variation (timing jitter, velocity) using the shared PRNG. Both are deterministic.

### 4.3 What the Browser Does NOT Do

The browser does not use the PRNG for:
- Motif selection (server decides)
- Scale degree selection (server decides)
- Register base selection (server decides)
- Fragment pitch selection (server decides)

These are musical decisions that must be authoritative. The browser only uses the PRNG for performance-level nuance.

---

## 5. Edge Cases

### 5.1 Epoch Boundary Continuity

When an epoch changes, the PRNG seed changes. This means the variation pattern changes abruptly. This is acceptable because:

- Epoch boundaries already involve a scale/root/energy change
- The listener's attention is on the larger transition, not micro-variation
- Form cycle phase offset (separate from PRNG) ensures the breathing rhythm doesn't jump

### 5.2 PRNG Exhaustion

An epoch lasts 15 minutes. At typical consumption rates, the PRNG will produce at most a few hundred values per epoch. With a period of 2³², there is zero risk of exhaustion or pattern repetition within an epoch.

### 5.3 Cross-Platform Consistency

The Elixir and JavaScript Mulberry32 implementations must produce bit-identical output. The test suite should include a set of known seed→value pairs that both implementations must match:

```
seed=0:       first value = 0.232560
seed=1:       first value = 0.816482
seed=42:      first value = 0.382904
seed=2147483647: first value = 0.584631
```

These values should be verified in both Elixir and JavaScript tests.

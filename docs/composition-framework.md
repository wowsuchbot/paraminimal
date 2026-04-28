# Composition Framework

> *"This is the dream: a music that breathes with the hours. Not a playlist cued to the clock, but a single living organism whose harmonic language, melodic character, and textural density are functions of time itself."*

## 1. Time as Tonality

The day is the meta-structure. Different periods aren't just different seeds — they're different **formal systems**, each with their own axioms: scales, motifs, energy profiles, rhythmic tendencies, and preferred contrapuntal operations.

### 1.1 Periods

The day is divided into time periods. Each period has:

- **A scale (or scale family)** — chosen for its acoustic character matching the time of day
- **Energy profile** — a curve describing how active the music should be
- **Density profile** — how much sonic material is present
- **Motif vocabulary** — melodic fragments native to this period
- **Contrapuntal tendency** — which canon operations this period prefers
- **Rhythmic character** — tempo range, groove type, rhythmic complexity

Period boundaries are soft — transitions happen over zones, not instants. (See §3.)

### 1.2 Period Definitions (Initial)

These are starting points, not final. The system should be able to expand, refine, or reconfigure these.

| Period | Hours | Character | Scale Candidates | Energy | Texture |
|--------|-------|-----------|-----------------|--------|---------|
| Deep Night | 0–5 | still, recursive | diminished, chromatic fragments | minimal | near-silence |
| Dawn | 5–8 | emerging, luminous | Lydian, major pentatonic | rising | sparse → unfolding |
| Morning | 8–12 | bright, active | Ionian, Mixolydian | high | full, rhythmic |
| Afternoon | 12–17 | warm, flowing | Dorian, major pentatonic | sustained | melodic focus |
| Twilight | 17–20 | transitional, wistful | Aeolian, harmonic minor | falling | thinning |
| Night | 20–24 | dark, mysterious | Phrygian, locrian fragments | low, tense | sparse, reverberant |

### 1.3 Scale Library

Each scale entry carries:

```elixir
%Scale{
  name: "Dorian",
  intervals: [0, 2, 3, 5, 7, 9, 10],  # semitones from root
  mode_number: 2,                       # position in parent major scale
  parent_key: "C major",                # relative major
  character_tags: [:minor, :bright, :flowing],
  energy_range: {0.3, 0.7},
  typical_register: {48, 72},           # MIDI range
  period_affinity: [:afternoon, :twilight],
  transition_distances: %{}              # computed, see §2
}
```

**Scale library will be built in stages:**

- **Stage 1 (now):** Western diatonic modes + pentatonic + minor variants. ~15 scales with full metadata.
- **Stage 2 (later):** Extended harmonies — harmonic minor, melodic minor modes, whole tone, octatonic.
- **Stage 3 (later):** Non-Western systems — raga, maqam — each with their own transition logics.
- **Stage 4 (later):** Microtonal and arhythmic systems.

The library is the foundation. Everything else (transitions, motifs, voice leading) depends on it.

---

## 2. Scale Relationships & Distance

Transitions between periods require transitioning between their scales. We don't invent transition heuristics — we use established music theory to compute *how reachable* one scale is from another.

### 2.1 Distance Metrics

Given scale A → scale B, the system computes:

**Shared tones** — intersection of note sets. C major (C D E F G A B) and A minor (A B C D E F G) share 7/7. C major and F♯ major share 1/7. More shared tones = smoother path.

**Circle of fifths distance** — how many steps apart on the circle. One sharp/flat apart is close. Tritone apart is far. This is acoustically grounded in the harmonic series.

**Minimal voice leading cost** — the total semitone distance each voice must travel to move from a chord in scale A to the nearest chord in scale B. Formalized by Dmitri Tymoczko's geometric music theory — scales are points in a space, voice leading is distance.

**Interval vector similarity** — comparing the distribution of interval classes. Two scales with similar interval content feel related even if their roots differ.

### 2.2 Distance Output

```elixir
%ScaleDistance{
  from: "Dorian",
  to: "Aeolian",
  shared_tones: 6,
  shared_ratio: 0.857,
  circle_fifths_distance: 1,
  voice_leading_cost: 2,        # total semitones across all voices
  interval_vector_similarity: 0.92,
  recommended_strategies: [:common_tone, :modal_interchange, :melodic_migration]
}
```

### 2.3 Research Stages

**Stage 1 (now):** Implement the distance metrics above. Build the initial scale library. Validate that the computed distances match musical intuition (C→G should be "close," C→F♯ should be "far").

**Stage 2:** Classical modulation techniques as programmable rules — pivot chord, common tone, chromatic mediant, enharmonic modulation. Each has preconditions and a procedure. Map which strategies work for which distance ranges.

**Stage 3:** Compose the transition vocabulary — take theoretical strategies and shape them into the "acts" the system performs (see §3).

**Stage 4:** Extend to non-Western systems with their own transition logics.

---

## 3. Transitions as Compositional Acts

A transition is not a crossfade, blend, or parameter ramp. It is an **act** — the old material *does something* to arrive at the new state. The material has agency.

### 3.1 Philosophy

The old state doesn't get quieter while the new state fades in. The old state **performs its own transformation**. A Middle Eastern melody doesn't dissolve — it finds a melodic path to the new tonal center. A dense rhythmic texture doesn't thin out — it loses conviction, its pulses becoming irregular before the new rhythm emerges with its own logic.

Silence is a natural part of the music, not a failure mode. A transition may use silence as arrival — the old material completes a phrase and doesn't continue. The silence is the transition.

### 3.2 Transition State Machine

Transitions are a **separate compositional layer** with their own state:

```
Epoch timeline:
  [period A ───────] [transition] [────── period B ──────]

Transition has its own:
  - strategy     (chosen from palette based on context)
  - duration     (constrained by time window, not fixed)
  - progression  (a sequence of acts, not a curve)
  - phase        (initiation → path → arrival)
```

A transition is triggered when the time system signals it's time to move toward the next period. The transition strategy is selected based on context (old state, new state, available time, energy level). Then the transition **runs** as its own compositional process.

### 3.3 Transition Strategy Palette

Each strategy is a rule set for how material transforms. They are not mutually exclusive — a single transition may compose multiple strategies.

**Melodic migration** — the active melody walks stepwise toward the new tonal center. Actual performed notes that gradually shift the interval set. Like watching someone walk from one room to another through a hallway.

**Fragmentation and reassembly** — old material breaks into smaller cells. The cells drift, recombine, and new material emerges from the debris. Good for high→low energy.

**Common tone sustention** — find a pitch shared between old and new harmony. Sustain it. Let everything else fall away. Rebuild the new harmony around that held tone. A baton pass.

**Rhythmic dissolution** — the rhythm gradually disorders itself. Steady pulses become irregular, then sparse, then the new rhythm emerges. The old tempo doesn't fade — it *loses conviction*.

**Register collapse** — all voices drift toward a central register, compress vertically, reach a unison or narrow cluster, then expand outward into the new harmonic space. A breath before expansion.

**Canon handoff** — the old motif plays forward while the new motif plays it in retrograde. They cross paths. At the intersection, you can't tell which is which. Then the new motif continues alone.

**Silence as arrival** — the old material completes a phrase and simply doesn't continue. The silence that follows isn't empty — it's the space where the listener expects something, and the new material enters that space.

**Modal interchange drift** — before changing scales entirely, the old scale begins borrowing tones from the new scale. A Dorian melody starts using an Aeolian flat 6. The boundary erodes from within.

**Voice leading migration** — each drone voice computes the nearest pitch in the target scale and glides to it (portamento). Shared tones are anchors. Moving voices glide at different rates, creating a moment of harmonic ambiguity.

### 3.4 Strategy Selection

The system selects strategies based on context:

- **Energy delta** — large energy changes favor fragmentation or register collapse. Small changes favor melodic migration.
- **Scale distance** — close scales (many shared tones) favor common tone sustention or modal interchange. Distant scales favor silence as arrival or canon handoff.
- **Available time** — short windows force efficient strategies (common tone, silence). Long windows allow elaborate paths (canon handoff, fragmentation).
- **Current density** — already sparse music may use register collapse (there's room). Dense music may use fragmentation (there's material to break).

### 3.5 Transition Timing

The time structure constrains transitions but doesn't dictate their internal pacing. The system receives:

- A **deadline** — "you must arrive by this time"
- An **earliest start** — "don't begin before this time"
- A **suggested window** — "this is roughly how long you have"

The transition composes its own internal pacing to meet the deadline. It may linger, accelerate, or pause — but it arrives on time.

---

## 4. Motifs & Strange Loops

### 4.1 Motif Structure

Each time period has a small set of motifs (3–5). Each motif is:

```elixir
%Motif{
  id: "dawn_rising_3",
  scale_degrees: [0, 2, 4, 5, 7, 4, 2],     # relative to scale root
  rhythm: [1, 0.5, 0.5, 1, 1, 0.5, 2],       # relative durations
  octave: 0,                                   # transposition offset
  period_affinity: :dawn,
  transformation_tendency: [:augmentation, :transposition],
  energy_range: {0.2, 0.5}
}
```

Motifs are defined in **scale degrees**, not absolute pitches — so they're portable across scales.

### 4.2 Canon Operations

The system can apply contrapuntal transformations to motifs:

- **Retrograde** — play backwards (time reversal)
- **Inversion** — mirror intervals (up becomes down)
- **Augmentation** — stretch rhythm (half speed)
- **Diminution** — compress rhythm (double speed)
- **Transposition** — shift to different scale degree
- **Additive permutation** — rotate the rhythmic pattern (messiaen technique)

Each period has a **transformation tendency** — which operations it prefers. Dawn favors augmentation (stretching open). Night favors inversion and retrograde (turning things inside out).

### 4.3 The Strange Loop

A motif from dawn reappears at midnight, but inverted and in a different scale. The *structure* is self-similar across time — same DNA, different expression. A listener who pays attention across hours would recognize the echoes.

This is the strange loop: you descend through layers of transformation and arrive back where you started, but at a different level. The formal system contains a representation of itself.

The system explicitly tracks motif lineage — every transformation is recorded, so it can trace the path from any current musical fragment back to its origin motif and the chain of transformations that produced it.

---

## 5. Current State (Ported from www.mxjxn.com/generative)

The existing generative page is entirely client-side JavaScript (~1100 lines). Here's what it does and what changes for paraminimal:

### 5.1 What Exists Now

- **Mulberry32 PRNG** — deterministic seeded random number generator
- **Bjorklund algorithm** — Euclidean rhythm generation
- **Markov chain** — pitch transitions biased toward stepwise motion and gravity toward root
- **Epoch system** — 1-hour epochs, `floor(Date.now() / 3600000)` as seed
- **Form modulation** — 20-second smooth cycles of density and energy
- **Three sound layers:**
  - Drone: `prophet` chord pads + `dark_ambience` sub (immediate)
  - Melodic: `pretty_bell` / `pluck` via Euclidean rhythm (after 6s)
  - Textural: `blade` / `dsaw`, sparser Euclidean (after 12s)
- **Scale:** fixed minor pentatonic `[0, 3, 5, 7, 10]` across octaves -1 to +2
- **Viz rack:** SVG knobs, gauges, step indicators for KEY / DRONE / FORM / RHYTHM / PHASE
- **SuperSonic WASM** — all synthesis client-side

### 5.2 What Changes for Paraminimal

| Aspect | Current | Paraminimal |
|--------|---------|-------------|
| Scale | Fixed minor pentatonic | Time-of-day driven scale library |
| Harmony | Single epoch-seeded chord | Period-appropriate harmony + voice leading |
| Time structure | 1-hour epochs only | Periods → transitions → motifs |
| Melody | Markov random walk | Motif-based with canon operations |
| Rhythm | 2 Euclidean layers | Period-appropriate, strategy-driven |
| Transitions | Hard epoch boundary | Compositional acts with strategy palette |
| Sync | Client-side deterministic | Server-authoritative epoch + PubSub |
| Interactivity | None | Listener influence (TBD) |
| Persistence | None | Postgres epoch history |
| Deployment | Static Astro page | Phoenix LiveView + Caddy |

### 5.3 What Stays

- Mulberry32 PRNG (deterministic, portable to Elixir)
- Bjorklund algorithm (will be part of rhythmic vocabulary)
- SuperSonic WASM for client-side synthesis
- SVG viz rack aesthetic (knobs, gauges, dark theme)
- The overall "press to begin, music grows" UX

---

## 6. Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                   PHOENIX SERVER                │
│                                                 │
│  ┌──────────────┐   ┌────────────────────────┐  │
│  │ Time System  │──▶│  Epoch Composer        │  │
│  │              │   │  - current period      │  │
│  │ - periods    │   │  - scale, energy,      │  │
│  │ - transitions│   │    density, motifs     │  │
│  │ - deadlines  │   │  - transition state    │  │
│  └──────────────┘   └───────────┬────────────┘  │
│                                  │               │
│                     ┌────────────▼────────────┐  │
│                     │  Scale Library           │  │
│                     │  - definitions           │  │
│                     │  - distance metrics      │  │
│                     │  - voice leading         │  │
│                     └────────────┬────────────┘  │
│                                  │               │
│                     ┌────────────▼────────────┐  │
│                     │  Motif Engine            │  │
│                     │  - motif definitions     │  │
│                     │  - canon operations      │  │
│                     │  - transformation chain  │  │
│                     └────────────┬────────────┘  │
│                                  │               │
│                     ┌────────────▼────────────┐  │
│                     │  Transition System       │  │
│                     │  - strategy palette      │  │
│                     │  - state machine         │  │
│                     │  - strategy selection    │  │
│                     └────────────┬────────────┘  │
│                                  │               │
│  ┌──────────────┐   ┌────────────▼────────────┐  │
│  │  Postgres    │   │  PubSub → LiveView      │──┼──▶ clients
│  │  - epochs    │   │  - broadcast state      │  │
│  │  - sessions  │   │  - listener presence    │  │
│  │  - moments   │   │  - interaction events   │  │
│  └──────────────┘   └─────────────────────────┘  │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│                   CLIENT (BROWSER)               │
│                                                 │
│  ┌──────────────┐   ┌────────────────────────┐  │
│  │ LiveView     │──▶│  SuperSonic WASM       │  │
│  │ (state recv) │   │  - synthdefs            │  │
│  │              │   │  - audio scheduling      │  │
│  └──────────────┘   └────────────────────────┘  │
│                                                 │
│  ┌────────────────────────────────────────────┐ │
│  │  Viz Rack (SVG)                            │ │
│  │  KEY · DRONE · FORM · RHYTHM · PHASE       │ │
│  └────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

The server is the **single source of truth** for what's happening compositionally. It computes the current period, manages transitions, selects motifs, and broadcasts state. Clients receive state and render audio + visuals. This means all listeners hear the same music at the same time.

---

## 7. Open Questions

These are design decisions to be made before or during implementation:

1. **Period granularity** — 6 periods as sketched? Finer (every 2h)? Or should the system compose its own period boundaries based on a continuous time→character function?

2. **Motif authoring** — hand-composed seed motifs (clear intent, less variety) or procedurally generated from rules (more variety, less control)? Hybrid?

3. **Cross-period motif referencing** — should the system explicitly reuse motifs from previous periods (strange loop), or let it emerge from shared pools?

4. **Interaction model** — what can a listener *do*? Push energy? Shift root? Vote on next transition strategy? This is TBD but should inform the architecture from the start.

5. **Epoch persistence** — save every epoch to Postgres for replay/reconstruction? This enables "moment NFTs" later but adds storage complexity.

6. **Real-time constraints** — the current system polls at 220ms. Phoenix LiveView + PubSub can push at similar rates. Is this sufficient, or do we need sub-100ms for rhythmic tightness?

7. **Geographic time** — should the time system use UTC, server local time, or the listener's local time? Using listener time means two people hear different music. Using UTC means a consistent global composition.

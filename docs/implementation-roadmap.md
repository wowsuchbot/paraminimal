# Implementation Roadmap

Phased build plan. Each phase produces working software — no long stretches without something runnable.

## Phase 1: Foundation (do first)

**Goal:** Phoenix app running with the scale library and distance metrics.

### 1.1 Scaffold Phoenix

**First PR scope — keep this small:**

- `mix phx.new paraminimal --live --no-dashboard --no-ecto` then add Ecto
- Configure Postgres
- One LiveView page (`/`) with period + scale + root displayed as plain text
- Deploy to `paraminimal.mxjxn.com` via Caddy + pm2
- Verify: visiting the URL shows something, pm2 keeps it alive

That's it. No viz rack, no canvas, no CSS polish. A white page with "Afternoon · Dorian · D3" that updates.

### 1.2 Scale Library

- Implement `Composition.Scale` struct
- Build `Scales.Western` — all 7 diatonic modes + major/minor pentatonic + natural/harmonic/melodic minor (~15 scales)
- Each scale: intervals, character tags, energy range, typical register, period affinity
- Write tests: verify interval sets, shared tone computation

### 1.3 Scale Distance Metrics

- Implement `Composition.ScaleDistance`
- Shared tones computation
- Circle of fifths distance
- Minimal voice leading cost (Tymoczko-inspired)
- Interval vector similarity
- Strategy recommendation based on distance range
- Write tests: C→G should be close, C→F♯ should be far, validate against musical intuition

**Deliverable:** A running Phoenix app at `paraminimal.mxjxn.com` with a page that displays the current scale and its distance to adjacent scales. The composition engine works in tests.

---

## Phase 2: Time System & Epochs

**Goal:** The server knows what time it is and what period it's in.

### 2.1 Time System

- Implement `Composition.TimeSystem`
- Period definitions with time ranges and scale bindings
- `current_period/0` — returns the active period for now
- Transition zone detection — is the system in a core zone or approaching a boundary?
- **Timezone: server UTC.** Everyone hears the same composition. Listener-local time is a future option, not a blocker.

### 2.2 Epoch Composer

- Implement `Composition.Epoch`
- Given a period, compute the full epoch state: scale, root, chord shape, energy, density, motif set
- Deterministic — same inputs always produce the same epoch
- Epoch change detection — when does the epoch need recomputing?

### 2.3 LiveView Integration

- Wire TimeSystem → Epoch → LiveView
- Display current period, scale, root note on the page
- Auto-updates as time passes
- PubSub broadcast on epoch change

**Deliverable:** Page shows "Current: Afternoon · Dorian · D3 · density 0.62 · energy 0.45" and updates live.

---

## Phase 3a: Motif Engine (Pure Elixir)

**Goal:** The composition engine can select and transform motifs. No browser needed.

### 3a.1 Motif Definitions

- Define initial motifs for each period (3–5 per period)
- Scale-degree representation with rhythm
- Port to Elixir data modules

### 3a.2 Motif Engine

- Implement `Composition.MotifEngine`
- Canon operations: retrograde, inversion, augmentation, diminution, transposition
- Motif selection based on period and form state
- Transformation chain tracking
- **All testable from `mix test` — no Phoenix, no browser, no audio**

**Deliverable:** Tests pass. Given a period and epoch state, the engine produces a motif sequence with transformations. You can trace lineage from any fragment back to its origin.

---

## Phase 3b: Audio & Viz (Browser)

**Goal:** You can hear the music and see the viz rack. The riskiest integration work.

### 3b.1 SuperSonic Hook

- Port the JS hook from generative.astro
- LiveView `pushEvent` → hook receives epoch state → schedules OSC to SuperSonic
- Load relevant synthdefs based on current period
- This is the highest-risk piece — WASM + LiveView bridge. Start here, get it working with a single drone note, then expand.

### 3b.2 Audio Playback

- Drone layer: chord pads + ambience (port from generative.astro)
- Melodic layer: motif-based (from 3a) instead of Markov
- Textural layer: motif fragments, sparse

### 3b.3 Viz Rack

- Port SVG components (VizKnob, VizGauge, StepIndicator) from generative.astro
- Wire to LiveView state updates
- Dark theme, same aesthetic as the original

**Deliverable:** You can press play and hear generative music that changes character based on time of day. Viz rack renders live.

---

## Phase 4: Transitions

**Goal:** Period changes happen as compositional acts, not hard cuts.

### 4.1 Transition State Machine

- Implement `Composition.Transition`
- States: `stable` → `initiating` → `in_progress` → `arriving` → `stable`
- Triggered by TimeSystem boundary detection
- Deadline-aware — knows when it must arrive

### 4.2 Strategy Palette

- Implement `Composition.TransitionStrategy`
- Initial strategies: melodic migration, common tone sustention, rhythmic dissolution, register collapse, silence as arrival
- Strategy selection based on context (energy delta, scale distance, available time)
- Each strategy is a rule set, not a fixed algorithm

### 4.3 Voice Leading

- Smooth pitch migration between scales
- Compute minimal voice leading paths
- Portamento/glide for drone voices
- Anchor shared tones

### 4.4 Integration

- Transitions drive epoch state changes
- LiveView shows transition progress
- Audio responds to transition state in real-time

**Deliverable:** Music transitions smoothly between periods. You can hear the transition happen as a musical act.

---

## Phase 5: Multiplayer & Persistence

**Goal:** Multiple listeners hear the same music. Epochs are saved.

### 5.1 Phoenix Presence

- Track connected listeners
- Display listener count
- Presence-based events (someone joined, someone left)

### 5.2 Postgres Persistence

- Epoch schema — save each epoch with full state
- Session schema — track listener sessions
- Query historical epochs

### 5.3 Server-Authoritative Sync

- All musical state computed server-side
- PubSub broadcasts to all connected clients
- Late-joining clients get current epoch state and catch up

**Deliverable:** Two browser tabs play the same music in sync. Epoch history queryable.

---

## Phase 6: Interaction & Polish (later)

**Goal:** Listeners can influence the music. The experience is refined.

### 6.1 Listener Influence (TBD — design needed)

- What can listeners do? Push energy? Vote on transitions?
- How does influence propagate?
- Rate limiting and abuse prevention

### 6.2 UX Polish

- Refined viz rack animations
- Mobile responsive
- Offline graceful degradation
- Error states

### 6.3 Smart Contracts (much later)

- Moment NFTs
- Influence registry on-chain
- Chain TBD

---

## Dependencies

```
Phase 1 (foundation)
  ├── 1.1 Phoenix scaffold ← no deps
  ├── 1.2 Scale library ← needs 1.1
  └── 1.3 Distance metrics ← needs 1.2

Phase 2 (time system)
  ├── 2.1 TimeSystem ← needs 1.2
  ├── 2.2 Epoch ← needs 2.1
  └── 2.3 LiveView ← needs 2.2

Phase 3a (motif engine, pure Elixir)
  ├── 3a.1 Motif definitions ← needs 1.2
  └── 3a.2 Motif engine ← needs 3a.1

Phase 3b (audio & viz, browser)
  ├── 3b.1 SuperSonic hook ← needs 2.3
  ├── 3b.2 Audio playback ← needs 3a.2 + 3b.1
  └── 3b.3 Viz rack ← needs 3b.1

Phase 4 (transitions)
  ├── 4.1 Transition state machine ← needs 2.1
  ├── 4.2 Strategy palette ← needs 4.1 + 1.3
  ├── 4.3 Voice leading ← needs 1.3
  └── 4.4 Integration ← needs 4.1 + 4.2 + 4.3

Phase 5 (multiplayer)
  ├── 5.1 Presence ← needs 2.3
  ├── 5.2 Persistence ← needs 2.2
  └── 5.3 Sync ← needs 5.1 + 5.2

Phase 6 (interaction) ← needs Phase 5
```

## Key Decisions

- **Timezone: server UTC.** All listeners hear the same composition. Listener-local time is a future option.
- **Server is single source of truth.** All musical state computed server-side. JS is a renderer, not a composer.
- **220ms polling is fine.** SuperSonic handles audio-accurate scheduling client-side. The server pushes *what* to play, not *when precisely*.
- **First PR is minimal.** Scaffold + one scale + one test + deployed. Everything else branches from there.

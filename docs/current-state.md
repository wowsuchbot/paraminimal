# Current State

Last updated after the Phase 4 chord-vocabulary and voicing slice.

## Summary

Paraminimal is now a runnable Phoenix LiveView application with a pure Elixir composition core, first real browser audio, and composed transition planning. The app computes a shared UTC-derived musical epoch, selects and transforms a period motif deterministically, renders epoch state on the root page, can play a SuperSonic-powered four-bar motif/drone loop from the current composition payload, and now builds deterministic multi-bar transition plans with chord vocabulary-backed voiced harmonic waypoints near period boundaries.

## Implemented

### Phoenix Foundation

- Phoenix LiveView app scaffolded.
- Ecto/Postgres configured.
- Root route mounted as `ParaminimalWeb.SessionLive`.
- Tailwind/esbuild asset pipeline from the Phoenix scaffold.
- Standard Phoenix test support.

### Composition Core

Implemented under `lib/paraminimal/composition/`:

- `Scale`: scale metadata and pitch-class helpers.
- `ScaleDistance`: shared tones, circle-of-fifths distance, voice-leading cost, interval-vector similarity, and transition strategy recommendations.
- `TimeSystem`: six UTC time periods, next-period lookup, period progress, and transition-zone detection.
- `Epoch`: deterministic UTC-derived composition state.
- `Motif`: period-affined melodic fragments represented as scale degrees and relative rhythm.
- `MotifEngine`: pure canon transformations and lineage tracking.
- `TransformedMotif`: transformed motif state with source id and transformation chain.
- `ChordVocabulary`: modal chord roles, scale masks, characteristic tones, arrivals, and avoid-note metadata.
- `Transition`: composed multi-bar path from source musical state to destination state.
- `TransitionStrategy`: deterministic strategy palette for harmonic, melodic, and rhythmic transition intent.
- `Voicing`: deterministic low/mid-register voicing pass for transition waypoints.

Implemented under `lib/paraminimal/scales/`:

- `Western`: initial Western scale library with modes, pentatonics, minor variants, diminished, whole tone, and chromatic.

Implemented under `lib/paraminimal/motifs/`:

- Period-specific motif libraries for deep night, dawn, morning, afternoon, twilight, and night.
- `Paraminimal.Motifs` registry for period and id lookup.

### LiveView UI

The root page displays:

- Current UTC epoch id.
- Current period.
- Current scale and root.
- Selected source motif and transformation.
- Energy and density.
- Chord shape.
- Transition status.
- Transition plan phase, bar position, path technique, and arrival gesture.
- Adjacent/next-period scale relationship metrics.
- SuperSonic runtime start/stop control.

The LiveView refreshes every 15 seconds and pushes compact `composition_state` payloads to the browser hook for audio scheduling.

### SuperSonic Boundary

Implemented in `assets/js/hooks/supersonic_runtime.js`:

- Owns user-gesture audio startup.
- Imports `supersonic-scsynth` from the assets npm package.
- Initializes SuperSonic in compatible `postMessage` mode.
- Loads built-in Sonic Pi synthdefs for one motif voice and one drone voice.
- Receives `composition_state` events from LiveView.
- Plays a four-bar motif loop through SuperSonic from server-computed motif degrees, rhythm, root, and scale state.
- Adds a sustained drone voice from epoch root, scale intervals, density, energy, and chord shape.
- During active transitions, renders drone/pad motion from server-voiced harmonic waypoints.
- Keeps an `AudioContext` fallback preview if SuperSonic cannot initialize.
- Keeps button and status text synced across LiveView re-renders.

SuperSonic has two relevant serving modes:

- `postMessage`: compatible mode, no special COOP/COEP headers required.
- `sab`: lower-latency SharedArrayBuffer mode, requires `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` on all relevant responses.

### Tests

Current suite covers:

- Scale definitions and pitch classes.
- Scale distance behavior.
- UTC period boundaries.
- Transition zones.
- Epoch determinism.
- Motif definitions.
- Motif transformations.
- Chord vocabulary scale masks and avoid-note metadata.
- Deterministic low/mid-register voicing.
- Transition path enrichment with voiced harmonic waypoints.
- LiveView rendering.

Latest known result:

```bash
mix assets.build && mix test
# 59 tests, 0 failures
```

## Not Implemented Yet

- Viz rack.
- Production-local serving strategy for SuperSonic engine/synthdef assets.
- Audio-accurate scheduling beyond the current JavaScript timer loop.
- Full transition audio rendering: guide-tone melody, glides, rhythmic fills, silence arrivals, and progressive chord changes.
- PubSub/shared epoch process.
- Presence/listener tracking.
- Epoch persistence schemas.
- Listener influence model.
- Smart contracts.

## How To Run

```bash
mix deps.get
mix ecto.create
mix phx.server
```

Open `http://localhost:4323`.

Do not read or edit `.env` files. If environment variables are needed, ask the user to manage them manually.

## Next Recommended Work

Continue Phase 4: Transitions.

The chord-vocabulary and voicing layer is in place. Next implementation should deepen Phase 4 audio response:

- Map `transition_plan.melodic_path` to guide-tone motif behavior.
- Render `transition_plan.rhythmic_gesture` as optional fill/break/percussion material.
- Add more intentional arrival handling in SuperSonic for `arrival_gesture`.
- Keep the server as composer; browser/SuperSonic remains the renderer.

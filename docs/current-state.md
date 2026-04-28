# Current State

Last updated after Phase 2.

## Summary

Paraminimal is now a runnable Phoenix LiveView application with a pure Elixir composition core. The app computes a shared UTC-derived musical epoch and renders it on the root page.

The project does not yet produce SuperSonic audio. A browser runtime hook exists so the audio integration has a clear place to attach in Phase 3.

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

Implemented under `lib/paraminimal/scales/`:

- `Western`: initial Western scale library with modes, pentatonics, minor variants, diminished, whole tone, and chromatic.

### LiveView UI

The root page displays:

- Current UTC epoch id.
- Current period.
- Current scale and root.
- Energy and density.
- Chord shape.
- Transition status.
- Adjacent/next-period scale relationship metrics.
- SuperSonic runtime start control.

The LiveView refreshes every 15 seconds and pushes compact `composition_state` payloads to the browser hook for future audio scheduling.

### SuperSonic Boundary

Implemented in `assets/js/hooks/supersonic_runtime.js`:

- Owns user-gesture audio startup.
- Creates an `AudioContext` fallback.
- Detects a future `window.SuperSonic` runtime if present.
- Receives `composition_state` events from LiveView.
- Leaves the actual OSC/SuperSonic scheduling for Phase 3.

### Tests

Current suite covers:

- Scale definitions and pitch classes.
- Scale distance behavior.
- UTC period boundaries.
- Transition zones.
- Epoch determinism.
- LiveView rendering.

Latest known result:

```bash
mix test
# 20 tests, 0 failures
```

## Not Implemented Yet

- Real SuperSonic package/runtime integration.
- SynthDefs or OSC scheduling.
- Motif definitions and motif transformation engine.
- Transition state machine beyond boundary detection.
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

Open `http://localhost:4000`.

Do not read or edit `.env` files. If environment variables are needed, ask the user to manage them manually.

## Next Recommended Work

Phase 3: Motifs & Audio.

Start narrow:

- Define a small motif set.
- Add `Composition.MotifEngine`.
- Translate epoch state into one audible SuperSonic drone and one motif voice.
- Keep all musical decisions server-computed and deterministic.

# Phase 3: Motifs & Audio

## Goal

Turn the deterministic epoch state into audible music. This phase should make Paraminimal feel like a music system rather than a dashboard.

## Core Work

### Motif Definitions

Add period-specific motifs under `lib/paraminimal/motifs/`. Motifs should be represented as scale degrees and relative rhythms so they can move across roots, scales, and periods.

Initial target:

- 3-5 motifs per period.
- Scale-degree pitch material.
- Relative durations.
- Period affinity.
- Energy range.
- Preferred transformations.

### Motif Engine

Add `Paraminimal.Composition.MotifEngine` to select and transform motifs for the current epoch.

Initial transformations:

- Retrograde.
- Inversion.
- Augmentation.
- Diminution.
- Transposition.
- Rhythmic rotation.

The engine should track transformation chains so motif lineage can support the strange-loop concept later.

### SuperSonic Runtime Integration

Replace the current SuperSonic runtime stub with the first real scheduling path.

The server should continue to compute musical state. The browser should initialize SuperSonic from a user gesture, receive compact state through LiveView events, and translate that state into scheduled audio actions.

Initial audio layers:

- Drone layer: sustained chord or root/fifth pad.
- Melodic layer: one motif voice.
- Texture layer: optional sparse fragments if the first two layers are stable.

## Deliverable

Pressing the audio start button should produce time-of-day-driven generative music. The first version can be musically simple, but it should use the real epoch, scale, root, energy, and density values.

## Verification

- Motif transformations are covered by pure Elixir tests.
- Epoch-to-audio payloads are stable and inspectable.
- Browser startup still requires a user gesture.
- The page remains usable when audio initialization fails.

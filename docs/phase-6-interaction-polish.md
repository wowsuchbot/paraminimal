# Phase 6: Interaction & Polish

## Goal

Turn the synchronized generative system into a refined listener experience. This phase adds controlled listener influence, stronger visuals, mobile polish, and later on-chain concepts.

## Core Work

### Listener Influence

Design an interaction model that lets listeners affect the music without breaking determinism or letting one listener dominate the experience.

Possible first interactions:

- Push energy up or down.
- Nudge density.
- Vote on transition strategy.
- Mark or save a moment.
- Add small influence to motif selection.

Influence should be rate-limited and aggregated server-side. The server remains authoritative.

### UX Polish

Refine the visual and interaction layer.

Targets:

- Responsive layout.
- Better loading and audio-permission states.
- Clear audio failure states.
- More expressive viz rack components.
- Mobile-friendly controls.
- Better transition and listener indicators.

### Audio Polish

Improve the SuperSonic side once the musical architecture is stable.

Targets:

- Richer synthdefs.
- Better drone, motif, and texture voices.
- Smoother scheduling.
- Parameter smoothing for energy, density, and transition progress.
- Graceful CPU limits for mobile browsers.

### Smart Contracts

Smart contracts are later-stage work. They should not drive the early architecture, but persisted epochs and saved moments should leave room for them.

Possible future concepts:

- Moment NFTs.
- Influence registry.
- Provenance for notable epochs.
- Chain choice to be decided later.

## Deliverable

Paraminimal should feel usable, expressive, and shareable. Listeners can influence the system in controlled ways, the UI communicates what is happening, and the audio/visual experience feels intentional across desktop and mobile.

## Verification

- Interaction behavior is rate-limited and tested.
- Multiple listeners cannot desynchronize the composition.
- Mobile layout and audio startup are manually verified.
- Audio failure states are visible and recoverable.

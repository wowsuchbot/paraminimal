# Phase 4: Transitions

## Goal

Make period changes happen as compositional acts, not abrupt changes in parameters. The old musical material should transform itself into the next state.

## Core Work

### Transition State Machine

Add `Paraminimal.Composition.Transition` as a pure Elixir state machine.

Initial states:

- `:stable`
- `:initiating`
- `:in_progress`
- `:arriving`
- `:stable`

The time system should provide the earliest start, deadline, and transition progress. The transition layer should decide how the musical material moves through that window.

### Strategy Palette

Add `Paraminimal.Composition.TransitionStrategy` to choose and execute transition strategies.

Initial strategies:

- Common tone sustention.
- Melodic migration.
- Voice-leading migration.
- Rhythmic dissolution.
- Register collapse.
- Silence as arrival.

Strategy selection should consider:

- Scale distance.
- Energy delta.
- Density.
- Available time.
- Current period and next period.

### Audio Response

The SuperSonic runtime should receive transition state as part of the composition payload. Audio should respond continuously to transition phase and progress.

Examples:

- Shared tones sustain while other voices move.
- Drone voices glide toward target pitches.
- Dense rhythms fragment before a lower-density period.
- Silence is allowed as a deliberate arrival state.

## Deliverable

Moving from one period to another should sound intentional. The UI should show transition state and progress, and the audio should reflect that transition in real time.

## Verification

- Transition state transitions are covered by pure Elixir tests.
- Strategy selection is deterministic for the same context.
- Close and distant scale changes choose different strategies.
- LiveView renders transition state without breaking epoch refresh.

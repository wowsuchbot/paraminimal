# Phase 4: Transitions

## Goal

Make period changes happen as compositional acts, not abrupt changes in parameters. The old musical material should transform itself into the next state through a composed path that may last several bars.

A transition is not just a fade or a UI state. It can be a complete harmonic, melodic, or rhythmic passage from one musical state to another: chord progressions that progressively change toward the destination, melodies that mathematically lead around scales and chord changes, soft tom rolls, cut-up breakbeats, minimal techno kick/snare/hat/fx material, silence, or any other deliberate transition moment.

## Core Work

### Transition State Machine

Add `Paraminimal.Composition.Transition` as a pure Elixir transition planner.

Initial states:

- `:stable`
- `:initiating`
- `:in_progress`
- `:arriving`
- `:stable`

The time system should provide the earliest start, deadline, and transition progress. The transition layer should decide how the musical material moves through that window as a multi-bar composition plan.

The plan should describe:

- Source and destination period, root, scale, and chord shape.
- Duration in bars and current phase.
- Harmonic waypoints between source and destination.
- Melodic guide tones or scale-degree paths.
- Optional rhythmic transition gestures.
- Strategy names that explain why this path was chosen.

### Strategy Palette

Add `Paraminimal.Composition.TransitionStrategy` to choose and execute transition strategies.

Initial strategies:

- Common tone sustention.
- Melodic migration.
- Voice-leading migration.
- Rhythmic dissolution.
- Register collapse.
- Silence as arrival.
- Progressive chord change.
- Rhythmic fill or break.

Strategy selection should consider:

- Scale distance.
- Energy delta.
- Density.
- Available time.
- Current period and next period.

### Harmonic State Vector

Represent each transition endpoint as a comparable state vector:

- `root`: pitch class `0..11`.
- `scale_mask`: 12-bit pitch-class mask for the scale or mode.
- `scale`: scale/mode slug.
- `chord_shape`: current harmonic shape or quality.
- `energy`: `0.0..1.0`.
- `density`: notes/events per bar or normalized density.
- `period_character`: the active period's musical character.

The current implementation already carries most of this through `Epoch` and `transition_plan`. The next refinement is to add explicit chord/voicing data and scale masks so path selection can score techniques more precisely.

### Path Selection Algorithm

Treat each transition technique as a candidate edge through harmonic space. Score every valid technique, apply hard constraints, then choose the highest-scoring path with deterministic tie-breakers.

Core fitness scores:

- `proximity_score`: `1.0 - circle_distance(root_a, root_b) / 6`.
- `energy_score`: how well the technique intensity matches the energy delta.
- `structural_score`: `1.0` when the transition has enough bars for the technique, otherwise `0.0`.
- `common_tone_score`: bitmask intersection between source and destination pitch sets.
- `voice_leading_score`: inverse of total interval distance between source and destination voicings.

Initial technique intensities:

- `tritone_dominant`: `0.9`.
- `chromatic_mediant`: `0.7`.
- `circle_of_fifths`: `0.5`.
- `pivot_chord`: `0.3`.
- `common_tone`: `0.2`.
- `silence_as_arrival`: depends on negative density and energy deltas.

Initial hard constraints:

- `modal_interchange` requires the same root or a clearly defined parallel/modal relation.
- `pivot_chord` requires at least one usable shared chord.
- `chromatic_mediant` requires root distance of 3 or 4 semitones and compatible chord quality.
- `circle_of_fifths` needs enough bars to make the sequence legible.
- `silence_as_arrival` requires a strong drop in energy or density.

Tie-breakers:

1. Prefer lower total voice-leading movement.
2. Prefer techniques that match the period character.
3. Prefer the longer, more legible path when duration is available.
4. Prefer the simpler path when duration is short.

### Harmonic Path Techniques

Initial techniques to represent as transition plans:

- `pivot_chord`: find shared diatonic chords between source and destination; choose a pivot that functions clearly in the destination, then cadence or arrive into the target.
- `common_tone`: hold one or more shared tones while other voices move underneath.
- `circle_of_fifths`: walk roots by fourths/fifths over 8-16 bars, stretching intermediate roots when there are more bars than steps.
- `chromatic_mediant`: move between same-quality chords whose roots are a major/minor third apart; preserve common tones and shift other voices by small intervals.
- `voice_leading_migration`: choose the next chord/voicing by minimizing total interval distance.
- `tritone_dominant`: use `ii -> V7` or `ii -> bII7` into the target for short, high-tension transitions.
- `modal_interchange`: keep the root stable while introducing characteristic pitches from the destination mode.
- `rhythmic_transition`: make rhythm the primary carrier when harmonic movement should stay sparse.

### Arrival Gestures

The arrival is the final 1-2 bars of a transition. It should be selected separately from the travel path.

Initial arrival gestures:

- `authentic_cadence`: use `V7 -> I` when clarity and tonal arrival matter.
- `modal_arrival`: use modal characteristic pitches and bass motion such as `II -> I`, `bVII -> I`, or `IV -> i`.
- `suspended_arrival`: arrive on tonic with `sus2` or `sus4`, then resolve the suspension after the downbeat.
- `common_tone_drone_arrival`: sustain a shared pitch across the boundary while the harmony changes underneath.
- `silence_as_arrival`: cut sound before the arrival and restart with low-density root/fifth material.
- `deceptive_arrival`: imply the target, then land on a related substitute to extend the phrase.
- `rhythmic_drop_arrival`: increase density before the boundary, then drop to a sparse target attack.

The transition plan should eventually contain both a `path_technique` and an `arrival_gesture`; these are related but not identical.

### Chord Vocabulary and Voicing Rules

Each scale/mode needs a deterministic chord vocabulary so transition paths can become concrete voicings.

Initial modal vocabulary:

- `ionian`: characteristic tension is the natural 4 as an avoid tone against the 3rd; tonic `1-3-5-7`; color/predominant `IV`, `ii`; arrival `V7`.
- `dorian`: characteristic major 6; tonic `1-b3-5-6`; color `IV7`, `ii7`; arrival `bVII`.
- `phrygian`: characteristic `b2`; tonic `1-b3-5`; color `bII`, `bIII`; arrival `v_dim`.
- `lydian`: characteristic `#4`; tonic `1-3-5-7-#11`; color `II`, `vii`; arrival `Vmaj7`.
- `mixolydian`: characteristic `b7`; tonic `1-3-5-b7`; color `v`, `bVII`; arrival `IV` or `v`.
- `aeolian`: characteristic `b6`; tonic `1-b3-5-b6`; color `iv`, `bVI`; arrival `v`, `bVII`.
- `locrian`: characteristic `b2` and `b5`; tonic `1-b3-b5`; color `bII`, `iv`; arrival `bV`.

Minor and synthetic vocabularies:

- `harmonic_minor`: characteristic `b6` and major 7; tonic `i(maj7)`; dominant `V7(b9)`; avoid putting `b6 -> 7` in the same melodic voice.
- `melodic_minor`: characteristic major 6 and major 7; tonic `i(maj6/9)`; use quartal or So What-style voicings; all scale tones may be stable.
- `major_pentatonic` and `minor_pentatonic`: no avoid notes; useful for high-density rhythmic passages; prefer quartal stacks.
- `diminished`: use diminished seventh and dominant altered colors; preserve symmetry by allowing voicing shifts by minor thirds.
- `whole_tone`: use augmented/dream-chord sonorities such as `1-3-#5-b7-9-#11`; useful for high-energy transitions.
- `chromatic`: use only constrained subsets; require a selected chord vocabulary or transition technique before voicing.

Register rules:

- Low register: root/fifth/octave power zone. Keep intervals at least a perfect fifth apart; reduce velocity for close low intervals.
- Mid register: guide-tone shell. Prefer 3rd, 7th, and characteristic pitches between `C3` and `C5`.
- High register: extension layer. Add 9ths/11ths/13ths as energy rises; small intervals are acceptable for shimmer.

Mode-specific constraints:

- Ionian natural 4 should be omitted, suspended, or shifted to `#4` when it clashes with the 3rd.
- Phrygian `b2` should sit at least an octave plus a semitone above the root unless used intentionally as a cluster.
- Lydian should include `#4` in the mid/high register when the mode needs to be clearly identified.
- Harmonic minor should split the `b6` and major 7 tendency tones across separate voices.

Avoid-note handling:

1. Generate candidate chord tones.
2. Identify tonal gravity tones, especially root and 3rd.
3. Detect minor ninth conflicts or mode-specific unstable tones.
4. Resolve by one deterministic action: suspend, shift, omit, or mark as passing tone.

### Architecture Decision: Path First, Voicing Second

Transition pathing should be calculated before final voicing.

The path planner chooses musical intent: technique, arrival gesture, roots, scales, bar waypoints, guide tones, density curve, and rhythmic gesture. Then a voicing/voice-leading pass turns each waypoint into concrete playable notes by register.

Reasons:

- The path remains a compositional decision, independent of synth/register details.
- Voice-leading can be tested as a deterministic post-process.
- Browser/SuperSonic receives concrete notes later, but does not decide the form.
- Different renderers can use the same transition path with different voicing policies.

### Audio Response

The SuperSonic runtime should receive transition state as part of the composition payload. Audio should respond continuously to transition phase and progress.

Examples:

- Shared tones sustain while other voices move.
- Drone voices glide toward target pitches.
- Dense rhythms fragment before a lower-density period.
- A melody leads around source and destination scales as guide tones.
- A rhythmic transition uses tom rolls, cut-up breaks, or sparse techno percussion gestures.
- Silence is allowed as a deliberate arrival state.

## Deliverable

Moving from one period to another should sound intentional. The UI should show transition state and progress, and the audio should reflect that transition in real time.

## Open Questions

These are the next research and design questions before deepening the implementation:

- How should the documented chord vocabularies be represented in Elixir: static data modules, structs, or functions attached to each scale family?
- How should `chord_shape` map onto the modal vocabulary? For example, does `:triad` mean a plain triad, or the mode's preferred tonic color?
- What period-character presets should weight path selection? Examples: ambient/still periods may favor common tones and silence, while active periods may favor tritone, rhythmic fill, or circle motion.
- How should transitions handle non-diatonic or synthetic scales where classical pivot chords are weak or unavailable?
- Should a transition have one primary technique, or can it be a layered plan such as `common_tone_drone` plus `rhythmic_fill` plus `modal_arrival`?
- What minimum and maximum bar lengths should each technique support?
- How should guide-tone melodies be generated from harmonic paths: chord tones only, scale characteristic tones, chromatic enclosures, or nearest-neighbor voice-leading?
- What rhythmic gesture vocabulary should be implemented first in SuperSonic: synthesized tom rolls, hats/kicks, breakbeat-like cuts, noise/fx sweeps, or silence/drop gestures?
- How should arrivals avoid sounding too final when the piece is endless?
- What should be visible in the UI: only phase/bar/strategy, or the full harmonic and arrival path?

## Verification

- Transition state transitions are covered by pure Elixir tests.
- Strategy selection is deterministic for the same context.
- Close and distant scale changes choose different strategies.
- LiveView renders transition state without breaking epoch refresh.

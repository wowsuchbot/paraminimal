# Project Structure

Planned directory layout for the Phoenix application.

```
paraminimal/
├── README.md
├── .env.example
├── .gitignore
├── .formatter.exs
├── mix.exs
├── config/
│   ├── config.exs
│   ├── dev.exs
│   ├── test.exs
│   └── prod.exs
│
├── lib/
│   └── paraminimal/                  # main application
│       ├── application.exs
│       ├── repo.exs                  # Ecto repo
│       │
│       ├── composition/              # ★ core music engine
│       │   ├── time_system.ex        # period definitions, current period, transition triggers
│       │   ├── epoch.ex              # epoch state: scale, energy, density, motif selection
│       │   ├── scale.ex              # scale data types + library access
│       │   ├── scale_distance.ex     # shared tones, circle of fifths, voice leading cost
│       │   ├── motif.ex              # motif definitions, scale-degree representation
│       │   ├── motif_engine.ex       # canon operations, transformation chains
│       │   ├── transition.ex         # transition state machine
│       │   └── transition_strategy.ex # strategy palette, selection logic
│       │
│       ├── scales/                   # scale library data
│       │   ├── western.ex            # diatonic modes, pentatonic, minor variants
│       │   ├── extended.ex           # harmonic minor modes, whole tone, octatonic
│       │   └── non_western.ex        # raga, maqam (later)
│       │
│       ├── motifs/                   # motif definitions per period
│       │   ├── deep_night.ex
│       │   ├── dawn.ex
│       │   ├── morning.ex
│       │   ├── afternoon.ex
│       │   ├── twilight.ex
│       │   └── night.ex
│       │
│       ├── live/                     # Phoenix LiveView
│       │   ├── session_live.ex       # main player UI (viz rack + play button)
│       │   └── session_live/
│       │       └── components/       # LiveView components
│       │           ├── viz_rack.ex   # KEY / DRONE / FORM / RHYTHM / PHASE
│       │           ├── viz_knob.ex
│       │           ├── viz_gauge.ex
│       │           ├── step_indicator.ex
│       │           └── epoch_info.ex
│       │
│       ├── presence/                 # Phoenix Presence (listener tracking)
│       │   └── tracker.ex
│       │
│       └── accounts/                 # listener sessions (later)
│           └── session.ex
│
├── priv/
│   └── repo/
│       ├── migrations/               # Ecto migrations
│       └── seeds.exs                 # seed scale library + initial motifs
│
├── test/
│   ├── paraminimal/
│   │   ├── composition/
│   │   │   ├── time_system_test.exs
│   │   │   ├── epoch_test.exs
│   │   │   ├── scale_test.exs
│   │   │   ├── scale_distance_test.exs
│   │   │   ├── motif_test.exs
│   │   │   ├── motif_engine_test.exs
│   │   │   ├── transition_test.exs
│   │   │   └── transition_strategy_test.exs
│   │   └── live/
│   │       └── session_live_test.exs
│   └── support/
│       ├── data/
│       │   ├── scales_test.exs       # test fixtures for scale library
│       │   └── motifs_test.exs       # test fixtures for motifs
│       └── fixtures.exs
│
├── assets/
│   ├── js/
│   │   └── hooks/                    # Phoenix LiveView JS hooks
│   │       ├── supersonic_hook.exs   # init WASM, load synthdefs, wire to LiveView
│   │       ├── viz_knob_hook.js      # SVG knob rendering (ported from Astro)
│   │       ├── viz_gauge_hook.js     # SVG gauge rendering
│   │       └── step_indicator_hook.js
│   ├── css/
│   │   └── app.css                   # dark theme, viz rack styles
│   └── vendor/                       # (none — SuperSonic loads from CDN)
│
└── docs/
    ├── composition-framework.md      # musical architecture (done)
    ├── getting-started.md            # dev setup (done)
    ├── project-structure.md          # this file
    └── implementation-roadmap.md     # build plan
```

## Key Design Decisions

### `lib/paraminimal/composition/` is the heart

Everything musical lives here. It's pure Elixir — no Phoenix, no LiveView, no database. This makes it:
- Testable in isolation (no need to boot Phoenix)
- Portable (could be used from a CLI, a different web framework, etc.)
- Fast (Elixir is great for this kind of stateful computation)

The LiveView layer in `lib/paraminimal/live/` just renders what the composition module produces.

### Scales and motifs are data, not logic

`lib/paraminimal/scales/` and `lib/paraminimal/motifs/` are data modules — they define structs and return lists of definitions. The logic that uses them (distance metrics, transitions, canon operations) lives in `composition/`. This separation means you can add new scales or motifs without touching the engine.

### Tests mirror the composition module

Every module in `composition/` has a corresponding test file. Tests should be the primary way you interact with the engine during development — they serve as both specification and documentation.

### JS hooks are thin

The JavaScript layer (`assets/js/hooks/`) does three things:
1. Initialize SuperSonic WASM and load synthdefs
2. Receive state updates from LiveView (`handleEvent`)
3. Send OSC messages to SuperSonic based on state

All musical logic stays server-side. The JS is a renderer, not a composer.

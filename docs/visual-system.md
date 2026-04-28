# Visual System (Viz Rack)

The visualization layer of Paraminimal — what the listener sees.

## Overview

The viz rack is the visual companion to the audio. It doesn't control the music — it reflects it. Each module in the rack displays a different aspect of the current composition state, giving the listener a window into what they're hearing.

The aesthetic draws from the original `www.mxjxn.com/generative` page: dark theme, SVG-based instruments, knobs and gauges, a technical/clinical look that feels like a studio monitoring system.

---

## 1. Module Inventory

The viz rack has five modules, each corresponding to a dimension of the composition state:

| Module | Label | What It Shows | Primary Input |
|--------|-------|--------------|---------------|
| KEY | Key | Current scale and root | epoch.scale, epoch.root |
| DRONE | Drone | Harmonic foundation state | chord_shape, drone pitches, energy |
| FORM | Form | Meso-level breathing | form cycle progress, form energy, form density |
| RHYTHM | Rhythm | Rhythmic grid activity | Euclidean patterns, phase gating |
| PHASE | Phase | Current period and transition | period, transition zone, progress |

### Module Layout

```
┌─────────────────────────────────────────────────┐
│  PARAMINIMAL                                     │
│                                                   │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  │
│  │ KEY  │  │DRONE │  │ FORM │  │RHYTHM│  │PHASE │  │
│  │      │  │      │  │      │  │      │  │      │  │
│  │ knob │  │gauge │  │ wave │  │steps │  │ arc  │  │
│  │      │  │      │  │      │  │      │  │      │  │
│  └──────┘  └──────┘  └──────┘  └──────┘  └──────┘  │
│                                                   │
│  [listener count]  [epoch id]  [period name]       │
└─────────────────────────────────────────────────┘
```

The modules are displayed horizontally on desktop and stack vertically on mobile.

---

## 2. KEY Module

### 2.1 Purpose

Shows the current tonal center — what key the music is in and what character that key has.

### 2.2 Component: Rotary Knob (VizKnob)

A circular knob that points to the current root pitch class. The knob rotates around 12 positions (one per semitone), like a clock face.

**State mapping:**
- Rotation angle: `root * 30°` (0 = C at 12 o'clock, clockwise through chromatic circle)
- Label: root note name + scale name (e.g., "F Dorian")
- Color: derived from the scale's character tags
  - Major/bright tags → warm color (amber/gold)
  - Minor/dark tags → cool color (blue/cyan)
  - Diminished/unstable → neutral (white/gray)

**Animations:**
- Root changes: smooth rotation (300ms ease-out) to new position
- Scale changes: color transition (500ms)
- No animation during stable playback — the knob stays still

### 2.3 Additional Display

Below the knob:
- Scale name in small text
- Pitch class set as a row of 12 small circles, filled for active notes, hollow for inactive

```
     ◉ ○ ○ ○ ◉ ○ ◉ ○ ○ ○ ◉ ○
      C C# D D# E F F# G G# A A# B
```

This gives a visual representation of the scale's interval structure.

---

## 3. DRONE Module

### 3.1 Purpose

Shows the harmonic foundation — what chord the drone is sustaining and how much energy it has.

### 3.2 Component: VU Gauge (VizGauge)

A vertical or semicircular gauge showing drone energy level.

**State mapping:**
- Fill level: epoch energy (0.0–1.0)
- Fill color: matches the drone's filter state
  - Low energy → dark/muted (deep blue-gray)
  - High energy → brighter (teal/cyan)
- Tick marks at 0%, 25%, 50%, 75%, 100%

### 3.3 Additional Display

Below the gauge:
- Chord shape name (e.g., "triad", "seventh", "open fifth")
- Drone voice count (number of pad voices)
- Active indicator: small dot that glows when drone is sounding

### 3.4 Transition Behavior

During transition zones:
- If the transition involves voice-leading migration, the gauge shows a subtle dual-level display — current energy and target energy overlapping
- If the drone is fading (silence as arrival strategy), the gauge smoothly decreases

---

## 4. FORM Module

### 4.1 Purpose

Shows the meso-level breathing of the music — the 20-second form cycle that modulates density and energy.

### 4.2 Component: Dual Waveform (VizWaveform)

A small oscilloscope-style display showing two overlapping waves:

**Wave 1 (density):**
- Shape: sinusoidal, modulated by smoothstep
- Amplitude: epoch density ± form amplitude
- Color: one color (e.g., cyan)
- Y-axis: 0.0–1.0

**Wave 2 (energy):**
- Shape: sinusoidal, modulated by smoothstep
- Amplitude: epoch energy ± form amplitude
- Color: different color (e.g., amber)
- Y-axis: 0.0–1.0

**Current position:**
- A vertical line or dot that moves along the waveform, showing where in the current form cycle we are
- Progress: `form.cycle_progress` (0.0–1.0)

### 4.3 State Mapping

```
form cycle progress ──▶ waveform cursor position
form_energy ──────────▶ energy wave amplitude
form_density ─────────▶ density wave amplitude
period ───────────────▶ wave frequency (higher energy periods = slightly faster visible oscillation)
```

### 4.4 Animation

The waveform is not static — it shows one or two complete cycles and the cursor moves through it in real time. The animation speed matches the actual form cycle duration (~20s per cycle).

The waveform redraws when:
- A new epoch starts (new baseline energy/density)
- The form cycle resets (cursor wraps around)

---

## 5. RHYTHM Module

### 5.1 Purpose

Shows the Euclidean rhythmic patterns — when notes will sound and when they won't.

### 5.2 Component: Step Indicator (StepIndicator)

A row of small squares or circles, one per Euclidean step. Active steps (onsets) are filled, inactive steps are hollow.

**Two rows:**
- Top row: melodic Euclidean pattern
- Bottom row: textural Euclidean pattern

**State mapping:**
- Number of steps: `n` from the Euclidean pattern
- Active steps: `k` onsets, distributed by Bjorklund
- Current step: highlighted during playback (the step currently being evaluated)

**Colors:**
- Active (onset): bright color (layer-specific — e.g., green for melodic, purple for textural)
- Inactive: dark outline
- Current step: pulsing or brighter version of active/inactive color
- Phase-inactive: entire row dims (when the layer is in a phase rest)

### 5.3 Rotation Display

The step indicator accounts for Euclidean rotation. If the pattern is rotated by 2 steps, the visual pattern shifts accordingly. This lets the listener see the rhythmic displacement.

### 5.4 Transition Behavior

During transition zones:
- If the rhythm is dissolving (rhythmic dissolution strategy), onsets randomly dim or disappear
- If the rhythm is fragmenting, the step indicator shows partial patterns
- If approaching silence, onsets fade gradually

### 5.5 Additional Display

Below the step indicators:
- k/n notation (e.g., "5/12" for melodic, "2/14" for textural)
- Step duration in ms (e.g., "650ms")
- Layer active/inactive status (phase gating)

---

## 6. PHASE Module

### 6.1 Purpose

Shows where we are in the day — the current period, transition status, and progress through the period.

### 6.2 Component: Arc / Ring (VizArc)

A circular arc or ring that represents the full day cycle. The arc is divided into six colored segments (one per period). A marker shows the current position.

**Arc segments:**

```
         Deep Night (0-5h)
       ╱                  ╲
  Night                   Dawn (5-8h)
  (20-24h)              ╱     ╲
      │              Morning   │
      │            (8-12h)     │
      │                         │
       ╲       Afternoon       ╱
  Twilight (17-20h)  (12-17h)  ╱
```

**State mapping:**
- Current period segment: highlighted/glowing
- Current position within segment: small dot or bright point
- Transition zone: the boundary between segments pulses when in the transition window

### 6.3 Additional Display

Below the arc:
- Period name (e.g., "Afternoon")
- Period character text (e.g., "warm, flowing")
- Time remaining in period
- Transition status:
  - Core: "stable"
  - Approaching boundary: "transitioning → [next period name]" with progress bar

### 6.4 Transition Animation

When in a transition zone:
- The current period segment begins dimming
- The next period segment begins brightening
- A progress bar shows transition progress (0.0–1.0)
- The transition strategy name appears briefly when the transition initiates

---

## 7. Footer Status Bar

Below the five modules, a status bar shows persistent information:

```
[listener icon] 3 listening  |  epoch 2026-04-28T16:45Z  |  F Dorian  |  42m to Twilight
```

Elements:
- **Listener count**: from Phoenix Presence, updated in real time
- **Epoch ID**: current 15-minute bucket
- **Key**: root + scale, same as KEY module
- **Next transition**: time to next period boundary

---

## 8. Responsive Behavior

### Desktop (>1024px)

- Five modules in a horizontal row
- Full-size components
- Footer status bar below

### Tablet (768–1024px)

- Three modules per row, two rows
- Slightly reduced component sizes
- Footer below

### Mobile (<768px)

- Single column, modules stacked vertically
- Reduced component sizes (knobs smaller, step indicators fewer steps)
- Only melodic step indicator shown (hide textural row to save space)
- Status bar simplified: period name + listener count only

### Animation Reduction

When `prefers-reduced-motion` is active:
- All transitions become instant (no easing)
- Waveform shows static state (no cursor animation)
- Step indicators show pattern but no current-step highlight
- Arc shows position but no pulsing

---

## 9. Color System

### Base Colors

- Background: `zinc-950` (#09090b)
- Panel background: `zinc-900` (#18181b)
- Panel border: `zinc-800` (#27272a)
- Primary text: `zinc-100` (#f4f4f5)
- Secondary text: `zinc-400` (#a1a1aa)
- Accent: `cyan-400` (#22d3ee) — used for labels, highlights, active states

### Module-Specific Colors

| Module | Active | Inactive | Transition |
|--------|--------|----------|------------|
| KEY | Amber/gold | Zinc-700 | — |
| DRONE | Teal/cyan (energy-mapped) | Zinc-700 | Dual-tone |
| FORM (density) | Cyan-400 | Zinc-800 | — |
| FORM (energy) | Amber-400 | Zinc-800 | — |
| RHYTHM (melodic) | Emerald-400 | Zinc-800 | Dimming |
| RHYTHM (textural) | Violet-400 | Zinc-800 | Dimming |
| PHASE | Cyan-400 | Zinc-800 | Pulsing |

### Dark Mode Only

The viz rack is designed for dark mode only. It is a monitoring/instrument interface — it doesn't need a light mode. The color system assumes a dark background.

---

## 10. Implementation Notes

### Server-Pushed State

All viz module state comes from the server via LiveView assigns and `push_event`. The browser does not compute any visual state independently. It receives:
- Epoch state (KEY, DRONE, PHASE)
- Form state (FORM)
- Euclidean state + current step position (RHYTHM)

The LiveView pushes updates every second (or at the form cycle resolution needed for smooth waveform animation). The 15-second epoch tick is sufficient for KEY, DRONE, and PHASE. FORM and RHYTHM need more frequent updates (1s or less) for smooth animation.

### SVG Rendering

All components are SVG. This matches the original generative page aesthetic and provides:
- Crisp rendering at any resolution
- Easy color manipulation via CSS/attributes
- Lightweight DOM footprint
- Good animation performance

### LiveView vs. Client-Side Animation

The server pushes the *data* (what the state is). The browser handles the *animation* (how the state transitions visually). For example:
- Server pushes: `form_cycle_progress: 0.73`
- Browser animates: the waveform cursor smoothly moving from 0.72 to 0.73

This keeps the server lightweight while allowing smooth client-side visuals. The animation uses CSS transitions and SVG animations, not JavaScript animation loops.

### Animation Frame Budget

The viz rack should not require a `requestAnimationFrame` loop. All animations are:
- CSS transitions (knob rotation, gauge fill, color changes)
- CSS keyframe animations (pulsing, dimming)
- SVG attribute updates driven by LiveView pushes

This keeps CPU usage minimal, especially important on mobile where SuperSonic is also running.

import {SuperSonic} from "supersonic-scsynth"

const SUPERSONIC_BASE_URL = "https://unpkg.com/supersonic-scsynth@0.66.0/dist/"
const SUPERSONIC_CORE_BASE_URL = "https://unpkg.com/supersonic-scsynth-core@0.66.0/"
const SYNTHDEF_BASE_URL = "https://unpkg.com/supersonic-scsynth-synthdefs@0.66.0/synthdefs/"
const MOTIF_SYNTH = "sonic-pi-beep"
const DRONE_SYNTH = "sonic-pi-prophet"
const UNIT_SECONDS = 0.25
const BAR_BEATS = 4
const SUPERSONIC_BOOT_TIMEOUT_MS = 8_000
const MAX_MELODIC_STEER_SEMITONES = 2
const SCHEDULER_TICK_MS = 200
const LOOKAHEAD_BARS = 1
const ARRIVAL_BARS = 2
const CURATED_GESTURE_POLICY = {
  silence_as_arrival: {motifMode: "mute", droneMode: "drop_then_land"},
  common_tone_drone_arrival: {motifMode: "sparse", droneMode: "common_tone"},
  suspended_arrival: {motifMode: "sparse", droneMode: "suspended"},
  modal_arrival: {motifMode: "normal", droneMode: "normal"},
  deceptive_arrival: {motifMode: "normal", droneMode: "normal"},
  rhythmic_drop_arrival: {motifMode: "drop", droneMode: "normal"},
  authentic_cadence: {motifMode: "normal", droneMode: "normal"}
}

const SuperSonicRuntime = {
  mounted() {
    this.audioContext = null
    this.runtime = null
    this.latestState = null
    this.schedulerTimer = null
    this.noteTimers = []
    this.isLooping = false
    this.scheduledBars = new Set()
    this.transportStartContextTime = null
    this.runtimeState = "waiting"
    this.statusMessage = "waiting for audio start"
    this.startButton = this.el.querySelector("#audio-start")
    this.status = this.el.querySelector("#audio-runtime-status")

    this.startButton?.addEventListener("click", () => this.play())

    this.handleEvent("composition_state", (state) => {
      this.latestState = state
      if (this.isLooping) {
        this.restartLoop()
      }
    })
  },

  updated() {
    this.startButton = this.el.querySelector("#audio-start")
    this.status = this.el.querySelector("#audio-runtime-status")
    this.syncButtonText()
    this.syncStatus()
  },

  async play() {
    if (this.isLooping) {
      this.stopLoop()
      return
    }

    if (!this.latestState?.motif) {
      this.setStatus("waiting for composition state", "waiting")
      return
    }

    if (!this.runtime) {
      await this.initialize()
    }

    this.startLoop()
  },

  async initialize() {
    this.setStatus("starting SuperSonic", "waiting")

    try {
      await this.ensureAudioContext()
      this.runtime = await this.createSuperSonicRuntime()
      this.setStatus("SuperSonic ready", "supersonic-ready")
    } catch (error) {
      console.warn("SuperSonic initialization failed; using AudioContext fallback", error)
      this.runtime = this.createFallbackRuntime()
      this.setStatus("fallback preview ready", "fallback")
    }
  },

  async ensureAudioContext() {
    if (!this.audioContext) {
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)()
    }

    await this.audioContext.resume()
  },

  async createSuperSonicRuntime() {
    const sonic = new SuperSonic({
      audioContext: this.audioContext,
      baseURL: SUPERSONIC_BASE_URL,
      coreBaseURL: SUPERSONIC_CORE_BASE_URL,
      mode: "postMessage",
      synthdefBaseURL: SYNTHDEF_BASE_URL,
      wasmBaseURL: `${SUPERSONIC_CORE_BASE_URL}wasm/`,
      workerBaseURL: `${SUPERSONIC_BASE_URL}workers/`,
      workletUrl: `${SUPERSONIC_CORE_BASE_URL}workers/scsynth_audio_worklet.js`
    })

    await this.withTimeout(sonic.init(), "SuperSonic init timed out")
    await this.withTimeout(
      Promise.all([sonic.loadSynthDef(MOTIF_SYNTH), sonic.loadSynthDef(DRONE_SYNTH)]),
      "SuperSonic synthdef load timed out"
    )

    const groupId = Math.floor(10_000 + Math.random() * 50_000)
    await sonic.send("/g_new", groupId, 0, 0)

    return {kind: "supersonic", sonic, groupId}
  },

  withTimeout(promise, message) {
    const timeout = new Promise((_, reject) => {
      setTimeout(() => reject(new Error(message)), SUPERSONIC_BOOT_TIMEOUT_MS)
    })

    return Promise.race([promise, timeout])
  },

  createFallbackRuntime() {
    return {kind: "fallback", audioContext: this.audioContext}
  },

  startLoop() {
    if (!this.latestState?.motif) {
      this.setStatus("waiting for composition state", "waiting")
      return
    }

    this.isLooping = true
    this.transportStartContextTime = this.audioContext.currentTime + 0.08
    this.scheduledBars.clear()
    this.syncButtonText()
    this.runSchedulerTick()
    this.schedulerTimer = setInterval(() => this.runSchedulerTick(), SCHEDULER_TICK_MS)
  },

  stopLoop() {
    this.isLooping = false
    this.clearScheduledTimers()
    this.freeSuperSonicGroup()
    this.syncButtonText()
    this.setStatus(`${this.runtimeLabel()} stopped`, this.runtimeStateForIdle())
  },

  restartLoop() {
    this.clearScheduledTimers()
    this.freeSuperSonicGroup()
    this.transportStartContextTime = this.audioContext.currentTime + 0.08
    this.scheduledBars.clear()
    this.runSchedulerTick()
  },

  runSchedulerTick() {
    if (!this.isLooping) {
      return
    }

    const state = this.latestState

    if (!state?.motif) {
      this.setStatus("waiting for composition state", "waiting")
      return
    }

    if (!this.runtime) {
      this.setStatus("runtime not ready", "failed")
      return
    }

    const currentBarIndex = this.transportBarIndex()
    const targetBarIndex = currentBarIndex + LOOKAHEAD_BARS

    for (let barIndex = currentBarIndex; barIndex <= targetBarIndex; barIndex++) {
      if (this.scheduledBars.has(barIndex)) continue

      if (this.runtime.kind === "supersonic") {
        this.scheduleSuperSonicBar(state, barIndex, currentBarIndex)
      } else {
        this.scheduleFallbackBar(state, barIndex, currentBarIndex)
      }

      this.scheduledBars.add(barIndex)
    }
  },

  scheduleSuperSonicBar(state, barIndex, currentBarIndex) {
    const transitionContext = this.transitionContextForBar(state, barIndex, currentBarIndex)
    const gesture = transitionContext.arrivalGesture
    const gestureText = transitionContext.arrivalWindow ? ` · gesture ${gesture}` : ""

    this.setStatus(`playing SuperSonic: ${state.motif.name} (continuous${gestureText})`, "playing")
    this.scheduleSuperSonicDroneBar(state, barIndex, currentBarIndex, transitionContext)
    this.scheduleSuperSonicMotifBar(state, barIndex, currentBarIndex, transitionContext)
  },

  scheduleSuperSonicMotifBar(state, barIndex, currentBarIndex, transitionContext) {
    const velocity = Math.max(0.16, Math.min(0.5, 0.18 + state.energy * 0.36))
    const barStartAt = this.barStartContextTime(barIndex)
    const motifEvents = this.applyGestureToMotifEvents(
      this.motifEventsForBar(state, barIndex, currentBarIndex),
      transitionContext
    )

    motifEvents.forEach((event) => {
      const timer = setTimeout(() => {
        if (!this.isLooping || this.runtime?.kind !== "supersonic") return

        this.sendSuperSonic(
          "/s_new",
          MOTIF_SYNTH,
          -1,
          1,
          this.runtime.groupId,
          "note",
          event.midi,
          "amp",
          velocity,
          "sustain",
          Math.max(0.03, event.duration * 0.7),
          "release",
          Math.min(0.18, event.duration * 0.45)
        )
      }, this.delayUntilContext(barStartAt + event.offset))

      this.noteTimers.push(timer)
    })
  },

  scheduleSuperSonicDroneBar(state, barIndex, currentBarIndex, transitionContext) {
    const barDuration = this.barDurationSeconds()
    const amp = Math.max(0.05, Math.min(0.18, 0.06 + state.density * 0.12))
    const barStartAt = this.barStartContextTime(barIndex)
    const notes = this.applyGestureToDroneNotes(
      this.droneNotesForBar(state, barIndex, currentBarIndex),
      state,
      transitionContext
    )

    if (notes.length === 0) return

    const timer = setTimeout(() => {
      if (!this.isLooping || this.runtime?.kind !== "supersonic") return

      notes.forEach((midi) => {
        this.sendSuperSonic(
          "/s_new",
          DRONE_SYNTH,
          -1,
          1,
          this.runtime.groupId,
          "note",
          midi,
          "amp",
          amp,
          "sustain",
          barDuration * 0.9,
          "release",
          Math.max(0.4, barDuration * 0.12)
        )
      })
    }, this.delayUntilContext(barStartAt))

    this.noteTimers.push(timer)
  },

  scheduleFallbackBar(state, barIndex, currentBarIndex) {
    const transitionContext = this.transitionContextForBar(state, barIndex, currentBarIndex)
    const gesture = transitionContext.arrivalGesture
    const gestureText = transitionContext.arrivalWindow ? ` · gesture ${gesture}` : ""
    this.setStatus(`playing fallback preview: ${state.motif.name} (continuous${gestureText})`, "playing")

    const context = this.runtime.audioContext
    const velocity = Math.max(0.18, Math.min(0.55, 0.25 + state.energy * 0.4))
    const barStartAt = this.barStartContextTime(barIndex)
    const barDuration = this.barDurationSeconds()

    this.applyGestureToDroneNotes(
      this.droneNotesForBar(state, barIndex, currentBarIndex),
      state,
      transitionContext
    ).forEach((midi) => {
      this.playFallbackTone(
        context,
        this.midiToFrequency(midi),
        barStartAt,
        barDuration,
        Math.max(0.035, Math.min(0.12, 0.04 + state.density * 0.1)),
        "sine"
      )
    })

    this.applyGestureToMotifEvents(
      this.motifEventsForBar(state, barIndex, currentBarIndex),
      transitionContext
    ).forEach((event) => {
      this.playFallbackTone(
        context,
        this.midiToFrequency(event.midi),
        barStartAt + event.offset,
        event.duration,
        velocity
      )
    })
  },

  playFallbackTone(context, frequency, startAt, duration, velocity, type = "triangle") {
    const oscillator = context.createOscillator()
    const gain = context.createGain()

    oscillator.type = type
    oscillator.frequency.setValueAtTime(frequency, startAt)
    gain.gain.setValueAtTime(0.0001, startAt)
    gain.gain.exponentialRampToValueAtTime(velocity, startAt + 0.02)
    gain.gain.exponentialRampToValueAtTime(0.0001, startAt + duration)

    oscillator.connect(gain)
    gain.connect(context.destination)
    oscillator.start(startAt)
    oscillator.stop(startAt + duration + 0.02)
  },

  motifEventsForBar(state, barIndex, currentBarIndex) {
    const events = []
    const barStartBeat = barIndex * BAR_BEATS
    const barEndBeat = barStartBeat + BAR_BEATS
    const motifPattern = this.motifPatternEvents(state)
    const motifBeats = this.motifPatternBeats(state)

    if (motifPattern.length === 0 || motifBeats <= 0) {
      return events
    }

    let cycle = Math.max(0, Math.floor(barStartBeat / motifBeats) - 1)

    while (cycle * motifBeats < barEndBeat + motifBeats) {
      const cycleOffset = cycle * motifBeats

      motifPattern.forEach((patternEvent) => {
        const onsetBeat = cycleOffset + patternEvent.onsetBeat
        if (onsetBeat < barStartBeat || onsetBeat >= barEndBeat) return

        events.push({
          offset: (onsetBeat - barStartBeat) * UNIT_SECONDS,
          duration: patternEvent.durationBeat * UNIT_SECONDS,
          midi: patternEvent.midi,
          barOffset: barIndex - currentBarIndex
        })
      })

      cycle += 1
    }

    return this.steerMotifEvents(events, state)
  },

  transitionContextForBar(state, barIndex, currentBarIndex) {
    const transition = state?.transition_plan
    const active = Boolean(transition?.active)
    const durationBars = Math.max(1, transition?.duration_bars || 1)
    const planBar = Math.max(1, (transition?.current_bar || 1) + (barIndex - currentBarIndex))
    const clampedPlanBar = Math.min(planBar, durationBars)
    const arrivalWindow = active && clampedPlanBar >= Math.max(1, durationBars - ARRIVAL_BARS + 1)
    const arrivalGesture = transition?.arrival_gesture || "modal_arrival"

    return {active, durationBars, planBar: clampedPlanBar, arrivalWindow, arrivalGesture}
  },

  applyGestureToMotifEvents(events, transitionContext) {
    if (!transitionContext.arrivalWindow) return events
    const policy = CURATED_GESTURE_POLICY[transitionContext.arrivalGesture] || CURATED_GESTURE_POLICY.modal_arrival

    switch (policy.motifMode) {
      case "mute":
        return []
      case "drop":
        return events.filter((_, index) => index % 2 === 0)
      case "sparse":
        return events.filter((event, index) => index % 2 === 0 || event.offset === 0)
      default:
        return events
    }
  },

  applyGestureToDroneNotes(notes, state, transitionContext) {
    if (!transitionContext.arrivalWindow) return notes
    const policy = CURATED_GESTURE_POLICY[transitionContext.arrivalGesture] || CURATED_GESTURE_POLICY.modal_arrival

    switch (policy.droneMode) {
      case "drop_then_land":
        return transitionContext.planBar === transitionContext.durationBars ? this.rootFifthLanding(state) : []
      case "common_tone":
        return this.commonToneNotes(notes, state)
      case "suspended":
        return this.suspendedNotes(state)
      default:
        return notes
    }
  },

  rootFifthLanding(state) {
    const root = 36 + (state.root || 0)
    return [root, root + 7]
  },

  commonToneNotes(notes, state) {
    const sourcePitches = state?.transition_plan?.source?.pitch_classes || []
    const destinationPitches = state?.transition_plan?.destination?.pitch_classes || []
    const shared = sourcePitches.filter((pitch) => destinationPitches.includes(pitch))
    const filtered = notes.filter((note) => shared.includes(Integer.mod(note, 12)))
    return filtered.length > 0 ? filtered : notes
  },

  suspendedNotes(state) {
    const root = 36 + (state.root || 0)
    return [root, root + 5, root + 7]
  },

  motifPatternEvents(state) {
    const events = []
    const degrees = state?.motif?.degrees || []
    const rhythm = state?.motif?.rhythm || []
    let offsetBeat = 0

    for (let index = 0; index < degrees.length; index++) {
      const durationBeat = Math.max(0.25, rhythm[index] || 1)
      events.push({
        onsetBeat: offsetBeat,
        durationBeat,
        midi: this.motifDegreeToMidi(state, degrees[index])
      })
      offsetBeat += durationBeat
    }

    return events
  },

  steerMotifEvents(events, state) {
    const transition = state?.transition_plan
    const melodicPath = transition?.melodic_path || []

    if (!transition?.active || melodicPath.length === 0) {
      return events
    }

    return events.map((event) => {
      const target = this.melodicTargetPitchClass(event, state, transition, melodicPath)
      const steeredMidi = this.steerMidiTowardPitchClass(event.midi, target, MAX_MELODIC_STEER_SEMITONES)
      return {...event, midi: steeredMidi}
    })
  },

  melodicTargetPitchClass(event, state, transition, melodicPath) {
    const durationBars = Math.max(1, transition.duration_bars || 1)
    const progressBar = Math.min(durationBars, Math.max(1, (transition.current_bar || 1) + event.barOffset))
    const pathIndex = Math.min(
      melodicPath.length - 1,
      Math.floor(((progressBar - 1) * melodicPath.length) / durationBars)
    )
    const target = melodicPath[pathIndex]

    return Number.isInteger(target?.target_pitch_class)
      ? target.target_pitch_class
      : Integer.mod(state.root || 0, 12)
  },

  steerMidiTowardPitchClass(sourceMidi, targetPitchClass, maxShift) {
    const candidates = [-12, 0, 12].map((octave) => targetPitchClass + octave)
    const nearest = candidates.reduce((best, candidate) => {
      return Math.abs(sourceMidi - candidate) < Math.abs(sourceMidi - best) ? candidate : best
    }, candidates[0])

    const delta = nearest - sourceMidi
    const clamped = Math.max(-maxShift, Math.min(maxShift, delta))
    return sourceMidi + clamped
  },

  motifDegreeToMidi(state, degree) {
    return 48 + (state.root || 0) + degree + ((state.motif?.octave || 0) * 12)
  },

  chordMidiNotes(state) {
    return this.chordDegrees(state.chord_shape)
      .map((degree) => 36 + (state.root || 0) + this.scaleDegreeOffset(state, degree))
      .map((midi) => (midi < 38 ? midi + 12 : midi))
  },

  droneNotesForBar(state, barIndex, currentBarIndex) {
    const transition = state?.transition_plan
    const harmonicPath = transition?.harmonic_path || []
    const voicedPath = harmonicPath.filter((waypoint) => Array.isArray(waypoint?.voicing?.notes))

    if (!transition?.active || voicedPath.length === 0) {
      return this.chordMidiNotes(state)
    }

    const planBar = Math.max(1, (transition.current_bar || 1) + (barIndex - currentBarIndex))
    const clampedBar = Math.min(planBar, voicedPath.length)
    const waypoint = voicedPath[Math.max(0, clampedBar - 1)] || voicedPath[voicedPath.length - 1]
    return waypoint.voicing.notes
  },

  chordDegrees(chordShape) {
    switch (chordShape) {
      case "cluster":
        return [0, 1, 2, 3]
      case "open_fifth":
        return [0, 4]
      case "sixth":
        return [0, 2, 4, 5]
      case "seventh":
        return [0, 2, 4, 6]
      case "suspended":
        return [0, 3, 4]
      case "triad":
      default:
        return [0, 2, 4]
    }
  },

  scaleDegreeOffset(state, degree) {
    const intervals = state.scale_intervals || [0, 2, 4, 5, 7, 9, 11]
    const length = intervals.length
    const index = ((degree % length) + length) % length
    const octave = Math.floor(degree / length)

    return intervals[index] + octave * 12
  },

  motifPatternBeats(state) {
    return (state?.motif?.rhythm || []).reduce((sum, value) => sum + value, 0)
  },

  barDurationSeconds() {
    return BAR_BEATS * UNIT_SECONDS
  },

  transportBarIndex() {
    const elapsedSeconds = Math.max(0, this.audioContext.currentTime - this.transportStartContextTime)
    return Math.floor(elapsedSeconds / this.barDurationSeconds())
  },

  barStartContextTime(barIndex) {
    return this.transportStartContextTime + barIndex * this.barDurationSeconds()
  },

  delayUntilContext(targetContextTime) {
    return Math.max(0, Math.round((targetContextTime - this.audioContext.currentTime) * 1000))
  },

  midiToFrequency(midi) {
    return 440 * Math.pow(2, (midi - 69) / 12)
  },

  clearScheduledTimers() {
    clearInterval(this.schedulerTimer)
    this.schedulerTimer = null
    this.noteTimers.forEach((timer) => clearTimeout(timer))
    this.noteTimers = []
    this.scheduledBars.clear()
  },

  freeSuperSonicGroup() {
    if (this.runtime?.kind === "supersonic") {
      this.sendSuperSonic("/g_freeAll", this.runtime.groupId)
    }
  },

  sendSuperSonic(address, ...args) {
    try {
      this.runtime.sonic.send(address, ...args)
    } catch (error) {
      console.warn(`SuperSonic send failed for ${address}`, error)
      this.setStatus("SuperSonic send failed; stop and restart audio", "failed")
    }
  },

  runtimeLabel() {
    if (this.runtime?.kind === "supersonic") return "SuperSonic"
    if (this.runtime?.kind === "fallback") return "fallback preview"
    return "audio"
  },

  runtimeStateForIdle() {
    if (this.runtime?.kind === "supersonic") return "supersonic-ready"
    if (this.runtime?.kind === "fallback") return "fallback"
    return "waiting"
  },

  setStatus(status, runtimeState = this.runtimeState) {
    this.runtimeState = runtimeState
    this.statusMessage = status
    this.syncStatus()
  },

  syncStatus() {
    if (this.status) {
      this.status.textContent = `Status: ${this.statusMessage}`
    }
  },

  syncButtonText() {
    if (this.startButton) {
      this.startButton.textContent = this.isLooping ? "Stop 4-Bar Audio Loop" : "Start 4-Bar Audio Loop"
    }
  }
}

export default SuperSonicRuntime

import {SuperSonic} from "supersonic-scsynth"

const SUPERSONIC_BASE_URL = "https://unpkg.com/supersonic-scsynth@0.66.0/dist/"
const SUPERSONIC_CORE_BASE_URL = "https://unpkg.com/supersonic-scsynth-core@0.66.0/"
const SYNTHDEF_BASE_URL = "https://unpkg.com/supersonic-scsynth-synthdefs@0.66.0/synthdefs/"
const MOTIF_SYNTH = "sonic-pi-beep"
const DRONE_SYNTH = "sonic-pi-prophet"
const UNIT_SECONDS = 0.25
const FOUR_BAR_BEATS = 16
const SUPERSONIC_BOOT_TIMEOUT_MS = 8_000

const SuperSonicRuntime = {
  mounted() {
    this.audioContext = null
    this.runtime = null
    this.latestState = null
    this.loopTimer = null
    this.noteTimers = []
    this.isLooping = false
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
    this.syncButtonText()
    this.scheduleLoopIteration()
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
    this.scheduleLoopIteration()
  },

  scheduleLoopIteration() {
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

    if (this.runtime.kind === "supersonic") {
      this.scheduleSuperSonicLoop(state)
    } else {
      this.scheduleFallbackLoop(state)
    }

    this.loopTimer = setTimeout(() => this.scheduleLoopIteration(), this.loopDurationMs(state))
  },

  scheduleSuperSonicLoop(state) {
    this.setStatus(`playing SuperSonic: ${state.motif.name}`, "playing")
    this.scheduleSuperSonicDrone(state)
    this.scheduleSuperSonicMotif(state)
  },

  scheduleSuperSonicMotif(state) {
    const velocity = Math.max(0.16, Math.min(0.5, 0.18 + state.energy * 0.36))

    this.motifEvents(state).forEach((event) => {
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
      }, event.offset * 1000)

      this.noteTimers.push(timer)
    })
  },

  scheduleSuperSonicDrone(state) {
    const loopSeconds = this.loopDurationMs(state) / 1000
    const amp = Math.max(0.05, Math.min(0.18, 0.06 + state.density * 0.12))

    this.droneEvents(state).forEach((event) => {
      const timer = setTimeout(() => {
        if (!this.isLooping || this.runtime?.kind !== "supersonic") return

        event.notes.forEach((midi) => {
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
            event.duration * 0.9,
            "release",
            Math.max(0.4, event.duration * 0.12)
          )
        })
      }, event.offset * 1000)

      this.noteTimers.push(timer)
    })
  },

  scheduleFallbackLoop(state) {
    this.setStatus(`playing fallback preview: ${state.motif.name}`, "playing")

    const context = this.runtime.audioContext
    const startAt = context.currentTime + 0.08
    const velocity = Math.max(0.18, Math.min(0.55, 0.25 + state.energy * 0.4))

    this.scheduleFallbackDrone(context, state, startAt)

    this.motifEvents(state).forEach((event) => {
      this.playFallbackTone(
        context,
        this.midiToFrequency(event.midi),
        startAt + event.offset,
        event.duration,
        velocity
      )
    })
  },

  scheduleFallbackDrone(context, state, startAt) {
    const velocity = Math.max(0.035, Math.min(0.12, 0.04 + state.density * 0.1))

    this.droneEvents(state).forEach((event) => {
      event.notes.forEach((midi) => {
        this.playFallbackTone(
          context,
          this.midiToFrequency(midi),
          startAt + event.offset,
          event.duration,
          velocity,
          "sine"
        )
      })
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

  motifEvents(state) {
    const events = []
    const loopSeconds = this.loopDurationMs(state) / 1000
    const degrees = state?.motif?.degrees || []
    const rhythm = state?.motif?.rhythm || []
    let offset = 0

    while (offset < loopSeconds - 0.001 && degrees.length > 0) {
      for (let index = 0; index < degrees.length && offset < loopSeconds - 0.001; index++) {
        const duration = Math.min(
          Math.max(0.05, (rhythm[index] || 1) * UNIT_SECONDS),
          loopSeconds - offset
        )

        events.push({
          offset,
          duration,
          midi: this.motifDegreeToMidi(state, degrees[index])
        })

        offset += duration
      }
    }

    return events
  },

  motifDegreeToMidi(state, degree) {
    return 48 + (state.root || 0) + degree + ((state.motif?.octave || 0) * 12)
  },

  chordMidiNotes(state) {
    return this.chordDegrees(state.chord_shape)
      .map((degree) => 36 + (state.root || 0) + this.scaleDegreeOffset(state, degree))
      .map((midi) => (midi < 38 ? midi + 12 : midi))
  },

  droneEvents(state) {
    const transition = state?.transition_plan
    const harmonicPath = transition?.harmonic_path || []
    const voicedPath = harmonicPath.filter((waypoint) => Array.isArray(waypoint?.voicing?.notes))

    if (!transition?.active || voicedPath.length === 0) {
      return [{offset: 0, duration: this.loopDurationMs(state) / 1000, notes: this.chordMidiNotes(state)}]
    }

    const loopSeconds = this.loopDurationMs(state) / 1000
    const barsPerLoop = 4
    const barSeconds = loopSeconds / barsPerLoop
    const startBar = Math.max(1, transition.current_bar || 1)

    return Array.from({length: barsPerLoop}, (_value, index) => {
      const bar = Math.min(startBar + index, voicedPath.length)
      const waypoint = voicedPath[Math.max(0, bar - 1)] || voicedPath[voicedPath.length - 1]

      return {
        offset: index * barSeconds,
        duration: barSeconds,
        notes: waypoint.voicing.notes
      }
    })
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

  loopDurationMs(state) {
    const motifBeats = (state?.motif?.rhythm || []).reduce((sum, value) => sum + value, 0)
    const motifMs = Math.max(1, motifBeats * UNIT_SECONDS * 1000)
    const fourBarsMs = FOUR_BAR_BEATS * UNIT_SECONDS * 1000

    return Math.max(fourBarsMs, Math.ceil(fourBarsMs / motifMs) * motifMs)
  },

  midiToFrequency(midi) {
    return 440 * Math.pow(2, (midi - 69) / 12)
  },

  clearScheduledTimers() {
    clearTimeout(this.loopTimer)
    this.loopTimer = null
    this.noteTimers.forEach((timer) => clearTimeout(timer))
    this.noteTimers = []
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

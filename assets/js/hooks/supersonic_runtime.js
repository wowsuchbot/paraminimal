const SuperSonicRuntime = {
  mounted() {
    this.audioContext = null
    this.sonic = null
    this.latestState = null
    this.lastScheduledEpochId = null
    this.loopTimer = null
    this.isLooping = false
    this.startButton = this.el.querySelector("#audio-start")
    this.status = this.el.querySelector("#audio-runtime-status")

    this.startButton?.addEventListener("click", () => this.play())

    this.handleEvent("composition_state", (state) => {
      this.latestState = state
      this.scheduleState(state)
    })
  },

  async play() {
    if (this.sonic) {
      if (this.isLooping) {
        this.stopLoop()
      } else {
        this.startLoop()
      }

      return
    }

    await this.initialize()
  },

  async initialize() {
    this.setStatus("starting")

    try {
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)()
      await this.audioContext.resume()
      this.sonic = await this.createRuntime()
      this.setStatus(this.sonic.kind === "supersonic" ? "SuperSonic runtime ready" : "preview loop ready")
      this.startLoop()
    } catch (error) {
      console.error("Audio runtime initialization failed", error)
      this.setStatus("failed")
    }
  },

  async createRuntime() {
    if (window.SuperSonic) {
      const sonic = new window.SuperSonic()
      await sonic.start?.()
      return {kind: "supersonic", sonic}
    }

    return {kind: "fallback", audioContext: this.audioContext}
  },

  scheduleState(state, force = false) {
    if (!this.sonic) {
      return
    }

    // Future work: translate server-computed state into OSC messages for
    // SuperSonic, e.g. /s_new, /n_set, and scheduled note/control events.
    console.debug("composition_state received for audio scheduling", state)

    if (this.sonic.kind === "fallback") {
      this.scheduleFallbackMotif(state, force)
    }
  },

  scheduleFallbackMotif(state, force = false) {
    if (!state?.motif || (!force && this.lastScheduledEpochId === state.epoch_id)) {
      if (!state?.motif) this.setStatus("waiting for composition state")
      return
    }

    this.lastScheduledEpochId = state.epoch_id
    this.setStatus(`looping ${state.motif.name}`)

    const context = this.sonic.audioContext
    const startAt = context.currentTime + 0.1
    const unitSeconds = 0.25
    const velocity = Math.max(0.18, Math.min(0.55, 0.25 + state.energy * 0.4))

    state.motif.degrees.reduce((offset, degree, index) => {
      const duration = Math.max(0.05, (state.motif.rhythm[index] || 1) * unitSeconds)
      this.playFallbackTone(context, this.degreeToFrequency(state, degree), startAt + offset, duration, velocity)
      return offset + duration
    }, 0)
  },

  startLoop() {
    if (!this.latestState?.motif) {
      this.setStatus("waiting for composition state")
      return
    }

    this.isLooping = true
    this.setButtonText("Stop Preview Loop")
    this.setStatus(`looping ${this.latestState.motif.name}`)
    this.scheduleLoopIteration()
  },

  stopLoop() {
    this.isLooping = false
    this.lastScheduledEpochId = null
    clearTimeout(this.loopTimer)
    this.loopTimer = null
    this.setButtonText("Start / Play Current Motif")
    this.setStatus("preview stopped")
  },

  scheduleLoopIteration() {
    if (!this.isLooping) {
      return
    }

    this.scheduleFallbackMotif(this.latestState, true)
    this.loopTimer = setTimeout(() => this.scheduleLoopIteration(), this.loopDurationMs(this.latestState))
  },

  loopDurationMs(state) {
    const unitSeconds = 0.25
    const motifBeats = (state?.motif?.rhythm || []).reduce((sum, value) => sum + value, 0)
    const motifMs = Math.max(1, motifBeats * unitSeconds * 1000)
    const fourBarsMs = 16 * unitSeconds * 1000

    return Math.max(fourBarsMs, Math.ceil(fourBarsMs / motifMs) * motifMs)
  },

  playFallbackTone(context, frequency, startAt, duration, velocity) {
    const oscillator = context.createOscillator()
    const gain = context.createGain()

    oscillator.type = "triangle"
    oscillator.frequency.setValueAtTime(frequency, startAt)
    gain.gain.setValueAtTime(0.0001, startAt)
    gain.gain.exponentialRampToValueAtTime(velocity, startAt + 0.02)
    gain.gain.exponentialRampToValueAtTime(0.0001, startAt + duration)

    oscillator.connect(gain)
    gain.connect(context.destination)
    oscillator.start(startAt)
    oscillator.stop(startAt + duration + 0.02)
  },

  degreeToFrequency(state, degree) {
    const midi = 48 + state.root + degree + ((state.motif.octave || 0) * 12)
    return 440 * Math.pow(2, (midi - 69) / 12)
  },

  setStatus(status) {
    if (this.status) {
      this.status.textContent = `Status: ${status}`
    }
  },

  setButtonText(text) {
    if (this.startButton) {
      this.startButton.textContent = text
    }
  }
}

export default SuperSonicRuntime

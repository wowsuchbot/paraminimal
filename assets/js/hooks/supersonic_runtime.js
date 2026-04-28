const SuperSonicRuntime = {
  mounted() {
    this.audioContext = null
    this.sonic = null
    this.startButton = this.el.querySelector("#audio-start")
    this.status = this.el.querySelector("#audio-runtime-status")

    this.startButton?.addEventListener("click", () => this.initialize())

    this.handleEvent("composition_state", (state) => {
      this.scheduleState(state)
    })
  },

  async initialize() {
    this.setStatus("starting")

    try {
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)()
      await this.audioContext.resume()
      this.sonic = await this.createRuntime()
      this.setStatus(this.sonic.kind === "supersonic" ? "SuperSonic ready" : "AudioContext fallback ready")
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

  scheduleState(state) {
    if (!this.sonic) {
      return
    }

    // Future work: translate server-computed state into OSC messages for
    // SuperSonic, e.g. /s_new, /n_set, and scheduled note/control events.
    console.debug("composition_state received for audio scheduling", state)
  },

  setStatus(status) {
    if (this.status) {
      this.status.textContent = `Status: ${status}`
    }
  }
}

export default SuperSonicRuntime

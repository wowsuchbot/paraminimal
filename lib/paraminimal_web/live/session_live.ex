defmodule ParaminimalWeb.SessionLive do
  use ParaminimalWeb, :live_view

  alias Paraminimal.Composition.Epoch
  alias Paraminimal.Composition.Scale

  @tick_ms 15_000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: schedule_tick()

    socket =
      socket
      |> assign(:audio_status, "waiting")
      |> assign_epoch(Epoch.current())

    {:ok, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    schedule_tick()

    epoch = Epoch.current()

    socket =
      socket
      |> assign_epoch(epoch)
      |> push_event("composition_state", audio_state(epoch))

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="min-h-screen bg-zinc-950 text-zinc-100">
      <section class="mx-auto flex min-h-screen w-full max-w-6xl flex-col gap-10 px-6 py-10">
        <div class="flex flex-col gap-4">
          <p class="text-sm uppercase tracking-[0.4em] text-cyan-300">Paraminimal</p>
          <div class="grid gap-8 lg:grid-cols-[1.2fr_0.8fr]">
            <div>
              <h1 class="text-4xl font-semibold tracking-tight text-white md:text-6xl">
                Deterministic, time-synchronized, endless.
              </h1>
              <p class="mt-5 max-w-2xl text-lg leading-8 text-zinc-300">
                Current: {@epoch.period.name} · {@epoch.scale.name} · {root_label(@epoch)} · density {@epoch.density} · energy {@epoch.energy}
              </p>
              <p class="mt-3 text-sm text-zinc-500">
                UTC epoch {@epoch.id} · next: {@epoch.next_period.name} · transition zone: {format_zone(
                  @epoch.transition.zone
                )}
              </p>
            </div>

            <div
              id="supersonic-runtime"
              phx-hook="SuperSonicRuntime"
              data-audio-status={@audio_status}
              class="rounded-2xl border border-cyan-400/30 bg-cyan-400/10 p-5 shadow-2xl shadow-cyan-950/40"
            >
              <p class="text-xs uppercase tracking-[0.3em] text-cyan-200">Audio Runtime</p>
              <h2 class="mt-3 text-2xl font-semibold text-white">SuperSonic boundary ready</h2>
              <p class="mt-3 text-sm leading-6 text-cyan-50/80">
                Browser audio must start from a user gesture. This button initializes the client
                runtime boundary that will schedule OSC messages for SuperSonic.
              </p>
              <button
                id="audio-start"
                type="button"
                class="mt-5 rounded-full bg-cyan-300 px-5 py-2 text-sm font-semibold text-zinc-950 transition hover:bg-cyan-200"
              >
                Start Audio Runtime
              </button>
              <p id="audio-runtime-status" class="mt-4 text-sm text-cyan-100">Status: waiting</p>
            </div>
          </div>
        </div>

        <section class="grid gap-6 lg:grid-cols-[0.8fr_1.2fr]">
          <div class="rounded-2xl border border-zinc-800 bg-zinc-900/80 p-6">
            <p class="text-xs uppercase tracking-[0.3em] text-zinc-500">Current UTC Epoch</p>
            <h2 class="mt-3 text-3xl font-semibold text-white">{@current_scale.name}</h2>
            <p class="mt-2 text-sm text-zinc-400">
              Pitch classes: {@current_scale |> Scale.pitch_classes() |> format_pitch_classes()}
            </p>

            <div class="mt-6 grid grid-cols-2 gap-3 text-sm">
              <.metric label="Period" value={@epoch.period.name} />
              <.metric label="Root" value={root_label(@epoch)} />
              <.metric label="Energy" value={@epoch.energy} />
              <.metric label="Density" value={@epoch.density} />
              <.metric label="Chord" value={format_atom(@epoch.chord_shape)} />
              <.metric label="Transition" value={transition_label(@epoch.transition)} />
              <.metric label="Tags" value={format_atoms(@current_scale.character_tags)} />
              <.metric label="Periods" value={format_atoms(@current_scale.period_affinity)} />
            </div>
          </div>

          <div class="rounded-2xl border border-zinc-800 bg-zinc-900/80 p-6">
            <p class="text-xs uppercase tracking-[0.3em] text-zinc-500">Adjacent Relationships</p>
            <div class="mt-5 grid gap-4">
              <div
                :for={distance <- @distances}
                class="rounded-xl border border-zinc-800 bg-zinc-950/70 p-4"
              >
                <div class="flex flex-col gap-2 md:flex-row md:items-start md:justify-between">
                  <div>
                    <h3 class="text-lg font-semibold text-white">{distance.from} → {distance.to}</h3>
                    <p class="mt-1 text-sm text-zinc-400">
                      Strategy: {format_atoms(distance.recommended_strategies)}
                    </p>
                  </div>
                  <p class="rounded-full bg-zinc-800 px-3 py-1 text-xs text-zinc-300">
                    shared {distance.shared_tones} / ratio {distance.shared_ratio}
                  </p>
                </div>

                <div class="mt-4 grid grid-cols-3 gap-3 text-sm">
                  <.metric label="Fifths" value={distance.circle_fifths_distance} />
                  <.metric label="Voice Cost" value={distance.voice_leading_cost} />
                  <.metric label="Vector" value={distance.interval_vector_similarity} />
                </div>
              </div>
            </div>
          </div>
        </section>
      </section>
    </main>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true

  defp metric(assigns) do
    ~H"""
    <div class="rounded-lg bg-zinc-950/80 p-3">
      <p class="text-xs uppercase tracking-[0.2em] text-zinc-500">{@label}</p>
      <p class="mt-2 break-words text-zinc-100">{@value}</p>
    </div>
    """
  end

  defp format_pitch_classes(pitch_classes) do
    pitch_classes
    |> Enum.map(&Scale.note_name/1)
    |> Enum.join(" ")
  end

  defp assign_epoch(socket, epoch) do
    socket
    |> assign(:epoch, epoch)
    |> assign(:current_scale, epoch.scale)
    |> assign(:distances, epoch.distances)
  end

  defp schedule_tick, do: Process.send_after(self(), :tick, @tick_ms)

  defp audio_state(epoch) do
    %{
      epoch_id: epoch.id,
      period: epoch.period.key,
      scale: epoch.scale.slug,
      root: epoch.root,
      energy: epoch.energy,
      density: epoch.density,
      transition_zone: epoch.transition.zone,
      transition_progress: epoch.transition.progress
    }
  end

  defp root_label(epoch), do: "#{epoch.root_name}3"

  defp transition_label(%{zone: :core}), do: "core"

  defp transition_label(%{
         next_period: next_period,
         minutes_to_boundary: minutes,
         progress: progress
       }) do
    "#{minutes}m to #{next_period.name} · #{progress}"
  end

  defp format_zone(zone), do: format_atom(zone)

  defp format_atom(atom), do: atom |> Atom.to_string() |> String.replace("_", " ")

  defp format_atoms(atoms) do
    atoms
    |> Enum.map(&format_atom/1)
    |> Enum.join(", ")
  end
end

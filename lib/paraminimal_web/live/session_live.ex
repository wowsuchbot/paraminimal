defmodule ParaminimalWeb.SessionLive do
  use ParaminimalWeb, :live_view

  alias Paraminimal.Composition.Epoch
  alias Paraminimal.Composition.Scale

  @tick_ms 15_000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: send(self(), :tick)

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
      <section class="mx-auto flex min-h-screen w-full max-w-screen-2xl flex-col gap-8 px-4 py-6 sm:px-6 lg:px-8 xl:px-10">
        <div class="rounded-3xl border border-zinc-800 bg-zinc-900/50 p-5 shadow-2xl shadow-black/30 sm:p-6 lg:p-8">
          <p class="text-sm uppercase tracking-[0.4em] text-cyan-300">Paraminimal</p>
          <div class="mt-5 grid items-stretch gap-6 xl:grid-cols-[minmax(0,1.35fr)_minmax(300px,0.85fr)_minmax(300px,0.85fr)]">
            <div class="min-w-0 xl:col-span-1">
              <h1 class="max-w-5xl text-4xl font-semibold tracking-tight text-white md:text-6xl xl:text-7xl">
                Deterministic, time-synchronized, endless.
              </h1>
              <p class="mt-5 max-w-4xl text-lg leading-8 text-zinc-300">
                Current: {@epoch.period.name} · {@epoch.scale.name} · {root_label(@epoch)} · density {@epoch.density} · energy {@epoch.energy}
              </p>
              <p class="mt-3 max-w-4xl text-sm leading-6 text-zinc-500">
                UTC epoch {@epoch.id} · next: {@epoch.next_period.name} · transition zone: {format_zone(
                  @epoch.transition.zone
                )}
              </p>
              <p class="mt-3 max-w-4xl text-sm leading-6 text-zinc-400">
                Motif: {@epoch.motif.name} · {format_transformations(
                  @epoch.transformed_motif.transformations
                )}
              </p>
            </div>

            <div
              id="supersonic-runtime"
              phx-hook="SuperSonicRuntime"
              data-audio-status={@audio_status}
              class="min-w-0 rounded-2xl border border-cyan-400/30 bg-cyan-400/10 p-5 shadow-2xl shadow-cyan-950/40"
            >
              <p class="text-xs uppercase tracking-[0.3em] text-cyan-200">Audio Runtime</p>
              <h2 class="mt-3 text-2xl font-semibold text-white">SuperSonic audio</h2>
              <p class="mt-3 text-sm leading-6 text-cyan-50/80">
                Starts a four-bar loop from the current epoch. It tries SuperSonic in compatible
                postMessage mode first, then falls back to a simple browser preview if needed.
              </p>
              <button
                id="audio-start"
                type="button"
                class="mt-5 inline-flex max-w-full items-center justify-center rounded-full bg-cyan-300 px-5 py-2 text-center text-sm font-semibold text-zinc-950 transition hover:bg-cyan-200"
              >
                Start 4-Bar Audio Loop
              </button>
              <p id="audio-runtime-status" class="mt-4 text-sm text-cyan-100">
                Status: waiting for audio start
              </p>
            </div>

            <aside class="min-w-0 rounded-2xl border border-zinc-700/70 bg-zinc-950/70 p-5">
              <p class="text-xs uppercase tracking-[0.3em] text-zinc-500">About</p>
              <h2 class="mt-3 text-2xl font-semibold text-white">A living formal system.</h2>
              <p class="mt-3 text-sm leading-6 text-zinc-300">
                A continuous piece shaped by time first, and later by other signals still to be
                discovered. It should keep changing on its own while many people can listen to the
                same moment together.
              </p>
            </aside>
          </div>
        </div>

        <section class="grid gap-6 xl:grid-cols-[minmax(420px,0.85fr)_minmax(0,1.4fr)]">
          <div class="min-w-0 rounded-2xl border border-zinc-800 bg-zinc-900/80 p-5 sm:p-6">
            <p class="text-xs uppercase tracking-[0.3em] text-zinc-500">Current UTC Epoch</p>
            <h2 class="mt-3 text-3xl font-semibold text-white">{@current_scale.name}</h2>
            <p class="mt-2 text-sm text-zinc-400">
              Pitch classes: {@current_scale |> Scale.pitch_classes() |> format_pitch_classes()}
            </p>

            <div class="mt-6 grid grid-cols-1 gap-3 text-sm sm:grid-cols-2 xl:grid-cols-1 2xl:grid-cols-2">
              <.metric label="Period" value={@epoch.period.name} />
              <.metric label="Root" value={root_label(@epoch)} />
              <.metric label="Energy" value={@epoch.energy} />
              <.metric label="Density" value={@epoch.density} />
              <.metric label="Chord" value={format_atom(@epoch.chord_shape)} />
              <.metric label="Transition" value={transition_label(@epoch.transition)} />
              <.metric label="Transition Plan" value={format_transition_plan(@epoch.transition_plan)} />
              <.metric label="Motif" value={@epoch.motif.name} />
              <.metric
                label="Transform"
                value={format_transformations(@epoch.transformed_motif.transformations)}
              />
              <.metric label="Tags" value={format_atoms(@current_scale.character_tags)} />
              <.metric label="Periods" value={format_atoms(@current_scale.period_affinity)} />
            </div>
          </div>

          <div class="min-w-0 rounded-2xl border border-zinc-800 bg-zinc-900/80 p-5 sm:p-6">
            <p class="text-xs uppercase tracking-[0.3em] text-zinc-500">Adjacent Relationships</p>
            <div class="mt-5 grid gap-4">
              <div
                :for={distance <- @distances}
                class="min-w-0 rounded-xl border border-zinc-800 bg-zinc-950/70 p-4"
              >
                <div class="grid gap-3 lg:grid-cols-[minmax(0,1fr)_auto] lg:items-start">
                  <div class="min-w-0">
                    <h3 class="text-lg font-semibold text-white">{distance.from} → {distance.to}</h3>
                    <p class="mt-1 text-sm text-zinc-400">
                      Strategy: {format_atoms(distance.recommended_strategies)}
                    </p>
                  </div>
                  <p class="w-fit rounded-full bg-zinc-800 px-3 py-1 text-xs text-zinc-300 lg:justify-self-end">
                    shared {distance.shared_tones} / ratio {distance.shared_ratio}
                  </p>
                </div>

                <div class="mt-4 grid grid-cols-1 gap-3 text-sm sm:grid-cols-3">
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
    <div class="min-w-0 rounded-lg bg-zinc-950/80 p-3">
      <p class="text-xs uppercase tracking-[0.2em] text-zinc-500">{@label}</p>
      <p class="mt-2 min-w-0 break-words leading-6 text-zinc-100">{@value}</p>
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
      scale_intervals: epoch.scale.intervals,
      root: epoch.root,
      energy: epoch.energy,
      density: epoch.density,
      chord_shape: epoch.chord_shape,
      motif: %{
        id: epoch.motif.id,
        name: epoch.motif.name,
        source_degrees: epoch.motif.scale_degrees,
        degrees: epoch.transformed_motif.scale_degrees,
        rhythm: epoch.transformed_motif.rhythm,
        octave: epoch.transformed_motif.octave,
        transformations:
          Enum.map(epoch.transformed_motif.transformations, &format_transformation/1)
      },
      transition_zone: epoch.transition.zone,
      transition_progress: epoch.transition.progress,
      transition_plan: transition_plan_state(epoch.transition_plan)
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

  defp format_transition_plan(%{phase: :stable}), do: "stable"

  defp format_transition_plan(%{
         phase: phase,
         current_bar: current_bar,
         duration_bars: duration_bars,
         path_technique: path_technique,
         arrival_gesture: arrival_gesture
       }) do
    "#{format_atom(phase)} · bar #{current_bar}/#{duration_bars} · #{format_atom(path_technique)} → #{format_atom(arrival_gesture)}"
  end

  defp transition_plan_state(plan) do
    %{
      active: plan.active?,
      phase: plan.phase,
      progress: plan.progress,
      duration_bars: plan.duration_bars,
      current_bar: plan.current_bar,
      path_technique: plan.path_technique,
      arrival_gesture: plan.arrival_gesture,
      strategies: plan.strategies,
      source:
        Map.take(plan.source, [
          :period,
          :scale,
          :root,
          :chord_shape,
          :energy,
          :density,
          :pitch_classes
        ]),
      destination:
        Map.take(plan.destination, [
          :period,
          :scale,
          :root,
          :chord_shape,
          :energy,
          :density,
          :pitch_classes
        ]),
      harmonic_path: plan.harmonic_path,
      melodic_path: plan.melodic_path,
      rhythmic_gesture: plan.rhythmic_gesture
    }
  end

  defp format_zone(zone), do: format_atom(zone)

  defp format_atom(atom), do: atom |> Atom.to_string() |> String.replace("_", " ")

  defp format_transformations([]), do: "identity"

  defp format_transformations(transformations) do
    transformations
    |> Enum.map(&format_transformation/1)
    |> Enum.join(", ")
  end

  defp format_transformation({operation, nil}), do: format_atom(operation)
  defp format_transformation({operation, value}), do: "#{format_atom(operation)} #{value}"

  defp format_atoms(atoms) do
    atoms
    |> Enum.map(&format_atom/1)
    |> Enum.join(", ")
  end
end

defmodule Paraminimal.Composition.Transition do
  @moduledoc """
  A deterministic composed path between musical states.

  The transition plan is descriptive: it tells the client what harmonic,
  melodic, and rhythmic path should be rendered over several bars. It does not
  schedule browser audio directly.
  """

  alias Paraminimal.Composition.Scale
  alias Paraminimal.Composition.ScaleDistance
  alias Paraminimal.Composition.TransitionStrategy
  alias Paraminimal.Composition.Voicing

  @type phase :: :stable | :initiating | :in_progress | :arriving

  @type musical_state :: %{
          period: atom(),
          scale: atom(),
          root: Scale.pitch_class(),
          root_name: String.t(),
          chord_shape: atom(),
          energy: float(),
          density: float()
        }

  @type harmonic_waypoint :: %{
          bar: pos_integer(),
          root: Scale.pitch_class(),
          root_name: String.t(),
          chord_shape: atom(),
          scale: atom(),
          weight: float(),
          voicing: Voicing.voiced_chord()
        }

  @type melodic_waypoint :: %{
          step: non_neg_integer(),
          degree: integer(),
          target_pitch_class: Scale.pitch_class()
        }

  @type rhythmic_gesture :: %{
          family: atom(),
          density: float(),
          subdivision: atom(),
          description: String.t()
        }

  @type t :: %__MODULE__{
          active?: boolean(),
          phase: phase(),
          progress: float(),
          duration_bars: non_neg_integer(),
          current_bar: non_neg_integer(),
          source: musical_state(),
          destination: musical_state(),
          distance: ScaleDistance.t(),
          path_technique: atom(),
          arrival_gesture: atom(),
          strategies: [TransitionStrategy.strategy()],
          harmonic_path: [harmonic_waypoint()],
          melodic_path: [melodic_waypoint()],
          rhythmic_gesture: rhythmic_gesture() | nil
        }

  @enforce_keys [
    :active?,
    :phase,
    :progress,
    :duration_bars,
    :current_bar,
    :source,
    :destination,
    :distance,
    :path_technique,
    :arrival_gesture,
    :strategies,
    :harmonic_path,
    :melodic_path
  ]
  defstruct [
    :active?,
    :phase,
    :progress,
    :duration_bars,
    :current_bar,
    :source,
    :destination,
    :distance,
    :path_technique,
    :arrival_gesture,
    :strategies,
    :harmonic_path,
    :melodic_path,
    :rhythmic_gesture
  ]

  @doc "Builds a composed transition plan from source/destination musical state."
  @spec compose(map()) :: t()
  def compose(%{
        time_transition: time_transition,
        source: source,
        destination: destination,
        distance: %ScaleDistance{} = distance
      }) do
    active? = Map.fetch!(time_transition, :in_transition_zone?)
    progress = Map.fetch!(time_transition, :progress)
    duration_bars = if active?, do: duration_bars(distance, source, destination), else: 0
    strategies = strategies(active?, distance, source, destination)
    path_technique = path_technique(strategies, distance, duration_bars)
    arrival_gesture = arrival_gesture(strategies, destination)

    %__MODULE__{
      active?: active?,
      phase: phase(active?, progress),
      progress: progress,
      duration_bars: duration_bars,
      current_bar: current_bar(active?, progress, duration_bars),
      source: source,
      destination: destination,
      distance: distance,
      path_technique: path_technique,
      arrival_gesture: arrival_gesture,
      strategies: strategies,
      harmonic_path:
        duration_bars
        |> harmonic_path(source, destination, distance)
        |> Voicing.voice_path(),
      melodic_path: melodic_path(source, destination),
      rhythmic_gesture: rhythmic_gesture(strategies, source, destination)
    }
  end

  defp phase(false, _progress), do: :stable
  defp phase(true, progress) when progress < 0.2, do: :initiating
  defp phase(true, progress) when progress < 0.8, do: :in_progress
  defp phase(true, _progress), do: :arriving

  defp duration_bars(%ScaleDistance{} = distance, source, destination) do
    energy_delta = abs(destination.energy - source.energy)
    density_delta = abs(destination.density - source.density)

    cond do
      distance.shared_ratio < 0.4 or energy_delta >= 0.35 -> 16
      distance.voice_leading_cost >= 8 or density_delta >= 0.25 -> 12
      true -> 8
    end
  end

  defp current_bar(false, _progress, _duration_bars), do: 0

  defp current_bar(true, progress, duration_bars) do
    progress
    |> Kernel.*(duration_bars)
    |> Float.floor()
    |> trunc()
    |> min(duration_bars - 1)
    |> Kernel.+(1)
  end

  defp strategies(false, _distance, _source, _destination), do: [:stable_sustain]

  defp strategies(true, distance, source, destination) do
    TransitionStrategy.select(
      distance,
      destination.energy - source.energy,
      destination.density - source.density
    )
  end

  defp path_technique([:stable_sustain], _distance, _duration_bars), do: :stable_sustain

  defp path_technique(strategies, distance, duration_bars) do
    cond do
      :silence_as_arrival in strategies and duration_bars <= 8 -> :tritone_dominant
      :common_tone_sustention in strategies -> :common_tone
      distance.circle_fifths_distance >= 4 and duration_bars >= 12 -> :circle_of_fifths
      :voice_leading_migration in strategies -> :voice_leading_migration
      :progressive_chord_change in strategies -> :progressive_chord_change
      true -> hd(strategies)
    end
  end

  defp arrival_gesture(strategies, destination) do
    cond do
      :silence_as_arrival in strategies -> :silence_as_arrival
      :rhythmic_fill in strategies -> :rhythmic_drop_arrival
      :common_tone_sustention in strategies -> :common_tone_drone_arrival
      destination.energy >= 0.7 -> :suspended_arrival
      destination.density <= 0.2 -> :modal_arrival
      true -> :modal_arrival
    end
  end

  defp harmonic_path(0, source, _destination, _distance) do
    [
      %{
        bar: 1,
        root: source.root,
        root_name: source.root_name,
        chord_shape: source.chord_shape,
        scale: source.scale,
        weight: 1.0
      }
    ]
  end

  defp harmonic_path(duration_bars, source, destination, distance) do
    shared_weight = max(distance.shared_ratio, 0.15)

    for bar <- 1..duration_bars do
      weight = Float.round(bar / duration_bars, 3)
      root = interpolate_pitch_class(source.root, destination.root, weight)

      %{
        bar: bar,
        root: root,
        root_name: Scale.note_name(root),
        chord_shape: if(weight < 0.66, do: source.chord_shape, else: destination.chord_shape),
        scale: if(weight < shared_weight, do: source.scale, else: destination.scale),
        weight: weight
      }
    end
  end

  defp melodic_path(source, destination) do
    source_pitches = Map.fetch!(source, :pitch_classes)
    destination_pitches = Map.fetch!(destination, :pitch_classes)

    source_pitches
    |> Enum.take(4)
    |> Enum.with_index()
    |> Enum.map(fn {pitch, index} ->
      target = nearest_pitch(pitch, destination_pitches)

      %{
        step: index,
        degree: index,
        target_pitch_class: target
      }
    end)
  end

  defp rhythmic_gesture(strategies, source, destination) do
    cond do
      :rhythmic_dissolution in strategies ->
        %{
          family: :rhythmic_dissolution,
          density: max(destination.density, 0.1),
          subdivision: :eighths,
          description: "fragment rhythm and leave space before arrival"
        }

      :rhythmic_fill in strategies ->
        %{
          family: :rhythmic_fill,
          density: max(source.density, destination.density),
          subdivision: :sixteenths,
          description: "multi-bar fill gesture using toms, cut breaks, or minimal percussion"
        }

      true ->
        nil
    end
  end

  defp interpolate_pitch_class(from, to, weight) do
    clockwise = Integer.mod(to - from, 12)
    counter = clockwise - 12
    interval = if abs(clockwise) <= abs(counter), do: clockwise, else: counter

    from
    |> Kernel.+(round(interval * weight))
    |> Integer.mod(12)
  end

  defp nearest_pitch(pitch, candidates) do
    Enum.min_by(candidates, &circular_distance(pitch, &1))
  end

  defp circular_distance(a, b) do
    distance = abs(a - b)
    min(distance, 12 - distance)
  end
end

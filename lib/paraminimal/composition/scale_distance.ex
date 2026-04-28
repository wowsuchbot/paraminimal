defmodule Paraminimal.Composition.ScaleDistance do
  @moduledoc """
  Distance metrics between scales.

  These metrics intentionally stay independent of Phoenix, Ecto, and audio
  scheduling so they can become the stable core for transition selection.
  """

  alias Paraminimal.Composition.Scale

  @type t :: %__MODULE__{
          from: String.t(),
          to: String.t(),
          shared_tones: non_neg_integer(),
          shared_ratio: float(),
          circle_fifths_distance: non_neg_integer(),
          voice_leading_cost: non_neg_integer(),
          interval_vector_similarity: float(),
          recommended_strategies: [atom()]
        }

  defstruct [
    :from,
    :to,
    :shared_tones,
    :shared_ratio,
    :circle_fifths_distance,
    :voice_leading_cost,
    :interval_vector_similarity,
    :recommended_strategies
  ]

  @doc "Computes the available distance metrics for two scales."
  @spec between(Scale.t(), Scale.t()) :: t()
  def between(%Scale{} = from, %Scale{} = to) do
    from_pitches = Scale.pitch_classes(from)
    to_pitches = Scale.pitch_classes(to)
    shared_tones = shared_tones(from_pitches, to_pitches)
    shared_ratio = shared_tones / max(length(from_pitches), length(to_pitches))
    circle_fifths_distance = circle_fifths_distance(from.root, to.root)
    voice_leading_cost = voice_leading_cost(from_pitches, to_pitches)
    interval_vector_similarity = interval_vector_similarity(from_pitches, to_pitches)

    %__MODULE__{
      from: from.name,
      to: to.name,
      shared_tones: shared_tones,
      shared_ratio: Float.round(shared_ratio, 3),
      circle_fifths_distance: circle_fifths_distance,
      voice_leading_cost: voice_leading_cost,
      interval_vector_similarity: Float.round(interval_vector_similarity, 3),
      recommended_strategies:
        recommend_strategies(shared_ratio, circle_fifths_distance, voice_leading_cost)
    }
  end

  @doc "Returns the number of shared pitch classes."
  @spec shared_tones([Scale.pitch_class()], [Scale.pitch_class()]) :: non_neg_integer()
  def shared_tones(from_pitches, to_pitches) do
    from_pitches
    |> MapSet.new()
    |> MapSet.intersection(MapSet.new(to_pitches))
    |> MapSet.size()
  end

  @doc "Computes root distance on the circle of fifths."
  @spec circle_fifths_distance(Scale.pitch_class(), Scale.pitch_class()) :: non_neg_integer()
  def circle_fifths_distance(from_root, to_root) when from_root in 0..11 and to_root in 0..11 do
    distance =
      from_root
      |> fifth_index()
      |> Kernel.-(fifth_index(to_root))
      |> abs()

    min(distance, 12 - distance)
  end

  @doc """
  Computes a simple minimal voice-leading cost from source pitch classes to the
  nearest target pitch classes.
  """
  @spec voice_leading_cost([Scale.pitch_class()], [Scale.pitch_class()]) :: non_neg_integer()
  def voice_leading_cost(from_pitches, to_pitches) do
    Enum.reduce(from_pitches, 0, fn pitch, total ->
      total + Enum.min(Enum.map(to_pitches, &circular_semitone_distance(pitch, &1)))
    end)
  end

  @doc "Compares interval-class vectors using cosine similarity."
  @spec interval_vector_similarity([Scale.pitch_class()], [Scale.pitch_class()]) :: float()
  def interval_vector_similarity(from_pitches, to_pitches) do
    from_vector = interval_vector(from_pitches)
    to_vector = interval_vector(to_pitches)
    dot = Enum.zip_reduce(from_vector, to_vector, 0, fn a, b, acc -> acc + a * b end)
    from_magnitude = magnitude(from_vector)
    to_magnitude = magnitude(to_vector)

    if from_magnitude == 0.0 or to_magnitude == 0.0 do
      0.0
    else
      dot / (from_magnitude * to_magnitude)
    end
  end

  defp fifth_index(pitch_class), do: Integer.mod(pitch_class * 7, 12)

  defp circular_semitone_distance(a, b) do
    distance = abs(a - b)
    min(distance, 12 - distance)
  end

  defp interval_vector(pitches) do
    pitch_pairs =
      for a <- pitches,
          b <- pitches,
          a < b,
          do: circular_interval_class(a, b)

    for interval_class <- 1..6 do
      Enum.count(pitch_pairs, &(&1 == interval_class))
    end
  end

  defp circular_interval_class(a, b) do
    distance = Integer.mod(b - a, 12)
    min(distance, 12 - distance)
  end

  defp magnitude(vector) do
    vector
    |> Enum.reduce(0, fn value, total -> total + value * value end)
    |> :math.sqrt()
  end

  defp recommend_strategies(shared_ratio, circle_fifths_distance, voice_leading_cost) do
    cond do
      shared_ratio >= 0.75 and circle_fifths_distance <= 2 ->
        [:common_tone, :modal_interchange, :melodic_migration]

      shared_ratio >= 0.5 and voice_leading_cost <= 8 ->
        [:voice_leading_migration, :melodic_migration, :register_collapse]

      true ->
        [:silence_as_arrival, :canon_handoff, :fragmentation]
    end
  end
end

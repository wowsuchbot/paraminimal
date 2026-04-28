defmodule Paraminimal.Composition.Epoch do
  @moduledoc """
  Deterministic composition state for a point in global UTC time.
  """

  alias Paraminimal.Composition.Scale
  alias Paraminimal.Composition.ScaleDistance
  alias Paraminimal.Composition.TimeSystem
  alias Paraminimal.Scales.Western

  @type t :: %__MODULE__{
          id: String.t(),
          generated_at: DateTime.t(),
          period: TimeSystem.period(),
          next_period: TimeSystem.period(),
          transition: TimeSystem.transition(),
          scale: Scale.t(),
          root: Scale.pitch_class(),
          root_name: String.t(),
          chord_shape: atom(),
          energy: float(),
          density: float(),
          distances: [ScaleDistance.t()]
        }

  defstruct [
    :id,
    :generated_at,
    :period,
    :next_period,
    :transition,
    :scale,
    :root,
    :root_name,
    :chord_shape,
    :energy,
    :density,
    :distances
  ]

  @doc "Builds the current epoch from the UTC clock."
  @spec current() :: t()
  def current, do: DateTime.utc_now() |> for_datetime()

  @doc "Builds deterministic epoch state for a UTC DateTime."
  @spec for_datetime(DateTime.t()) :: t()
  def for_datetime(%DateTime{} = datetime) do
    utc = DateTime.shift_zone!(datetime, "Etc/UTC")
    period = TimeSystem.period_for(utc)
    next_period = TimeSystem.next_period(period)
    transition = TimeSystem.transition_for(utc)
    progress = TimeSystem.period_progress(utc, period)
    root = root_for(utc, period)
    scale = scale_for(utc, period, root)
    next_root = root_for(utc, next_period)

    distances =
      next_period.scale_candidates
      |> Enum.map(&Western.get!(&1, next_root))
      |> Enum.map(&ScaleDistance.between(scale, &1))

    %__MODULE__{
      id: epoch_id(utc),
      generated_at: utc,
      period: period,
      next_period: next_period,
      transition: transition,
      scale: scale,
      root: root,
      root_name: Scale.note_name(root),
      chord_shape: chord_shape_for(period, scale),
      energy: profile_value(period.energy_profile, progress),
      density: profile_value(period.density_profile, progress),
      distances: distances
    }
  end

  @doc "Returns true when two epochs represent the same deterministic bucket."
  @spec same_epoch?(t(), t()) :: boolean()
  def same_epoch?(%__MODULE__{id: id}, %__MODULE__{id: id}), do: true
  def same_epoch?(%__MODULE__{}, %__MODULE__{}), do: false

  defp scale_for(datetime, period, root) do
    scale_slug =
      period.scale_candidates
      |> Enum.at(selection_index(datetime, period, length(period.scale_candidates)))

    Western.get!(scale_slug, root)
  end

  defp root_for(datetime, period) do
    stable_hash({Date.to_iso8601(DateTime.to_date(datetime)), datetime.hour, period.key}, 12)
  end

  defp selection_index(datetime, period, count) do
    stable_hash({epoch_id(datetime), period.key, :scale}, count)
  end

  defp chord_shape_for(%{key: :deep_night}, _scale), do: :cluster
  defp chord_shape_for(%{key: :dawn}, _scale), do: :open_fifth
  defp chord_shape_for(%{key: :morning}, _scale), do: :triad
  defp chord_shape_for(%{key: :afternoon}, _scale), do: :sixth
  defp chord_shape_for(%{key: :twilight}, _scale), do: :seventh
  defp chord_shape_for(%{key: :night}, _scale), do: :suspended

  defp profile_value(profile, progress) do
    profile
    |> raw_profile_value(progress)
    |> clamp()
    |> Float.round(2)
  end

  defp raw_profile_value({low, high, :minimal}, progress) do
    low + (high - low) * (0.5 + :math.sin(progress * :math.pi() * 2) * 0.1)
  end

  defp raw_profile_value({low, high, :rising}, progress), do: low + (high - low) * progress

  defp raw_profile_value({low, high, :falling}, progress), do: low + (high - low) * progress

  defp raw_profile_value({low, high, :sustained}, progress) do
    midpoint = (low + high) / 2
    midpoint + :math.sin(progress * :math.pi()) * ((high - low) / 4)
  end

  defp raw_profile_value({low, high, :tense}, progress) do
    low + (high - low) * (0.35 + :math.sin(progress * :math.pi() * 3) * 0.15)
  end

  defp raw_profile_value({low, high, :sparse}, progress) do
    low + (high - low) * (0.25 + progress * 0.35)
  end

  defp clamp(value), do: value |> max(0.0) |> min(1.0)

  defp epoch_id(datetime) do
    date = Date.to_iso8601(DateTime.to_date(datetime))
    hour = datetime.hour |> Integer.to_string() |> String.pad_leading(2, "0")

    minute_bucket =
      (div(datetime.minute, 15) * 15) |> Integer.to_string() |> String.pad_leading(2, "0")

    "#{date}T#{hour}:#{minute_bucket}Z"
  end

  defp stable_hash(term, modulo) do
    term
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> :binary.decode_unsigned()
    |> Integer.mod(modulo)
  end
end

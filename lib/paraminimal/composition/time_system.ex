defmodule Paraminimal.Composition.TimeSystem do
  @moduledoc """
  Global UTC time structure for the composition engine.

  All listeners share this clock. Display layers may format time differently
  later, but composition decisions should stay UTC-derived and deterministic.
  """

  @transition_window_minutes 20

  @type period_key :: :deep_night | :dawn | :morning | :afternoon | :twilight | :night

  @type period :: %{
          key: period_key(),
          name: String.t(),
          start_hour: 0..23,
          end_hour: 1..24,
          character: String.t(),
          scale_candidates: [atom()],
          energy_profile: {float(), float(), atom()},
          density_profile: {float(), float(), atom()},
          texture: String.t(),
          rhythmic_character: String.t()
        }

  @type transition :: %{
          in_transition_zone?: boolean(),
          zone: :core | :approaching_boundary,
          next_period: period(),
          minutes_to_boundary: non_neg_integer(),
          progress: float(),
          window_minutes: pos_integer()
        }

  @periods [
    %{
      key: :deep_night,
      name: "Deep Night",
      start_hour: 0,
      end_hour: 5,
      character: "still, recursive",
      scale_candidates: [:diminished, :chromatic, :minor_pentatonic],
      energy_profile: {0.08, 0.24, :minimal},
      density_profile: {0.05, 0.22, :minimal},
      texture: "near-silence",
      rhythmic_character: "sparse pulses, long rests"
    },
    %{
      key: :dawn,
      name: "Dawn",
      start_hour: 5,
      end_hour: 8,
      character: "emerging, luminous",
      scale_candidates: [:lydian, :major_pentatonic],
      energy_profile: {0.2, 0.55, :rising},
      density_profile: {0.12, 0.45, :rising},
      texture: "sparse to unfolding",
      rhythmic_character: "unfolding, lightly syncopated"
    },
    %{
      key: :morning,
      name: "Morning",
      start_hour: 8,
      end_hour: 12,
      character: "bright, active",
      scale_candidates: [:ionian, :mixolydian],
      energy_profile: {0.65, 0.9, :sustained},
      density_profile: {0.55, 0.85, :sustained},
      texture: "full, rhythmic",
      rhythmic_character: "steady, active, clear pulse"
    },
    %{
      key: :afternoon,
      name: "Afternoon",
      start_hour: 12,
      end_hour: 17,
      character: "warm, flowing",
      scale_candidates: [:dorian, :major_pentatonic, :melodic_minor],
      energy_profile: {0.42, 0.7, :sustained},
      density_profile: {0.38, 0.68, :sustained},
      texture: "melodic focus",
      rhythmic_character: "flowing, medium-density groove"
    },
    %{
      key: :twilight,
      name: "Twilight",
      start_hour: 17,
      end_hour: 20,
      character: "transitional, wistful",
      scale_candidates: [:aeolian, :harmonic_minor, :dorian],
      energy_profile: {0.55, 0.25, :falling},
      density_profile: {0.5, 0.18, :falling},
      texture: "thinning",
      rhythmic_character: "loosening, phrase-led motion"
    },
    %{
      key: :night,
      name: "Night",
      start_hour: 20,
      end_hour: 24,
      character: "dark, mysterious",
      scale_candidates: [:phrygian, :locrian, :minor_pentatonic],
      energy_profile: {0.22, 0.38, :tense},
      density_profile: {0.15, 0.35, :sparse},
      texture: "sparse, reverberant",
      rhythmic_character: "slow, tense, spacious"
    }
  ]

  @doc "Returns the configured period definitions."
  @spec periods() :: [period()]
  def periods, do: @periods

  @doc "Returns the period currently active in UTC."
  @spec current_period() :: period()
  def current_period, do: DateTime.utc_now() |> period_for()

  @doc "Returns the active period for a UTC DateTime."
  @spec period_for(DateTime.t()) :: period()
  def period_for(%DateTime{} = datetime) do
    minute = minute_of_day(datetime)

    Enum.find(@periods, fn period ->
      minute >= period.start_hour * 60 and minute < period.end_hour * 60
    end)
  end

  @doc "Returns a period by key."
  @spec period!(period_key()) :: period()
  def period!(key),
    do: Enum.find(@periods, &(&1.key == key)) || raise(ArgumentError, "unknown period #{key}")

  @doc "Returns the period after the given period."
  @spec next_period(period() | period_key()) :: period()
  def next_period(%{key: key}), do: next_period(key)

  def next_period(key) when is_atom(key) do
    index = Enum.find_index(@periods, &(&1.key == key))
    Enum.at(@periods, Integer.mod(index + 1, length(@periods)))
  end

  @doc "Returns transition-zone information for a UTC DateTime."
  @spec transition_for(DateTime.t()) :: transition()
  def transition_for(%DateTime{} = datetime) do
    period = period_for(datetime)
    next = next_period(period)
    minutes_to_boundary = minutes_until_end(datetime, period)
    in_transition_zone? = minutes_to_boundary <= @transition_window_minutes

    progress =
      if in_transition_zone? do
        (@transition_window_minutes - minutes_to_boundary) / @transition_window_minutes
      else
        0.0
      end

    %{
      in_transition_zone?: in_transition_zone?,
      zone: if(in_transition_zone?, do: :approaching_boundary, else: :core),
      next_period: next,
      minutes_to_boundary: minutes_to_boundary,
      progress: Float.round(progress, 3),
      window_minutes: @transition_window_minutes
    }
  end

  @doc "Returns progress through the current period as a value from 0.0 to 1.0."
  @spec period_progress(DateTime.t(), period()) :: float()
  def period_progress(%DateTime{} = datetime, period) do
    minute = minute_of_day(datetime)
    start_minute = period.start_hour * 60
    duration = (period.end_hour - period.start_hour) * 60

    ((minute - start_minute) / duration)
    |> max(0.0)
    |> min(1.0)
    |> Float.round(3)
  end

  defp minutes_until_end(datetime, period) do
    minute = minute_of_day(datetime)
    boundary = period.end_hour * 60

    boundary - minute
  end

  defp minute_of_day(%DateTime{} = datetime) do
    utc = DateTime.shift_zone!(datetime, "Etc/UTC")
    utc.hour * 60 + utc.minute
  end
end

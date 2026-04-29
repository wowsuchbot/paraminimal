defmodule Paraminimal.Composition.ChordVocabulary do
  @moduledoc """
  Modal chord vocabulary and voicing metadata.

  This module describes legal harmonic material for each scale family. It stays
  data-oriented so transition pathing can remain separate from voicing and audio
  rendering.
  """

  alias Paraminimal.Composition.Scale

  @type register_policy :: :root_fifth | :guide_tones | :extensions

  @type t :: %__MODULE__{
          scale: atom(),
          scale_mask: non_neg_integer(),
          characteristic_intervals: [integer()],
          avoid_intervals: [integer()],
          chord_roles: %{atom() => [integer()]},
          arrivals: [atom()],
          voicing_logic: %{
            low: register_policy(),
            mid: register_policy(),
            high: register_policy()
          },
          constraints: [atom()]
        }

  @enforce_keys [
    :scale,
    :scale_mask,
    :characteristic_intervals,
    :avoid_intervals,
    :chord_roles,
    :arrivals,
    :voicing_logic,
    :constraints
  ]
  defstruct [
    :scale,
    :scale_mask,
    :characteristic_intervals,
    :avoid_intervals,
    :chord_roles,
    :arrivals,
    :voicing_logic,
    :constraints
  ]

  @definitions %{
    ionian: %{
      intervals: [0, 2, 4, 5, 7, 9, 11],
      characteristic_intervals: [4],
      avoid_intervals: [5],
      chord_roles: %{tonic: [0, 4, 7, 11], color: [5, 9, 0, 4], arrival: [7, 11, 2, 5]},
      arrivals: [:authentic_cadence],
      constraints: [:avoid_natural_four_against_third]
    },
    dorian: %{
      intervals: [0, 2, 3, 5, 7, 9, 10],
      characteristic_intervals: [3, 9],
      avoid_intervals: [],
      chord_roles: %{tonic: [0, 3, 7, 9], color: [5, 9, 0, 3], arrival: [10, 2, 5]},
      arrivals: [:modal_arrival, :common_tone_drone_arrival],
      constraints: []
    },
    phrygian: %{
      intervals: [0, 1, 3, 5, 7, 8, 10],
      characteristic_intervals: [1],
      avoid_intervals: [],
      chord_roles: %{tonic: [0, 3, 7], color: [1, 5, 8], arrival: [7, 10, 1]},
      arrivals: [:modal_arrival, :suspended_arrival],
      constraints: [:keep_flat_two_above_root]
    },
    lydian: %{
      intervals: [0, 2, 4, 6, 7, 9, 11],
      characteristic_intervals: [6],
      avoid_intervals: [],
      chord_roles: %{tonic: [0, 4, 7, 11, 18], color: [2, 6, 9], arrival: [7, 11, 2, 6]},
      arrivals: [:suspended_arrival, :common_tone_drone_arrival],
      constraints: [:include_sharp_four_high]
    },
    mixolydian: %{
      intervals: [0, 2, 4, 5, 7, 9, 10],
      characteristic_intervals: [10],
      avoid_intervals: [],
      chord_roles: %{tonic: [0, 4, 7, 10], color: [10, 2, 5], arrival: [5, 9, 0]},
      arrivals: [:modal_arrival, :rhythmic_drop_arrival],
      constraints: []
    },
    aeolian: %{
      intervals: [0, 2, 3, 5, 7, 8, 10],
      characteristic_intervals: [8],
      avoid_intervals: [],
      chord_roles: %{tonic: [0, 3, 7, 8], color: [8, 0, 3], arrival: [10, 2, 5]},
      arrivals: [:modal_arrival, :silence_as_arrival],
      constraints: []
    },
    locrian: %{
      intervals: [0, 1, 3, 5, 6, 8, 10],
      characteristic_intervals: [1, 6],
      avoid_intervals: [],
      chord_roles: %{tonic: [0, 3, 6], color: [1, 5, 8], arrival: [6, 10, 1]},
      arrivals: [:suspended_arrival, :silence_as_arrival],
      constraints: [:keep_flat_two_above_root]
    },
    major_pentatonic: %{
      intervals: [0, 2, 4, 7, 9],
      characteristic_intervals: [2, 9],
      avoid_intervals: [],
      chord_roles: %{tonic: [0, 2, 4, 7, 9], color: [2, 7, 9], arrival: [0, 7, 9]},
      arrivals: [:common_tone_drone_arrival, :rhythmic_drop_arrival],
      constraints: [:quartal_safe]
    },
    minor_pentatonic: %{
      intervals: [0, 3, 5, 7, 10],
      characteristic_intervals: [3, 10],
      avoid_intervals: [],
      chord_roles: %{tonic: [0, 3, 5, 7, 10], color: [5, 10, 3], arrival: [0, 7, 10]},
      arrivals: [:common_tone_drone_arrival, :rhythmic_drop_arrival],
      constraints: [:quartal_safe]
    },
    natural_minor: %{
      intervals: [0, 2, 3, 5, 7, 8, 10],
      characteristic_intervals: [8],
      avoid_intervals: [],
      chord_roles: %{tonic: [0, 3, 7, 8], color: [8, 0, 3], arrival: [10, 2, 5]},
      arrivals: [:modal_arrival, :silence_as_arrival],
      constraints: []
    },
    harmonic_minor: %{
      intervals: [0, 2, 3, 5, 7, 8, 11],
      characteristic_intervals: [8, 11],
      avoid_intervals: [],
      chord_roles: %{tonic: [0, 3, 7, 11], color: [8, 0, 3], arrival: [7, 11, 2, 5, 8]},
      arrivals: [:authentic_cadence, :suspended_arrival],
      constraints: [:split_flat_six_and_major_seven]
    },
    melodic_minor: %{
      intervals: [0, 2, 3, 5, 7, 9, 11],
      characteristic_intervals: [9, 11],
      avoid_intervals: [],
      chord_roles: %{tonic: [0, 3, 7, 9, 14], color: [5, 9, 11], arrival: [7, 11, 2, 5]},
      arrivals: [:modal_arrival, :suspended_arrival],
      constraints: [:quartal_safe]
    },
    diminished: %{
      intervals: [0, 2, 3, 5, 6, 8, 9, 11],
      characteristic_intervals: [3, 6, 9],
      avoid_intervals: [],
      chord_roles: %{tonic: [0, 3, 6, 9], color: [0, 3, 6, 10], arrival: [11, 2, 5, 8]},
      arrivals: [:silence_as_arrival, :suspended_arrival],
      constraints: [:minor_third_symmetry]
    },
    whole_tone: %{
      intervals: [0, 2, 4, 6, 8, 10],
      characteristic_intervals: [4, 8, 10],
      avoid_intervals: [],
      chord_roles: %{tonic: [0, 4, 8, 10, 14, 18], color: [2, 6, 10], arrival: [0, 4, 8]},
      arrivals: [:suspended_arrival, :common_tone_drone_arrival],
      constraints: [:no_perfect_fifth]
    },
    chromatic: %{
      intervals: Enum.to_list(0..11),
      characteristic_intervals: [],
      avoid_intervals: [],
      chord_roles: %{tonic: [0, 3, 7, 10], color: [1, 4, 8], arrival: [0, 7]},
      arrivals: [:silence_as_arrival, :rhythmic_drop_arrival],
      constraints: [:requires_selected_subset]
    }
  }

  @doc "Returns vocabulary for a scale slug."
  @spec get!(atom()) :: t()
  def get!(scale) when is_atom(scale) do
    definition = Map.fetch!(@definitions, scale)

    %__MODULE__{
      scale: scale,
      scale_mask: scale_mask(definition.intervals),
      characteristic_intervals: definition.characteristic_intervals,
      avoid_intervals: definition.avoid_intervals,
      chord_roles: definition.chord_roles,
      arrivals: definition.arrivals,
      voicing_logic: %{low: :root_fifth, mid: :guide_tones, high: :extensions},
      constraints: definition.constraints
    }
  end

  @doc "Returns all known vocabulary slugs."
  @spec known_scales() :: [atom()]
  def known_scales, do: @definitions |> Map.keys() |> Enum.sort()

  @doc "Builds a 12-bit mask from scale intervals or pitch classes."
  @spec scale_mask([integer()] | Scale.t()) :: non_neg_integer()
  def scale_mask(%Scale{intervals: intervals}), do: scale_mask(intervals)

  def scale_mask(intervals) when is_list(intervals) do
    Enum.reduce(intervals, 0, fn interval, mask ->
      Bitwise.bor(mask, Bitwise.bsl(1, Integer.mod(interval, 12)))
    end)
  end

  @doc "Returns chord intervals for a role, falling back to tonic material."
  @spec chord_intervals(t(), atom()) :: [integer()]
  def chord_intervals(%__MODULE__{chord_roles: roles}, role) do
    Map.get(roles, role) || Map.fetch!(roles, :tonic)
  end

  @doc "Maps a symbolic chord shape onto the vocabulary's chord roles."
  @spec role_for_shape(atom()) :: atom()
  def role_for_shape(:cluster), do: :color
  def role_for_shape(:open_fifth), do: :tonic
  def role_for_shape(:sixth), do: :tonic
  def role_for_shape(:seventh), do: :tonic
  def role_for_shape(:suspended), do: :arrival
  def role_for_shape(:triad), do: :tonic
  def role_for_shape(_shape), do: :tonic

  @doc "Returns true when an interval should not be held as a stable chord member."
  @spec avoid_interval?(t(), integer()) :: boolean()
  def avoid_interval?(%__MODULE__{avoid_intervals: avoid_intervals}, interval) do
    Integer.mod(interval, 12) in Enum.map(avoid_intervals, &Integer.mod(&1, 12))
  end
end

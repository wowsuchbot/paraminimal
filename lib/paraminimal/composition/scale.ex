defmodule Paraminimal.Composition.Scale do
  @moduledoc """
  Scale metadata used by the composition engine.

  Intervals are semitone offsets from the scale root. Roots are pitch classes,
  where `0` is C and `11` is B.
  """

  @type pitch_class :: 0..11
  @type t :: %__MODULE__{
          slug: atom(),
          name: String.t(),
          root: pitch_class(),
          root_name: String.t(),
          intervals: [pitch_class()],
          mode_number: pos_integer() | nil,
          parent_key: String.t() | nil,
          character_tags: [atom()],
          energy_range: {float(), float()},
          typical_register: {non_neg_integer(), non_neg_integer()},
          period_affinity: [atom()]
        }

  @enforce_keys [
    :slug,
    :name,
    :root,
    :root_name,
    :intervals,
    :character_tags,
    :energy_range,
    :typical_register,
    :period_affinity
  ]
  defstruct [
    :slug,
    :name,
    :root,
    :root_name,
    :intervals,
    :mode_number,
    :parent_key,
    :character_tags,
    :energy_range,
    :typical_register,
    :period_affinity
  ]

  @note_names ~w(C C# D Eb E F F# G Ab A Bb B)

  @doc "Builds the pitch classes produced by the scale root and interval set."
  @spec pitch_classes(t()) :: [pitch_class()]
  def pitch_classes(%__MODULE__{root: root, intervals: intervals}) do
    intervals
    |> Enum.map(&Integer.mod(root + &1, 12))
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc "Returns a display name for a pitch class."
  @spec note_name(pitch_class()) :: String.t()
  def note_name(pitch_class) when pitch_class in 0..11 do
    Enum.at(@note_names, pitch_class)
  end
end

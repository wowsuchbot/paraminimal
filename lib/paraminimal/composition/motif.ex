defmodule Paraminimal.Composition.Motif do
  @moduledoc """
  A melodic fragment that defines the character of a time period.

  Motifs are the raw material for the canon-based composition engine.
  Each motif carries scale degrees (relative to a scale root), a rhythm
  pattern, and metadata about which period and energy range it suits.
  """

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          scale_degrees: [integer()],
          rhythm: [float()],
          octave: integer(),
          period_affinity: atom(),
          transformation_tendency: [atom()],
          energy_range: {float(), float()}
        }

  @enforce_keys [
    :id,
    :name,
    :scale_degrees,
    :rhythm,
    :octave,
    :period_affinity,
    :transformation_tendency,
    :energy_range
  ]

  defstruct [
    :id,
    :name,
    :scale_degrees,
    :rhythm,
    :octave,
    :period_affinity,
    :transformation_tendency,
    :energy_range
  ]

  @doc "Returns the number of notes in the motif."
  @spec length(t()) :: non_neg_integer()
  def length(%__MODULE__{scale_degrees: degrees}), do: Kernel.length(degrees)

  @doc "Returns the total rhythmic duration of the motif."
  @spec total_duration(t()) :: float()
  def total_duration(%__MODULE__{rhythm: rhythm}) do
    Enum.sum(rhythm)
  end

  @doc "Returns the intervallic range (max - min) of the scale degrees."
  @spec range(t()) :: non_neg_integer()
  def range(%__MODULE__{scale_degrees: degrees}) do
    Enum.max(degrees) - Enum.min(degrees)
  end
end

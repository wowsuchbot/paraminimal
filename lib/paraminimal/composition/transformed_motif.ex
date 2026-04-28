defmodule Paraminimal.Composition.TransformedMotif do
  @moduledoc """
  A motif that has been through one or more canon transformations.

  Tracks the full lineage back to the source motif so any fragment
  can be traced to its origin.
  """

  @type transformation :: {atom(), term()}
  @type t :: %__MODULE__{
          source_id: String.t(),
          transformations: [transformation()],
          scale_degrees: [integer()],
          rhythm: [float()],
          octave: integer()
        }

  @enforce_keys [:source_id, :transformations, :scale_degrees, :rhythm, :octave]
  defstruct [:source_id, :transformations, :scale_degrees, :rhythm, :octave]

  @doc "Builds a TransformedMotif from a base Motif (identity transform)."
  @spec from_motif(Paraminimal.Composition.Motif.t()) :: t()
  def from_motif(%Paraminimal.Composition.Motif{} = motif) do
    %__MODULE__{
      source_id: motif.id,
      transformations: [],
      scale_degrees: motif.scale_degrees,
      rhythm: motif.rhythm,
      octave: motif.octave
    }
  end

  @doc "Returns the depth of the transformation chain."
  @spec chain_depth(t()) :: non_neg_integer()
  def chain_depth(%__MODULE__{transformations: transformations}) do
    Kernel.length(transformations)
  end
end

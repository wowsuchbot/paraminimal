defmodule Paraminimal.Motifs.Dawn do
  @moduledoc """
  Motifs for the Dawn period (5-8h).

  Character: emerging, luminous, unfolding.
  Rising patterns, open intervals (4ths, 5ths), expanding arcs.
  """

  alias Paraminimal.Composition.Motif

  @spec all() :: [Motif.t()]
  def all do
    [
      %Motif{
        id: "dawn_rising_fourths_1",
        name: "Rising Fourths",
        scale_degrees: [0, 5, 2, 7, 4, 9],
        rhythm: [1.0, 1.0, 0.5, 1.0, 0.5, 2.0],
        octave: 0,
        period_affinity: :dawn,
        transformation_tendency: [:augmentation, :transposition],
        energy_range: {0.20, 0.35}
      },
      %Motif{
        id: "dawn_open_fifth_arc_1",
        name: "Open Fifth Arc",
        scale_degrees: [0, 7, 12, 7, 0],
        rhythm: [1.0, 1.5, 2.0, 1.5, 2.0],
        octave: 0,
        period_affinity: :dawn,
        transformation_tendency: [:augmentation, :transposition],
        energy_range: {0.25, 0.45}
      },
      %Motif{
        id: "dawn_unfolding_scale_1",
        name: "Unfolding Scale",
        scale_degrees: [0, 2, 4, 5, 7, 9, 11],
        rhythm: [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 2.0],
        octave: 0,
        period_affinity: :dawn,
        transformation_tendency: [:transposition, :augmentation],
        energy_range: {0.30, 0.50}
      },
      %Motif{
        id: "dawn_luminous_skip_1",
        name: "Luminous Skip",
        scale_degrees: [0, 5, 7, 12],
        rhythm: [1.0, 1.0, 1.5, 3.0],
        octave: 1,
        period_affinity: :dawn,
        transformation_tendency: [:augmentation, :transposition],
        energy_range: {0.22, 0.55}
      }
    ]
  end
end

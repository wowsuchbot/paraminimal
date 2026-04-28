defmodule Paraminimal.Motifs.Twilight do
  @moduledoc """
  Motifs for the Twilight period (17-20h).

  Character: transitional, wistful, thinning.
  Falling patterns, mixed intervals, incomplete cadences.
  """

  alias Paraminimal.Composition.Motif

  @spec all() :: [Motif.t()]
  def all do
    [
      %Motif{
        id: "twilight_falling_fifth_1",
        name: "Falling Fifth",
        scale_degrees: [7, 0, 5, 10, 3, 7],
        rhythm: [1.0, 1.0, 1.0, 1.0, 1.0, 2.0],
        octave: 0,
        period_affinity: :twilight,
        transformation_tendency: [:inversion, :retrograde],
        energy_range: {0.40, 0.55}
      },
      %Motif{
        id: "twilight_wistful_descent_1",
        name: "Wistful Descent",
        scale_degrees: [11, 8, 7, 5, 3, 0],
        rhythm: [1.0, 0.5, 1.5, 0.5, 1.0, 2.5],
        octave: 0,
        period_affinity: :twilight,
        transformation_tendency: [:retrograde, :inversion],
        energy_range: {0.35, 0.50}
      },
      %Motif{
        id: "twilight_incomplete_cadence_1",
        name: "Incomplete Cadence",
        scale_degrees: [0, 4, 7, 5, 3],
        rhythm: [1.0, 1.0, 1.0, 2.0, 3.0],
        octave: 0,
        period_affinity: :twilight,
        transformation_tendency: [:inversion, :retrograde],
        energy_range: {0.28, 0.45}
      },
      %Motif{
        id: "twilight_fading_third_1",
        name: "Fading Third",
        scale_degrees: [7, 4, 2, 0, -1],
        rhythm: [1.5, 1.0, 1.0, 1.5, 3.0],
        octave: 0,
        period_affinity: :twilight,
        transformation_tendency: [:retrograde, :inversion],
        energy_range: {0.25, 0.40}
      }
    ]
  end
end

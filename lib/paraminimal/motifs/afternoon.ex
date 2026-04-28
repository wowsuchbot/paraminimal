defmodule Paraminimal.Motifs.Afternoon do
  @moduledoc """
  Motifs for the Afternoon period (12-17h).

  Character: warm, flowing, melodic focus.
  Stepwise motion, lyrical lines, gentle contours.
  """

  alias Paraminimal.Composition.Motif

  @spec all() :: [Motif.t()]
  def all do
    [
      %Motif{
        id: "afternoon_warm_step_1",
        name: "Warm Step",
        scale_degrees: [0, 2, 3, 5, 7, 9, 10],
        rhythm: [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0],
        octave: 0,
        period_affinity: :afternoon,
        transformation_tendency: [:augmentation, :inversion],
        energy_range: {0.42, 0.58}
      },
      %Motif{
        id: "afternoon_lyrical_arc_1",
        name: "Lyrical Arc",
        scale_degrees: [0, 2, 4, 7, 9, 7, 4, 2],
        rhythm: [1.0, 1.0, 1.5, 1.5, 1.0, 1.0, 1.0, 2.0],
        octave: 0,
        period_affinity: :afternoon,
        transformation_tendency: [:inversion, :augmentation],
        energy_range: {0.50, 0.68}
      },
      %Motif{
        id: "afternoon_gentle_sigh_1",
        name: "Gentle Sigh",
        scale_degrees: [7, 5, 4, 2, 0],
        rhythm: [1.0, 1.5, 1.0, 1.5, 2.0],
        octave: 0,
        period_affinity: :afternoon,
        transformation_tendency: [:augmentation, :inversion],
        energy_range: {0.45, 0.62}
      },
      %Motif{
        id: "afternoon_flowing_thirds_1",
        name: "Flowing Thirds",
        scale_degrees: [0, 3, 2, 5, 4, 7, 5],
        rhythm: [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.5],
        octave: 0,
        period_affinity: :afternoon,
        transformation_tendency: [:inversion, :augmentation],
        energy_range: {0.48, 0.70}
      }
    ]
  end
end

defmodule Paraminimal.Motifs.Night do
  @moduledoc """
  Motifs for the Night period (20-24h).

  Character: dark, mysterious, sparse.
  Narrow ranges, tritone touches, suspended resolutions.
  """

  alias Paraminimal.Composition.Motif

  @spec all() :: [Motif.t()]
  def all do
    [
      %Motif{
        id: "night_tritone_whisper_1",
        name: "Tritone Whisper",
        scale_degrees: [0, 6, 5, 0],
        rhythm: [2.0, 1.0, 2.0, 3.0],
        octave: 0,
        period_affinity: :night,
        transformation_tendency: [:diminution, :inversion],
        energy_range: {0.22, 0.35}
      },
      %Motif{
        id: "night_suspended_shadow_1",
        name: "Suspended Shadow",
        scale_degrees: [0, 5, 6, 7, 6],
        rhythm: [1.5, 1.5, 1.0, 2.0, 3.0],
        octave: -1,
        period_affinity: :night,
        transformation_tendency: [:inversion, :diminution],
        energy_range: {0.25, 0.38}
      },
      %Motif{
        id: "night_narrow_pulse_1",
        name: "Narrow Pulse",
        scale_degrees: [0, 2, 3, 2, 0],
        rhythm: [1.0, 1.0, 1.0, 1.0, 2.0],
        octave: 0,
        period_affinity: :night,
        transformation_tendency: [:diminution, :inversion],
        energy_range: {0.20, 0.32}
      },
      %Motif{
        id: "night_chromatic_suspension_1",
        name: "Chromatic Suspension",
        scale_degrees: [0, 1, 6, 5, 4, 0],
        rhythm: [1.0, 0.5, 2.0, 1.0, 1.0, 2.5],
        octave: 0,
        period_affinity: :night,
        transformation_tendency: [:inversion, :diminution],
        energy_range: {0.28, 0.40}
      }
    ]
  end
end

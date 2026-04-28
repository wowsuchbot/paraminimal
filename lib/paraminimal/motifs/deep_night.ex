defmodule Paraminimal.Motifs.DeepNight do
  @moduledoc """
  Motifs for the Deep Night period (0-5h).

  Character: still, recursive, minimal.
  Small intervals, chromatic fragments, near-repetitions.
  """

  alias Paraminimal.Composition.Motif

  @spec all() :: [Motif.t()]
  def all do
    [
      %Motif{
        id: "deep_night_chromatic_pulse_1",
        name: "Chromatic Pulse",
        scale_degrees: [0, 1, 0, 1, 0],
        rhythm: [1.0, 0.5, 1.0, 0.5, 2.0],
        octave: 0,
        period_affinity: :deep_night,
        transformation_tendency: [:retrograde, :diminution],
        energy_range: {0.08, 0.18}
      },
      %Motif{
        id: "deep_night_semitone_echo_1",
        name: "Semitone Echo",
        scale_degrees: [0, 1, 2, 1, 0],
        rhythm: [1.5, 1.0, 1.5, 1.0, 2.0],
        octave: -1,
        period_affinity: :deep_night,
        transformation_tendency: [:retrograde, :diminution],
        energy_range: {0.10, 0.22}
      },
      %Motif{
        id: "deep_night_still_cluster_1",
        name: "Still Cluster",
        scale_degrees: [0, 1, 2],
        rhythm: [3.0, 2.0, 4.0],
        octave: 0,
        period_affinity: :deep_night,
        transformation_tendency: [:diminution, :retrograde],
        energy_range: {0.05, 0.15}
      },
      %Motif{
        id: "deep_night_recursive_return_1",
        name: "Recursive Return",
        scale_degrees: [0, 1, 2, 3, 2, 1, 0],
        rhythm: [1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 2.0],
        octave: 0,
        period_affinity: :deep_night,
        transformation_tendency: [:retrograde, :diminution],
        energy_range: {0.12, 0.24}
      }
    ]
  end
end

defmodule Paraminimal.Motifs.Morning do
  @moduledoc """
  Motifs for the Morning period (8-12h).

  Character: bright, active, full.
  Angular leaps, rhythmic variety, complete phrases.
  """

  alias Paraminimal.Composition.Motif

  @spec all() :: [Motif.t()]
  def all do
    [
      %Motif{
        id: "morning_angular_leap_1",
        name: "Angular Leap",
        scale_degrees: [0, 7, 2, 9, 4, 7, 0],
        rhythm: [0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 2.0],
        octave: 0,
        period_affinity: :morning,
        transformation_tendency: [:transposition, :retrograde],
        energy_range: {0.65, 0.80}
      },
      %Motif{
        id: "morning_bright_phrase_1",
        name: "Bright Phrase",
        scale_degrees: [0, 4, 7, 11, 9, 5, 2, 0],
        rhythm: [1.0, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 1.5],
        octave: 1,
        period_affinity: :morning,
        transformation_tendency: [:transposition, :retrograde],
        energy_range: {0.70, 0.90}
      },
      %Motif{
        id: "morning_rhythmic_kick_1",
        name: "Rhythmic Kick",
        scale_degrees: [0, 0, 4, 0, 7, 4, 0],
        rhythm: [0.25, 0.25, 0.5, 0.25, 0.5, 0.5, 1.0],
        octave: 0,
        period_affinity: :morning,
        transformation_tendency: [:retrograde, :transposition],
        energy_range: {0.75, 0.90}
      },
      %Motif{
        id: "morning_complete_arc_1",
        name: "Complete Arc",
        scale_degrees: [0, 4, 7, 11, 14, 11, 7, 4, 0],
        rhythm: [0.5, 0.5, 0.5, 0.5, 1.0, 0.5, 0.5, 0.5, 1.5],
        octave: 0,
        period_affinity: :morning,
        transformation_tendency: [:transposition, :retrograde],
        energy_range: {0.68, 0.85}
      },
      %Motif{
        id: "morning_active_run_1",
        name: "Active Run",
        scale_degrees: [0, 2, 4, 5, 7, 9, 11, 12],
        rhythm: [0.25, 0.25, 0.25, 0.25, 0.25, 0.25, 0.5, 2.0],
        octave: 0,
        period_affinity: :morning,
        transformation_tendency: [:retrograde, :transposition],
        energy_range: {0.72, 0.88}
      }
    ]
  end
end

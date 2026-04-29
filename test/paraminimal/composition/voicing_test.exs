defmodule Paraminimal.Composition.VoicingTest do
  use ExUnit.Case, async: true

  alias Paraminimal.Composition.Voicing

  test "voice_waypoint creates low root/fifth and mid guide tones" do
    voicing =
      Voicing.voice_waypoint(%{
        root: 0,
        root_name: "C",
        scale: :ionian,
        chord_shape: :triad,
        bar: 1,
        weight: 1.0
      })

    assert voicing.low_notes == [36, 55]
    assert Enum.all?(voicing.mid_notes, &(&1 in 48..72))
    assert Enum.any?(voicing.mid_notes, &(Integer.mod(&1, 12) == 4))
    assert Enum.any?(voicing.mid_notes, &(Integer.mod(&1, 12) == 11))
    refute Enum.any?(voicing.notes, &(Integer.mod(&1, 12) == 5))
  end

  test "phrygian flat two is voiced above the root by more than an octave" do
    voicing =
      Voicing.voice_waypoint(%{
        root: 0,
        root_name: "C",
        scale: :phrygian,
        chord_shape: :cluster,
        bar: 1,
        weight: 1.0
      })

    assert Enum.any?(voicing.mid_notes, &(&1 >= 61 and Integer.mod(&1, 12) == 1))
  end

  test "voice_path keeps waypoint order and adds voicing data" do
    path = [
      %{root: 0, root_name: "C", scale: :ionian, chord_shape: :triad, bar: 1, weight: 0.5},
      %{root: 7, root_name: "G", scale: :mixolydian, chord_shape: :seventh, bar: 2, weight: 1.0}
    ]

    voiced = Voicing.voice_path(path)

    assert Enum.map(voiced, & &1.bar) == [1, 2]
    assert Enum.all?(voiced, &match?(%{voicing: %{notes: notes}} when is_list(notes), &1))
  end
end

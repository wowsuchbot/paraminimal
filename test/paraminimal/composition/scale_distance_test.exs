defmodule Paraminimal.Composition.ScaleDistanceTest do
  use ExUnit.Case, async: true

  alias Paraminimal.Composition.Scale
  alias Paraminimal.Composition.ScaleDistance
  alias Paraminimal.Scales.Western

  test "shared tones count pitch-class intersections" do
    c_ionian = Western.get!(:ionian, 0)
    a_aeolian = Western.get!(:aeolian, 9)

    assert ScaleDistance.shared_tones(
             Scale.pitch_classes(c_ionian),
             Scale.pitch_classes(a_aeolian)
           ) == 7
  end

  test "nearby keys are close on the circle of fifths" do
    c_ionian = Western.get!(:ionian, 0)
    g_ionian = Western.get!(:ionian, 7)

    distance = ScaleDistance.between(c_ionian, g_ionian)

    assert distance.shared_tones == 6
    assert distance.circle_fifths_distance == 1
    assert distance.voice_leading_cost == 1
    assert :common_tone in distance.recommended_strategies
  end

  test "tritone-related keys are farther than adjacent keys" do
    c_ionian = Western.get!(:ionian, 0)
    g_ionian = Western.get!(:ionian, 7)
    f_sharp_ionian = Western.get!(:ionian, 6)

    close = ScaleDistance.between(c_ionian, g_ionian)
    far = ScaleDistance.between(c_ionian, f_sharp_ionian)

    assert far.circle_fifths_distance == 6
    assert far.shared_tones < close.shared_tones
    assert :silence_as_arrival in far.recommended_strategies
  end

  test "interval vector similarity recognizes same scale families" do
    c_ionian = Western.get!(:ionian, 0)
    g_ionian = Western.get!(:ionian, 7)

    assert ScaleDistance.between(c_ionian, g_ionian).interval_vector_similarity == 1.0
  end
end

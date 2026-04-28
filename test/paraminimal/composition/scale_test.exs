defmodule Paraminimal.Composition.ScaleTest do
  use ExUnit.Case, async: true

  alias Paraminimal.Composition.Scale
  alias Paraminimal.Scales.Western

  test "western library includes the initial scale families" do
    slugs = Enum.map(Western.all(), & &1.slug)

    assert length(slugs) == 15
    assert :ionian in slugs
    assert :dorian in slugs
    assert :major_pentatonic in slugs
    assert :minor_pentatonic in slugs
    assert :natural_minor in slugs
    assert :harmonic_minor in slugs
    assert :melodic_minor in slugs
  end

  test "scale pitch classes are transposed by root" do
    c_ionian = Western.get!(:ionian, 0)
    g_ionian = Western.get!(:ionian, 7)

    assert Scale.pitch_classes(c_ionian) == [0, 2, 4, 5, 7, 9, 11]
    assert Scale.pitch_classes(g_ionian) == [0, 2, 4, 6, 7, 9, 11]
  end

  test "scale metadata captures musical character" do
    d_dorian = Western.get!(:dorian, 2)

    assert d_dorian.name == "D Dorian"
    assert d_dorian.parent_key == "C major"
    assert :flowing in d_dorian.character_tags
    assert :afternoon in d_dorian.period_affinity
  end
end

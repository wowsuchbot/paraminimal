defmodule Paraminimal.Composition.ChordVocabularyTest do
  use ExUnit.Case, async: true

  alias Paraminimal.Composition.ChordVocabulary
  alias Paraminimal.Scales.Western

  test "scale masks encode interval membership deterministically" do
    ionian = ChordVocabulary.get!(:ionian)

    assert ionian.scale_mask == ChordVocabulary.scale_mask([0, 2, 4, 5, 7, 9, 11])
    assert Bitwise.band(ionian.scale_mask, Bitwise.bsl(1, 4)) > 0
    assert Bitwise.band(ionian.scale_mask, Bitwise.bsl(1, 1)) == 0
  end

  test "vocabularies expose characteristic and avoid-note metadata" do
    ionian = ChordVocabulary.get!(:ionian)
    lydian = ChordVocabulary.get!(:lydian)

    assert ChordVocabulary.avoid_interval?(ionian, 5)
    refute ChordVocabulary.avoid_interval?(lydian, 6)
    assert lydian.characteristic_intervals == [6]
    assert :include_sharp_four_high in lydian.constraints
  end

  test "all Western scale slugs have chord vocabularies" do
    slugs = Western.all() |> Enum.map(& &1.slug)

    assert Enum.all?(slugs, fn slug ->
             slug in ChordVocabulary.known_scales()
           end)
  end
end

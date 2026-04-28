defmodule Paraminimal.Composition.MotifEngineTest do
  use ExUnit.Case, async: true

  alias Paraminimal.Composition.Motif
  alias Paraminimal.Composition.MotifEngine
  alias Paraminimal.Composition.TransformedMotif

  # A simple test motif: ascending pentatonic fragment
  setup do
    motif = %Motif{
      id: "test_ascending",
      name: "Test Ascending",
      scale_degrees: [0, 2, 4, 5, 7],
      rhythm: [1.0, 0.5, 0.5, 1.0, 2.0],
      octave: 0,
      period_affinity: :morning,
      transformation_tendency: [:transposition, :retrograde],
      energy_range: {0.5, 0.9}
    }

    %{motif: motif}
  end

  describe "retrograde/1" do
    test "reverses scale_degrees and rhythm", %{motif: motif} do
      tm = MotifEngine.retrograde(motif)

      assert tm.scale_degrees == [7, 5, 4, 2, 0]
      assert tm.rhythm == [2.0, 1.0, 0.5, 0.5, 1.0]
    end

    test "records retrograde in lineage", %{motif: motif} do
      tm = MotifEngine.retrograde(motif)

      assert tm.source_id == "test_ascending"
      assert tm.transformations == [{:retrograde, nil}]
    end
  end

  describe "inversion/1" do
    test "mirrors intervals around the first note", %{motif: motif} do
      tm = MotifEngine.inversion(motif)

      # [0, 2, 4, 5, 7] → pivot=0, intervals: +2,+2,+1,+2 → flip: -2,-2,-1,-2
      # [0, 0-2, -2-2, -4-1, -5-2] = [0, -2, -4, -5, -7]
      assert tm.scale_degrees == [0, -2, -4, -5, -7]
      assert tm.rhythm == motif.rhythm
    end

    test "records inversion in lineage", %{motif: motif} do
      tm = MotifEngine.inversion(motif)

      assert tm.transformations == [{:inversion, nil}]
    end
  end

  describe "augmentation/1" do
    test "doubles all rhythm values", %{motif: motif} do
      tm = MotifEngine.augmentation(motif)

      assert tm.rhythm == [2.0, 1.0, 1.0, 2.0, 4.0]
      assert tm.scale_degrees == motif.scale_degrees
    end
  end

  describe "diminution/1" do
    test "halves all rhythm values", %{motif: motif} do
      tm = MotifEngine.diminution(motif)

      assert tm.rhythm == [0.5, 0.25, 0.25, 0.5, 1.0]
      assert tm.scale_degrees == motif.scale_degrees
    end
  end

  describe "transposition/2" do
    test "shifts all scale_degrees by offset", %{motif: motif} do
      tm = MotifEngine.transposition(motif, 3)

      assert tm.scale_degrees == [3, 5, 7, 8, 10]
      assert tm.rhythm == motif.rhythm
    end

    test "handles negative offset", %{motif: motif} do
      tm = MotifEngine.transposition(motif, -2)

      assert tm.scale_degrees == [-2, 0, 2, 3, 5]
    end

    test "records offset in lineage", %{motif: motif} do
      tm = MotifEngine.transposition(motif, 5)

      assert tm.transformations == [{:transposition, 5}]
    end
  end

  describe "additive_permutation/2" do
    test "rotates rhythm by N positions", %{motif: motif} do
      tm = MotifEngine.additive_permutation(motif, 2)

      # [1.0, 0.5, 0.5, 1.0, 2.0] rotate by 2 → [0.5, 1.0, 2.0, 1.0, 0.5]
      assert tm.rhythm == [0.5, 1.0, 2.0, 1.0, 0.5]
      assert tm.scale_degrees == motif.scale_degrees
    end

    test "wraps rotation with modulo", %{motif: motif} do
      tm = MotifEngine.additive_permutation(motif, 7)

      # 7 mod 5 = 2, same as rotation by 2
      assert tm.rhythm == [0.5, 1.0, 2.0, 1.0, 0.5]
    end

    test "records n in lineage", %{motif: motif} do
      tm = MotifEngine.additive_permutation(motif, 3)

      assert tm.transformations == [{:additive_permutation, 3}]
    end
  end

  describe "apply_chain/2" do
    test "composes retrograde then inversion", %{motif: motif} do
      # Apply separately
      step1 = MotifEngine.retrograde(motif)
      step1_degrees = step1.scale_degrees
      # Create fresh from step1's degrees for manual inversion
      manual_tm = %TransformedMotif{
        source_id: motif.id,
        transformations: [],
        scale_degrees: step1_degrees,
        rhythm: step1.rhythm,
        octave: 0
      }

      manual_result = MotifEngine.inversion(manual_tm)

      # Apply via chain
      chained = MotifEngine.apply_chain(motif, [{:retrograde, nil}, {:inversion, nil}])

      assert chained.scale_degrees == manual_result.scale_degrees
      assert chained.rhythm == manual_result.rhythm
    end

    test "records full transformation lineage", %{motif: motif} do
      tm = MotifEngine.apply_chain(motif, [{:retrograde, nil}, {:transposition, 2}])

      assert tm.source_id == "test_ascending"
      assert tm.transformations == [{:retrograde, nil}, {:transposition, 2}]
      assert tm.scale_degrees == [9, 7, 6, 4, 2]
    end

    test "accepts atom-only operations without args", %{motif: motif} do
      tm = MotifEngine.apply_chain(motif, [:retrograde])

      assert tm.scale_degrees == [7, 5, 4, 2, 0]
      assert tm.transformations == [{:retrograde, nil}]
    end

    test "raises for atom-only operations that need args" do
      motif = %Motif{
        id: "test",
        name: "Test",
        scale_degrees: [0, 2],
        rhythm: [1.0, 1.0],
        octave: 0,
        period_affinity: :morning,
        transformation_tendency: [],
        energy_range: {0.0, 1.0}
      }

      assert_raise ArgumentError, ~r/requires an argument/, fn ->
        MotifEngine.apply_chain(motif, [:transposition])
      end
    end

    test "preserves octave through transformations", %{motif: motif} do
      tm = MotifEngine.apply_chain(motif, [{:retrograde, nil}, {:augmentation, nil}])

      assert tm.octave == motif.octave
    end
  end
end

defmodule Paraminimal.MotifsTest do
  use ExUnit.Case, async: true

  alias Paraminimal.Composition.Motif
  alias Paraminimal.Motifs

  @periods ~w(deep_night dawn morning afternoon twilight night)a

  describe "for_period/1" do
    test "each period has 3-5 motifs" do
      for period <- @periods do
        motifs = Motifs.for_period(period)
        count = length(motifs)

        assert count >= 3 and count <= 5,
               "#{period} has #{count} motifs, expected 3-5"
      end
    end

    test "returns motifs with matching period_affinity" do
      for period <- @periods do
        motifs = Motifs.for_period(period)

        for motif <- motifs do
          assert motif.period_affinity == period,
                 "motif #{motif.id} has period_affinity #{motif.period_affinity}, expected #{period}"
        end
      end
    end
  end

  describe "motif validation" do
    test "all motifs have valid scale_degrees (integers)" do
      for motif <- Motifs.all() do
        for degree <- motif.scale_degrees do
          assert is_integer(degree),
                 "motif #{motif.id} has non-integer scale_degree: #{inspect(degree)}"
        end
      end
    end

    test "all motifs have valid rhythm (positive floats)" do
      for motif <- Motifs.all() do
        for dur <- motif.rhythm do
          assert is_float(dur) or is_integer(dur),
                 "motif #{motif.id} has non-numeric rhythm value: #{inspect(dur)}"

          assert dur > 0,
                 "motif #{motif.id} has non-positive rhythm value: #{inspect(dur)}"
        end
      end
    end

    test "all motifs have matching length for degrees and rhythm" do
      for motif <- Motifs.all() do
        assert length(motif.scale_degrees) == length(motif.rhythm),
               "motif #{motif.id} has #{length(motif.scale_degrees)} degrees but #{length(motif.rhythm)} rhythm values"
      end
    end

    test "all motifs have non-empty transformation_tendency" do
      for motif <- Motifs.all() do
        assert length(motif.transformation_tendency) > 0,
               "motif #{motif.id} has empty transformation_tendency"
      end
    end

    test "all motifs have valid energy_range tuples" do
      for motif <- Motifs.all() do
        {lo, hi} = motif.energy_range

        assert is_float(lo) and is_float(hi),
               "motif #{motif.id} has invalid energy_range: #{inspect(motif.energy_range)}"

        assert lo < hi,
               "motif #{motif.id} energy_range low >= high: #{inspect(motif.energy_range)}"
      end
    end
  end

  describe "by_id/1" do
    test "finds a specific motif by id" do
      assert %Motif{id: "dawn_rising_fourths_1"} = Motifs.by_id("dawn_rising_fourths_1")
    end

    test "returns nil for unknown id" do
      assert Motifs.by_id("nonexistent_motif") == nil
    end
  end

  describe "all/0" do
    test "returns motifs from all periods" do
      all_motifs = Motifs.all()
      periods = all_motifs |> Enum.map(& &1.period_affinity) |> Enum.uniq() |> Enum.sort()

      assert periods == Enum.sort(@periods)
    end
  end

  describe "period_keys/0" do
    test "returns all six period keys" do
      keys = Motifs.period_keys()
      assert length(keys) == 6

      for period <- @periods do
        assert period in keys
      end
    end
  end
end

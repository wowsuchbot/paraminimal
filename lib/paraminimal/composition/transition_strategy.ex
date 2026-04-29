defmodule Paraminimal.Composition.TransitionStrategy do
  @moduledoc """
  Chooses deterministic strategies for composed transitions.

  A strategy is a musical intent, not a fixed audio algorithm. The transition
  planner turns these strategy names into path data that the browser can later
  render through SuperSonic.
  """

  alias Paraminimal.Composition.ScaleDistance

  @type strategy ::
          :stable_sustain
          | :common_tone_sustention
          | :melodic_migration
          | :voice_leading_migration
          | :progressive_chord_change
          | :rhythmic_dissolution
          | :rhythmic_fill
          | :register_collapse
          | :silence_as_arrival

  @doc "Selects strategy names from musical distance and energy/density deltas."
  @spec select(ScaleDistance.t(), float(), float()) :: [strategy()]
  def select(%ScaleDistance{} = distance, energy_delta, density_delta) do
    distance
    |> base_strategies()
    |> add_density_strategy(density_delta)
    |> add_energy_strategy(energy_delta)
    |> Enum.uniq()
  end

  defp base_strategies(%ScaleDistance{shared_ratio: shared_ratio, voice_leading_cost: cost})
       when shared_ratio >= 0.65 and cost <= 6 do
    [:common_tone_sustention, :progressive_chord_change, :melodic_migration]
  end

  defp base_strategies(%ScaleDistance{shared_ratio: shared_ratio, voice_leading_cost: cost})
       when shared_ratio >= 0.4 and cost <= 10 do
    [:voice_leading_migration, :progressive_chord_change, :melodic_migration]
  end

  defp base_strategies(_distance) do
    [:silence_as_arrival, :register_collapse, :rhythmic_fill]
  end

  defp add_density_strategy(strategies, density_delta) when density_delta <= -0.2,
    do: strategies ++ [:rhythmic_dissolution]

  defp add_density_strategy(strategies, density_delta) when density_delta >= 0.2,
    do: strategies ++ [:rhythmic_fill]

  defp add_density_strategy(strategies, _density_delta), do: strategies

  defp add_energy_strategy(strategies, energy_delta) when energy_delta <= -0.25,
    do: strategies ++ [:silence_as_arrival]

  defp add_energy_strategy(strategies, _energy_delta), do: strategies
end

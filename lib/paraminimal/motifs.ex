defmodule Paraminimal.Motifs do
  @moduledoc """
  Registry for motif definitions, organized by time period.

  Each period module returns 3-5 motifs that define the melodic
  character of that time of day. This module provides lookup by
  period key or individual motif id.
  """

  alias Paraminimal.Composition.Motif

  @period_modules %{
    deep_night: Paraminimal.Motifs.DeepNight,
    dawn: Paraminimal.Motifs.Dawn,
    morning: Paraminimal.Motifs.Morning,
    afternoon: Paraminimal.Motifs.Afternoon,
    twilight: Paraminimal.Motifs.Twilight,
    night: Paraminimal.Motifs.Night
  }

  @doc "Returns all motifs across all periods."
  @spec all() :: [Motif.t()]
  def all do
    @period_modules
    |> Map.values()
    |> Enum.flat_map(& &1.all())
  end

  @doc "Returns all motifs for a given period."
  @spec for_period(atom()) :: [Motif.t()]
  def for_period(period_key) when is_atom(period_key) do
    module = Map.fetch!(@period_modules, period_key)
    module.all()
  end

  @doc "Returns a single motif by its id."
  @spec by_id(String.t()) :: Motif.t() | nil
  def by_id(id) when is_binary(id) do
    Enum.find(all(), &(&1.id == id))
  end

  @doc "Returns the list of all period keys."
  @spec period_keys() :: [atom()]
  def period_keys, do: Map.keys(@period_modules)
end

defmodule Paraminimal.Composer do
  @moduledoc """
  DB-backed authoring context for the `/compose` miniapp.
  """

  import Ecto.Query, warn: false
  alias Paraminimal.Repo

  alias Paraminimal.Composer.ChordProfile
  alias Paraminimal.Composer.InstrumentRule
  alias Paraminimal.Composer.Motif
  alias Paraminimal.Composer.Phrase
  alias Paraminimal.Composer.TransitionRecipe

  def list_motifs, do: Repo.all(from m in Motif, order_by: [asc: m.name])
  def list_phrases, do: Repo.all(from p in Phrase, order_by: [asc: p.name])
  def list_transition_recipes, do: Repo.all(from r in TransitionRecipe, order_by: [asc: r.name])
  def list_instrument_rules, do: Repo.all(from r in InstrumentRule, order_by: [asc: r.name])
  def list_chord_profiles, do: Repo.all(from c in ChordProfile, order_by: [asc: c.name])

  def get_motif!(id), do: Repo.get!(Motif, id)
  def get_phrase!(id), do: Repo.get!(Phrase, id)
  def get_transition_recipe!(id), do: Repo.get!(TransitionRecipe, id)
  def get_instrument_rule!(id), do: Repo.get!(InstrumentRule, id)
  def get_chord_profile!(id), do: Repo.get!(ChordProfile, id)

  def change_motif(%Motif{} = motif, attrs \\ %{}), do: Motif.changeset(motif, attrs)
  def change_phrase(%Phrase{} = phrase, attrs \\ %{}), do: Phrase.changeset(phrase, attrs)

  def change_transition_recipe(%TransitionRecipe{} = recipe, attrs \\ %{}),
    do: TransitionRecipe.changeset(recipe, attrs)

  def change_instrument_rule(%InstrumentRule{} = rule, attrs \\ %{}),
    do: InstrumentRule.changeset(rule, attrs)

  def change_chord_profile(%ChordProfile{} = profile, attrs \\ %{}),
    do: ChordProfile.changeset(profile, attrs)

  def save_motif(%Motif{} = motif, attrs),
    do: motif |> Motif.changeset(attrs) |> Repo.insert_or_update()

  def save_phrase(%Phrase{} = phrase, attrs),
    do: phrase |> Phrase.changeset(attrs) |> Repo.insert_or_update()

  def save_transition_recipe(%TransitionRecipe{} = recipe, attrs),
    do: recipe |> TransitionRecipe.changeset(attrs) |> Repo.insert_or_update()

  def save_instrument_rule(%InstrumentRule{} = rule, attrs),
    do: rule |> InstrumentRule.changeset(attrs) |> Repo.insert_or_update()

  def save_chord_profile(%ChordProfile{} = profile, attrs),
    do: profile |> ChordProfile.changeset(attrs) |> Repo.insert_or_update()

  def clone_transition_recipe!(id) do
    recipe = get_transition_recipe!(id)

    attrs =
      recipe
      |> Map.from_struct()
      |> Map.drop([:__meta__, :id, :inserted_at, :updated_at])
      |> Map.update!(:slug, &"#{&1}-v#{recipe.version + 1}")
      |> Map.update!(:name, &"#{&1} (copy)")
      |> Map.update!(:version, &(&1 + 1))
      |> Map.put(:status, "draft")

    %TransitionRecipe{} |> TransitionRecipe.changeset(attrs) |> Repo.insert!()
  end
end

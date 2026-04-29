defmodule Paraminimal.ComposerTest do
  use Paraminimal.DataCase, async: true

  alias Paraminimal.Composer
  alias Paraminimal.Composer.Motif
  alias Paraminimal.Composer.TransitionRecipe

  test "motif changeset validates energy band ordering" do
    changeset =
      Motif.changeset(%Motif{}, %{
        name: "Bad motif",
        slug: "bad-motif",
        status: "draft",
        period_affinity: "morning",
        energy_min: 0.9,
        energy_max: 0.2
      })

    refute changeset.valid?
    assert "must be greater than or equal to energy_min" in errors_on(changeset).energy_max
  end

  test "transition recipe requires key fields" do
    changeset = TransitionRecipe.changeset(%TransitionRecipe{}, %{})
    refute changeset.valid?
    assert "can't be blank" in errors_on(changeset).name
    assert "can't be blank" in errors_on(changeset).slug
  end

  test "save and list transition recipe" do
    attrs = %{
      "name" => "Pivot Path",
      "slug" => "pivot-path",
      "status" => "draft",
      "from_period" => "morning",
      "to_period" => "afternoon",
      "path_technique" => "pivot_modulation",
      "arrival_gesture" => "authentic_cadence"
    }

    assert {:ok, recipe} = Composer.save_transition_recipe(%TransitionRecipe{}, attrs)
    assert recipe.slug == "pivot-path"
    assert Enum.any?(Composer.list_transition_recipes(), &(&1.id == recipe.id))
  end
end

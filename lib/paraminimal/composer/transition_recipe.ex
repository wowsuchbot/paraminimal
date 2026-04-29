defmodule Paraminimal.Composer.TransitionRecipe do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(draft published archived)
  @periods ~w(deep_night dawn morning afternoon twilight night)

  schema "composer_transition_recipes" do
    field :name, :string
    field :slug, :string
    field :status, :string, default: "draft"
    field :version, :integer, default: 1
    field :from_period, :string, default: "morning"
    field :to_period, :string, default: "afternoon"
    field :energy_band, :string, default: "mid"
    field :density_band, :string, default: "mid"
    field :distance_class, :string, default: "near"
    field :path_technique, :string, default: "voice_leading_migration"
    field :arrival_gesture, :string, default: "modal_arrival"
    field :harmonic_route_roles, {:array, :string}, default: []
    field :melodic_guide_behavior, :string, default: "nearest"
    field :max_leap, :integer, default: 4
    field :forbidden_colors, {:array, :string}, default: []
    field :avoid_moves, {:array, :string}, default: []
    field :feel_notes, :string, default: ""
    field :controls_json, :map, default: %{}
    field :metadata_json, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(recipe, attrs) do
    recipe
    |> cast(attrs, [
      :name,
      :slug,
      :status,
      :version,
      :from_period,
      :to_period,
      :energy_band,
      :density_band,
      :distance_class,
      :path_technique,
      :arrival_gesture,
      :harmonic_route_roles,
      :melodic_guide_behavior,
      :max_leap,
      :forbidden_colors,
      :avoid_moves,
      :feel_notes,
      :controls_json,
      :metadata_json
    ])
    |> validate_required([
      :name,
      :slug,
      :status,
      :from_period,
      :to_period,
      :path_technique,
      :arrival_gesture
    ])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:from_period, @periods)
    |> validate_inclusion(:to_period, @periods)
    |> validate_number(:version, greater_than: 0)
    |> validate_number(:max_leap, greater_than: 0, less_than_or_equal_to: 24)
    |> unique_constraint(:slug)
  end
end

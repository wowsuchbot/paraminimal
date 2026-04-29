defmodule Paraminimal.Composer.ChordProfile do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(draft published archived)

  schema "composer_chord_profiles" do
    field :name, :string
    field :slug, :string
    field :status, :string, default: "draft"
    field :version, :integer, default: 1
    field :scale_slug, :string, default: "ionian"
    field :characteristic_tones, {:array, :integer}, default: []
    field :avoid_tones, {:array, :integer}, default: []
    field :chord_roles, :map, default: %{}
    field :arrival_options, {:array, :string}, default: []
    field :feel_notes, :string, default: ""
    field :controls_json, :map, default: %{}
    field :metadata_json, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [
      :name,
      :slug,
      :status,
      :version,
      :scale_slug,
      :characteristic_tones,
      :avoid_tones,
      :chord_roles,
      :arrival_options,
      :feel_notes,
      :controls_json,
      :metadata_json
    ])
    |> validate_required([:name, :slug, :status, :scale_slug])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:version, greater_than: 0)
    |> unique_constraint(:slug)
  end
end

defmodule Paraminimal.Composer.Motif do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(draft published archived)
  @periods ~w(deep_night dawn morning afternoon twilight night)

  schema "composer_motifs" do
    field :name, :string
    field :slug, :string
    field :status, :string, default: "draft"
    field :version, :integer, default: 1
    field :period_affinity, :string, default: "morning"
    field :energy_min, :float, default: 0.2
    field :energy_max, :float, default: 0.8
    field :feel_notes, :string, default: ""
    field :degrees, {:array, :integer}, default: []
    field :rhythm, {:array, :float}, default: []
    field :contour_hints, {:array, :string}, default: []
    field :controls_json, :map, default: %{}
    field :metadata_json, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(motif, attrs) do
    motif
    |> cast(attrs, [
      :name,
      :slug,
      :status,
      :version,
      :period_affinity,
      :energy_min,
      :energy_max,
      :feel_notes,
      :degrees,
      :rhythm,
      :contour_hints,
      :controls_json,
      :metadata_json
    ])
    |> validate_required([:name, :slug, :status, :period_affinity, :energy_min, :energy_max])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:period_affinity, @periods)
    |> validate_number(:version, greater_than: 0)
    |> validate_number(:energy_min, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
    |> validate_number(:energy_max, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
    |> validate_energy_range()
    |> unique_constraint(:slug)
  end

  defp validate_energy_range(changeset) do
    min = get_field(changeset, :energy_min) || 0.0
    max = get_field(changeset, :energy_max) || 0.0

    if max < min do
      add_error(changeset, :energy_max, "must be greater than or equal to energy_min")
    else
      changeset
    end
  end
end

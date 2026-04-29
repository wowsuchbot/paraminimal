defmodule Paraminimal.Composer.Phrase do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(draft published archived)

  schema "composer_phrases" do
    field :name, :string
    field :slug, :string
    field :status, :string, default: "draft"
    field :version, :integer, default: 1
    field :bars, :integer, default: 4
    field :role_sequence, {:array, :string}, default: []
    field :guide_tone_anchors, {:array, :integer}, default: []
    field :feel_notes, :string, default: ""
    field :controls_json, :map, default: %{}
    field :metadata_json, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(phrase, attrs) do
    phrase
    |> cast(attrs, [
      :name,
      :slug,
      :status,
      :version,
      :bars,
      :role_sequence,
      :guide_tone_anchors,
      :feel_notes,
      :controls_json,
      :metadata_json
    ])
    |> validate_required([:name, :slug, :status, :bars])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:version, greater_than: 0)
    |> validate_number(:bars, greater_than: 0, less_than_or_equal_to: 32)
    |> unique_constraint(:slug)
  end
end

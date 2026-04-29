defmodule Paraminimal.Composer.InstrumentRule do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(draft published archived)
  @layers ~w(drone motif texture percussion)

  schema "composer_instrument_rules" do
    field :name, :string
    field :slug, :string
    field :status, :string, default: "draft"
    field :version, :integer, default: 1
    field :layer, :string, default: "drone"
    field :register_policy, :string, default: "mid"
    field :note_limit, :integer, default: 3
    field :articulation, :string, default: "legato"
    field :release_ms, :integer, default: 300
    field :gesture_overrides, :map, default: %{}
    field :feel_notes, :string, default: ""
    field :controls_json, :map, default: %{}
    field :metadata_json, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(rule, attrs) do
    rule
    |> cast(attrs, [
      :name,
      :slug,
      :status,
      :version,
      :layer,
      :register_policy,
      :note_limit,
      :articulation,
      :release_ms,
      :gesture_overrides,
      :feel_notes,
      :controls_json,
      :metadata_json
    ])
    |> validate_required([:name, :slug, :status, :layer, :note_limit])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:layer, @layers)
    |> validate_number(:version, greater_than: 0)
    |> validate_number(:note_limit, greater_than: 0, less_than_or_equal_to: 16)
    |> validate_number(:release_ms, greater_than_or_equal_to: 10, less_than_or_equal_to: 10_000)
    |> unique_constraint(:slug)
  end
end

defmodule Paraminimal.Repo.Migrations.CreateComposerAuthoringTables do
  use Ecto.Migration

  def change do
    create table(:composer_motifs) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :status, :string, null: false, default: "draft"
      add :version, :integer, null: false, default: 1
      add :period_affinity, :string, null: false, default: "morning"
      add :energy_min, :float, null: false, default: 0.2
      add :energy_max, :float, null: false, default: 0.8
      add :feel_notes, :text, null: false, default: ""
      add :degrees, {:array, :integer}, null: false, default: []
      add :rhythm, {:array, :float}, null: false, default: []
      add :contour_hints, {:array, :string}, null: false, default: []
      add :controls_json, :map, null: false, default: %{}
      add :metadata_json, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:composer_motifs, [:slug])
    create index(:composer_motifs, [:status, :period_affinity])

    create table(:composer_phrases) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :status, :string, null: false, default: "draft"
      add :version, :integer, null: false, default: 1
      add :bars, :integer, null: false, default: 4
      add :role_sequence, {:array, :string}, null: false, default: []
      add :guide_tone_anchors, {:array, :integer}, null: false, default: []
      add :feel_notes, :text, null: false, default: ""
      add :controls_json, :map, null: false, default: %{}
      add :metadata_json, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:composer_phrases, [:slug])
    create index(:composer_phrases, [:status])

    create table(:composer_transition_recipes) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :status, :string, null: false, default: "draft"
      add :version, :integer, null: false, default: 1
      add :from_period, :string, null: false, default: "morning"
      add :to_period, :string, null: false, default: "afternoon"
      add :energy_band, :string, null: false, default: "mid"
      add :density_band, :string, null: false, default: "mid"
      add :distance_class, :string, null: false, default: "near"
      add :path_technique, :string, null: false, default: "voice_leading_migration"
      add :arrival_gesture, :string, null: false, default: "modal_arrival"
      add :harmonic_route_roles, {:array, :string}, null: false, default: []
      add :melodic_guide_behavior, :string, null: false, default: "nearest"
      add :max_leap, :integer, null: false, default: 4
      add :forbidden_colors, {:array, :string}, null: false, default: []
      add :avoid_moves, {:array, :string}, null: false, default: []
      add :feel_notes, :text, null: false, default: ""
      add :controls_json, :map, null: false, default: %{}
      add :metadata_json, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:composer_transition_recipes, [:slug])
    create index(:composer_transition_recipes, [:status, :from_period, :to_period])

    create table(:composer_instrument_rules) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :status, :string, null: false, default: "draft"
      add :version, :integer, null: false, default: 1
      add :layer, :string, null: false, default: "drone"
      add :register_policy, :string, null: false, default: "mid"
      add :note_limit, :integer, null: false, default: 3
      add :articulation, :string, null: false, default: "legato"
      add :release_ms, :integer, null: false, default: 300
      add :gesture_overrides, :map, null: false, default: %{}
      add :feel_notes, :text, null: false, default: ""
      add :controls_json, :map, null: false, default: %{}
      add :metadata_json, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:composer_instrument_rules, [:slug])
    create index(:composer_instrument_rules, [:status, :layer])

    create table(:composer_chord_profiles) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :status, :string, null: false, default: "draft"
      add :version, :integer, null: false, default: 1
      add :scale_slug, :string, null: false, default: "ionian"
      add :characteristic_tones, {:array, :integer}, null: false, default: []
      add :avoid_tones, {:array, :integer}, null: false, default: []
      add :chord_roles, :map, null: false, default: %{}
      add :arrival_options, {:array, :string}, null: false, default: []
      add :feel_notes, :text, null: false, default: ""
      add :controls_json, :map, null: false, default: %{}
      add :metadata_json, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:composer_chord_profiles, [:slug])
    create index(:composer_chord_profiles, [:status, :scale_slug])
  end
end

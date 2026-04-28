defmodule Paraminimal.Scales.Western do
  @moduledoc """
  Initial Western scale library for the composition engine.
  """

  alias Paraminimal.Composition.Scale

  @definitions %{
    ionian: %{
      name: "Ionian",
      intervals: [0, 2, 4, 5, 7, 9, 11],
      mode_number: 1,
      character_tags: [:major, :bright, :stable],
      energy_range: {0.5, 0.9},
      typical_register: {52, 76},
      period_affinity: [:morning]
    },
    dorian: %{
      name: "Dorian",
      intervals: [0, 2, 3, 5, 7, 9, 10],
      mode_number: 2,
      character_tags: [:minor, :bright, :flowing],
      energy_range: {0.3, 0.7},
      typical_register: {48, 72},
      period_affinity: [:afternoon, :twilight]
    },
    phrygian: %{
      name: "Phrygian",
      intervals: [0, 1, 3, 5, 7, 8, 10],
      mode_number: 3,
      character_tags: [:minor, :dark, :tense],
      energy_range: {0.2, 0.6},
      typical_register: {40, 67},
      period_affinity: [:night]
    },
    lydian: %{
      name: "Lydian",
      intervals: [0, 2, 4, 6, 7, 9, 11],
      mode_number: 4,
      character_tags: [:major, :luminous, :floating],
      energy_range: {0.2, 0.6},
      typical_register: {55, 79},
      period_affinity: [:dawn]
    },
    mixolydian: %{
      name: "Mixolydian",
      intervals: [0, 2, 4, 5, 7, 9, 10],
      mode_number: 5,
      character_tags: [:major, :open, :active],
      energy_range: {0.5, 0.9},
      typical_register: {50, 74},
      period_affinity: [:morning]
    },
    aeolian: %{
      name: "Aeolian",
      intervals: [0, 2, 3, 5, 7, 8, 10],
      mode_number: 6,
      character_tags: [:minor, :wistful, :falling],
      energy_range: {0.2, 0.6},
      typical_register: {45, 69},
      period_affinity: [:twilight]
    },
    locrian: %{
      name: "Locrian",
      intervals: [0, 1, 3, 5, 6, 8, 10],
      mode_number: 7,
      character_tags: [:diminished, :unstable, :dark],
      energy_range: {0.1, 0.4},
      typical_register: {38, 64},
      period_affinity: [:deep_night, :night]
    },
    major_pentatonic: %{
      name: "Major Pentatonic",
      intervals: [0, 2, 4, 7, 9],
      mode_number: nil,
      character_tags: [:major, :open, :simple],
      energy_range: {0.3, 0.8},
      typical_register: {52, 76},
      period_affinity: [:dawn, :afternoon]
    },
    minor_pentatonic: %{
      name: "Minor Pentatonic",
      intervals: [0, 3, 5, 7, 10],
      mode_number: nil,
      character_tags: [:minor, :earthy, :sparse],
      energy_range: {0.2, 0.6},
      typical_register: {43, 70},
      period_affinity: [:deep_night, :night]
    },
    natural_minor: %{
      name: "Natural Minor",
      intervals: [0, 2, 3, 5, 7, 8, 10],
      mode_number: nil,
      character_tags: [:minor, :wistful, :stable],
      energy_range: {0.2, 0.6},
      typical_register: {45, 69},
      period_affinity: [:twilight, :night]
    },
    harmonic_minor: %{
      name: "Harmonic Minor",
      intervals: [0, 2, 3, 5, 7, 8, 11],
      mode_number: nil,
      character_tags: [:minor, :tense, :ornate],
      energy_range: {0.3, 0.7},
      typical_register: {45, 72},
      period_affinity: [:twilight]
    },
    melodic_minor: %{
      name: "Melodic Minor",
      intervals: [0, 2, 3, 5, 7, 9, 11],
      mode_number: nil,
      character_tags: [:minor, :bright, :ascending],
      energy_range: {0.4, 0.8},
      typical_register: {48, 74},
      period_affinity: [:afternoon, :twilight]
    },
    diminished: %{
      name: "Diminished",
      intervals: [0, 2, 3, 5, 6, 8, 9, 11],
      mode_number: nil,
      character_tags: [:diminished, :recursive, :unstable],
      energy_range: {0.1, 0.5},
      typical_register: {36, 67},
      period_affinity: [:deep_night]
    },
    whole_tone: %{
      name: "Whole Tone",
      intervals: [0, 2, 4, 6, 8, 10],
      mode_number: nil,
      character_tags: [:floating, :ambiguous, :symmetric],
      energy_range: {0.2, 0.5},
      typical_register: {50, 78},
      period_affinity: [:deep_night, :dawn]
    },
    chromatic: %{
      name: "Chromatic",
      intervals: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
      mode_number: nil,
      character_tags: [:chromatic, :recursive, :dense],
      energy_range: {0.1, 0.5},
      typical_register: {36, 72},
      period_affinity: [:deep_night]
    }
  }

  @doc "Returns all scale definitions for C as the default root."
  @spec all() :: [Scale.t()]
  def all do
    @definitions
    |> Map.keys()
    |> Enum.sort()
    |> Enum.map(&get!/1)
  end

  @doc "Returns a named scale for the given root pitch class."
  @spec get!(atom(), Scale.pitch_class()) :: Scale.t()
  def get!(slug, root \\ 0) when is_atom(slug) and root in 0..11 do
    definition = Map.fetch!(@definitions, slug)
    root_name = Scale.note_name(root)

    %Scale{
      slug: slug,
      name: "#{root_name} #{definition.name}",
      root: root,
      root_name: root_name,
      intervals: definition.intervals,
      mode_number: definition.mode_number,
      parent_key: parent_key(root, definition.mode_number),
      character_tags: definition.character_tags,
      energy_range: definition.energy_range,
      typical_register: definition.typical_register,
      period_affinity: definition.period_affinity
    }
  end

  defp parent_key(_root, nil), do: nil

  defp parent_key(root, mode_number) do
    parent_root =
      root
      |> Kernel.-(Enum.at([0, 2, 4, 5, 7, 9, 11], mode_number - 1))
      |> Integer.mod(12)

    "#{Scale.note_name(parent_root)} major"
  end
end

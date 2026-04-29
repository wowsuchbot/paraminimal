defmodule Paraminimal.Composition.Voicing do
  @moduledoc """
  Deterministic voicing pass for transition waypoints.

  Path planning chooses the musical route first. This module turns a waypoint
  into concrete MIDI notes using modal vocabulary, register constraints, and a
  small amount of voice-leading against the previous voicing.
  """

  alias Paraminimal.Composition.ChordVocabulary

  @low_root_min 36
  @low_root_max 47
  @mid_min 48
  @mid_max 72

  @type voiced_chord :: %{
          role: atom(),
          vocabulary: atom(),
          notes: [integer()],
          low_notes: [integer()],
          mid_notes: [integer()],
          pitch_classes: [integer()],
          avoided_intervals: [integer()]
        }

  @doc "Voices a harmonic waypoint into concrete MIDI notes."
  @spec voice_waypoint(map(), [integer()] | nil) :: voiced_chord()
  def voice_waypoint(waypoint, previous_notes \\ nil) do
    vocabulary = ChordVocabulary.get!(Map.fetch!(waypoint, :scale))
    role = waypoint |> Map.get(:chord_shape, :triad) |> ChordVocabulary.role_for_shape()

    intervals =
      vocabulary |> ChordVocabulary.chord_intervals(role) |> stable_intervals(vocabulary)

    root = Map.fetch!(waypoint, :root)

    low_notes = low_notes(root)
    mid_notes = mid_notes(root, intervals, vocabulary, previous_notes)
    notes = Enum.sort(low_notes ++ mid_notes)

    %{
      role: role,
      vocabulary: vocabulary.scale,
      notes: notes,
      low_notes: low_notes,
      mid_notes: mid_notes,
      pitch_classes: notes |> Enum.map(&Integer.mod(&1, 12)) |> Enum.uniq() |> Enum.sort(),
      avoided_intervals: vocabulary.avoid_intervals
    }
  end

  @doc "Adds voiced chords to each waypoint in order."
  @spec voice_path([map()]) :: [map()]
  def voice_path(path) when is_list(path) do
    {voiced_path, _previous} =
      Enum.map_reduce(path, nil, fn waypoint, previous ->
        voiced = voice_waypoint(waypoint, previous)
        {Map.put(waypoint, :voicing, voiced), voiced.notes}
      end)

    voiced_path
  end

  defp stable_intervals(intervals, vocabulary) do
    intervals
    |> Enum.reject(&ChordVocabulary.avoid_interval?(vocabulary, &1))
    |> ensure_minimum_harmony(vocabulary)
  end

  defp ensure_minimum_harmony(intervals, vocabulary) when length(intervals) >= 2 do
    ensure_character(intervals, vocabulary)
  end

  defp ensure_minimum_harmony(intervals, vocabulary) do
    vocabulary
    |> ChordVocabulary.chord_intervals(:tonic)
    |> Enum.reject(&ChordVocabulary.avoid_interval?(vocabulary, &1))
    |> then(&(intervals ++ &1))
    |> Enum.uniq()
    |> Enum.take(3)
    |> ensure_character(vocabulary)
  end

  defp ensure_character(intervals, %{characteristic_intervals: []}), do: intervals

  defp ensure_character(intervals, %{characteristic_intervals: characteristic_intervals}) do
    characteristic =
      Enum.find(characteristic_intervals, fn interval ->
        Integer.mod(interval, 12) not in Enum.map(intervals, &Integer.mod(&1, 12))
      end)

    if characteristic, do: intervals ++ [characteristic], else: intervals
  end

  defp low_notes(root) do
    root_note = fit_pitch_class(root, @low_root_min, @low_root_max)
    [root_note, root_note + 19]
  end

  defp mid_notes(root, intervals, vocabulary, previous_notes) do
    intervals
    |> guide_intervals(vocabulary)
    |> Enum.map(&mid_note(root, &1, vocabulary))
    |> voice_lead(previous_notes)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp guide_intervals(intervals, vocabulary) do
    preferred =
      intervals
      |> Enum.filter(&(Integer.mod(&1, 12) in [3, 4, 10, 11]))
      |> Kernel.++(vocabulary.characteristic_intervals)
      |> Enum.uniq()

    case preferred do
      [] -> intervals |> Enum.reject(&(Integer.mod(&1, 12) == 0)) |> Enum.take(2)
      guides -> Enum.take(guides, 3)
    end
  end

  defp mid_note(root, interval, %{constraints: constraints}) do
    note = fit_pitch_class(root + interval, @mid_min, @mid_max)

    cond do
      :keep_flat_two_above_root in constraints and Integer.mod(interval, 12) == 1 ->
        root
        |> fit_pitch_class(@mid_min, @mid_max)
        |> Kernel.+(13)
        |> cap(@mid_max)

      true ->
        note
    end
  end

  defp voice_lead(notes, nil), do: notes

  defp voice_lead(notes, previous_notes) do
    Enum.map(notes, fn note ->
      candidates = [note - 12, note, note + 12] |> Enum.filter(&(&1 in @mid_min..@mid_max))
      Enum.min_by(candidates, &nearest_distance(&1, previous_notes))
    end)
  end

  defp nearest_distance(note, previous_notes) do
    previous_notes
    |> Enum.map(&abs(note - &1))
    |> Enum.min(fn -> 0 end)
  end

  defp fit_pitch_class(pitch, min, max) do
    pitch
    |> Integer.mod(12)
    |> Stream.iterate(&(&1 + 12))
    |> Enum.find(&(&1 >= min and &1 <= max))
  end

  defp cap(value, max), do: min(value, max)
end

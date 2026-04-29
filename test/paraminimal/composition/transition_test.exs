defmodule Paraminimal.Composition.TransitionTest do
  use ExUnit.Case, async: true

  alias Paraminimal.Composition.Scale
  alias Paraminimal.Composition.ScaleDistance
  alias Paraminimal.Composition.TimeSystem
  alias Paraminimal.Composition.Transition
  alias Paraminimal.Scales.Western

  test "compose returns stable sustain outside the transition window" do
    source = state(:twilight, Western.get!(:aeolian, 0), :seventh, 0.5, 0.4)
    destination = state(:night, Western.get!(:phrygian, 7), :suspended, 0.25, 0.2)

    plan =
      compose_plan(
        "2026-04-28T19:30:00Z",
        source,
        destination
      )

    refute plan.active?
    assert plan.phase == :stable
    assert plan.duration_bars == 0
    assert plan.current_bar == 0
    assert plan.strategies == [:stable_sustain]
    assert length(plan.harmonic_path) == 1
  end

  test "compose creates a multi-bar path near a period boundary" do
    source = state(:twilight, Western.get!(:aeolian, 0), :seventh, 0.5, 0.4)
    destination = state(:night, Western.get!(:phrygian, 7), :suspended, 0.25, 0.2)

    plan =
      compose_plan(
        "2026-04-28T19:50:00Z",
        source,
        destination
      )

    assert plan.active?
    assert plan.phase == :in_progress
    assert plan.duration_bars in [8, 12, 16]
    assert plan.current_bar in 1..plan.duration_bars
    assert length(plan.harmonic_path) == plan.duration_bars
    assert length(plan.melodic_path) > 0
    assert hd(plan.harmonic_path).scale == :aeolian
    assert List.last(plan.harmonic_path).scale == :phrygian

    assert Enum.all?(
             plan.harmonic_path,
             &match?(%{voicing: %{notes: notes}} when is_list(notes), &1)
           )

    assert plan.path_technique in [
             :common_tone,
             :voice_leading_migration,
             :progressive_chord_change,
             :tritone_dominant
           ]

    assert is_atom(plan.arrival_gesture)
  end

  test "distant transitions include arrival and rhythmic strategies" do
    source = state(:morning, Western.get!(:ionian, 0), :triad, 0.9, 0.8)
    destination = state(:twilight, Western.get!(:ionian, 6), :seventh, 0.25, 0.2)

    plan =
      compose_plan(
        "2026-04-28T04:55:00Z",
        source,
        destination
      )

    assert plan.duration_bars == 16
    assert plan.path_technique in [:circle_of_fifths, :tritone_dominant]
    assert plan.arrival_gesture == :silence_as_arrival
    assert :silence_as_arrival in plan.strategies
    assert :rhythmic_dissolution in plan.strategies
    assert plan.rhythmic_gesture.family == :rhythmic_dissolution
  end

  test "epoch includes a composed transition plan" do
    epoch = Paraminimal.Composition.Epoch.for_datetime(datetime!("2026-04-28T19:50:00Z"))

    assert epoch.transition_plan.active?
    assert epoch.transition_plan.source.period == :twilight
    assert epoch.transition_plan.destination.period == :night
    assert epoch.transition_plan.duration_bars > 0
  end

  defp compose_plan(iso8601, source, destination) do
    Transition.compose(%{
      time_transition: iso8601 |> datetime!() |> TimeSystem.transition_for(),
      source: source,
      destination: destination,
      distance: ScaleDistance.between(source.scale_struct, destination.scale_struct)
    })
  end

  defp state(period, scale, chord_shape, energy, density) do
    %{
      period: period,
      scale: scale.slug,
      scale_struct: scale,
      root: scale.root,
      root_name: scale.root_name,
      chord_shape: chord_shape,
      energy: energy,
      density: density,
      pitch_classes: Scale.pitch_classes(scale)
    }
  end

  defp datetime!(iso8601) do
    {:ok, datetime, 0} = DateTime.from_iso8601(iso8601)
    datetime
  end
end

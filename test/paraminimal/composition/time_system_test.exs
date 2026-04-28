defmodule Paraminimal.Composition.TimeSystemTest do
  use ExUnit.Case, async: true

  alias Paraminimal.Composition.TimeSystem

  test "period_for returns the UTC period for each boundary" do
    assert period_key("2026-04-28T00:00:00Z") == :deep_night
    assert period_key("2026-04-28T04:59:00Z") == :deep_night
    assert period_key("2026-04-28T05:00:00Z") == :dawn
    assert period_key("2026-04-28T08:00:00Z") == :morning
    assert period_key("2026-04-28T12:00:00Z") == :afternoon
    assert period_key("2026-04-28T17:00:00Z") == :twilight
    assert period_key("2026-04-28T20:00:00Z") == :night
    assert period_key("2026-04-28T23:59:00Z") == :night
  end

  test "next_period wraps at the end of the day" do
    assert TimeSystem.next_period(:deep_night).key == :dawn
    assert TimeSystem.next_period(:night).key == :deep_night
  end

  test "transition_for detects the approach to a period boundary" do
    transition = transition_for("2026-04-28T04:45:00Z")

    assert transition.in_transition_zone?
    assert transition.zone == :approaching_boundary
    assert transition.next_period.key == :dawn
    assert transition.minutes_to_boundary == 15
    assert transition.progress == 0.25
  end

  test "transition_for reports core zone outside the boundary window" do
    transition = transition_for("2026-04-28T04:39:00Z")

    refute transition.in_transition_zone?
    assert transition.zone == :core
    assert transition.next_period.key == :dawn
    assert transition.minutes_to_boundary == 21
    assert transition.progress == 0.0
  end

  defp period_key(iso8601) do
    iso8601
    |> datetime!()
    |> TimeSystem.period_for()
    |> Map.fetch!(:key)
  end

  defp transition_for(iso8601) do
    iso8601
    |> datetime!()
    |> TimeSystem.transition_for()
  end

  defp datetime!(iso8601) do
    {:ok, datetime, 0} = DateTime.from_iso8601(iso8601)
    datetime
  end
end

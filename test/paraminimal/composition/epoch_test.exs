defmodule Paraminimal.Composition.EpochTest do
  use ExUnit.Case, async: true

  alias Paraminimal.Composition.Epoch

  test "for_datetime returns deterministic state for the same timestamp" do
    datetime = datetime!("2026-04-28T13:37:00Z")

    assert Epoch.for_datetime(datetime) == Epoch.for_datetime(datetime)
  end

  test "for_datetime computes afternoon epoch metadata" do
    epoch = Epoch.for_datetime(datetime!("2026-04-28T13:37:00Z"))

    assert epoch.period.key == :afternoon
    assert epoch.next_period.key == :twilight
    assert epoch.scale.slug in [:dorian, :major_pentatonic, :melodic_minor]
    assert epoch.root in 0..11
    assert epoch.root_name
    assert epoch.energy >= 0.0 and epoch.energy <= 1.0
    assert epoch.density >= 0.0 and epoch.density <= 1.0
    assert length(epoch.distances) == 3
  end

  test "same_epoch? tracks quarter-hour epoch buckets" do
    first = Epoch.for_datetime(datetime!("2026-04-28T13:01:00Z"))
    same_bucket = Epoch.for_datetime(datetime!("2026-04-28T13:14:00Z"))
    next_bucket = Epoch.for_datetime(datetime!("2026-04-28T13:15:00Z"))

    assert Epoch.same_epoch?(first, same_bucket)
    refute Epoch.same_epoch?(first, next_bucket)
  end

  test "transition state is included near boundaries" do
    epoch = Epoch.for_datetime(datetime!("2026-04-28T19:50:00Z"))

    assert epoch.period.key == :twilight
    assert epoch.transition.in_transition_zone?
    assert epoch.transition.next_period.key == :night
  end

  defp datetime!(iso8601) do
    {:ok, datetime, 0} = DateTime.from_iso8601(iso8601)
    datetime
  end
end

defmodule ParaminimalWeb.SessionLiveTest do
  use ParaminimalWeb.ConnCase

  import Phoenix.LiveViewTest

  test "GET / renders composition foundation", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")

    assert html =~ "Paraminimal"
    assert html =~ "Current:"
    assert html =~ "UTC epoch"
    assert html =~ "Current UTC Epoch"
    assert html =~ "Adjacent Relationships"
    assert html =~ "SuperSonic boundary ready"
  end
end

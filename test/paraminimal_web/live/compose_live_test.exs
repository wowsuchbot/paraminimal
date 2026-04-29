defmodule ParaminimalWeb.ComposeLiveTest do
  use ParaminimalWeb.ConnCase

  import Phoenix.LiveViewTest

  test "GET /compose renders three pane composer shell", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/compose")

    assert html =~ "Composer Miniapp"
    assert html =~ "Library"
    assert html =~ "Editor"
    assert html =~ "Audition"
  end

  test "saves transition recipe from form", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/compose")

    params = %{
      "kind" => "transition_recipe",
      "data" => %{
        "name" => "Recipe A",
        "slug" => "recipe-a",
        "status" => "draft",
        "version" => "1",
        "from_period" => "morning",
        "to_period" => "afternoon",
        "energy_band" => "mid",
        "density_band" => "mid",
        "distance_class" => "near",
        "path_technique" => "pivot_modulation",
        "arrival_gesture" => "authentic_cadence",
        "harmonic_route_roles" => "ii,V,I",
        "melodic_guide_behavior" => "nearest",
        "max_leap" => "5",
        "avoid_moves" => "parallel_fifths",
        "forbidden_colors" => "b9"
      }
    }

    html = render_submit(view, "save", params)
    assert html =~ "Saved Transition recipe"
    assert html =~ "Recipe A"
  end

  test "preview start populates diagnostics", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/compose")
    html = render_click(view, "preview_start")
    assert html =~ "Diagnostics log"
    assert html =~ "recipe="
  end
end

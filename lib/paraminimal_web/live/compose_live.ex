defmodule ParaminimalWeb.ComposeLive do
  use ParaminimalWeb, :live_view

  alias Paraminimal.Composer
  alias Paraminimal.Composer.ChordProfile
  alias Paraminimal.Composer.InstrumentRule
  alias Paraminimal.Composer.Motif
  alias Paraminimal.Composer.Phrase
  alias Paraminimal.Composer.TransitionRecipe
  alias Paraminimal.Composition.Epoch

  @kinds [:transition_recipe, :motif, :instrument_rule, :phrase, :chord_profile]
  @status_options ["draft", "published", "archived"]
  @period_options ["deep_night", "dawn", "morning", "afternoon", "twilight", "night"]

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:kinds, @kinds)
      |> assign(:status_options, @status_options)
      |> assign(:period_options, @period_options)
      |> assign(:selected_kind, :transition_recipe)
      |> assign(:selected_id, nil)
      |> assign(:preview_payload, nil)
      |> assign(:preview_log, [])
      |> assign_library()
      |> assign_form(:transition_recipe, new_record(:transition_recipe))

    {:ok, socket}
  end

  @impl true
  def handle_event("select_kind", %{"kind" => kind}, socket) do
    selected_kind = String.to_existing_atom(kind)

    {:noreply,
     socket
     |> assign(:selected_kind, selected_kind)
     |> assign(:selected_id, nil)
     |> assign_form(selected_kind, new_record(selected_kind))}
  end

  def handle_event("new_item", _params, socket) do
    kind = socket.assigns.selected_kind
    {:noreply, socket |> assign(:selected_id, nil) |> assign_form(kind, new_record(kind))}
  end

  def handle_event("select_item", %{"kind" => kind, "id" => id}, socket) do
    selected_kind = String.to_existing_atom(kind)
    record = get_record!(selected_kind, id)

    {:noreply,
     socket
     |> assign(:selected_kind, selected_kind)
     |> assign(:selected_id, record.id)
     |> assign_form(selected_kind, record)}
  end

  def handle_event("validate", %{"kind" => kind, "data" => attrs}, socket) do
    selected_kind = String.to_existing_atom(kind)

    changeset =
      attrs
      |> normalize_attrs(selected_kind)
      |> then(&change_record(selected_kind, current_record(socket), &1))
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset, as: :data))}
  end

  def handle_event("save", %{"kind" => kind, "data" => attrs}, socket) do
    selected_kind = String.to_existing_atom(kind)
    attrs = normalize_attrs(attrs, selected_kind)

    case save_record(selected_kind, current_record(socket), attrs) do
      {:ok, saved} ->
        {:noreply,
         socket
         |> put_flash(:info, "Saved #{label_for(selected_kind)}")
         |> assign(:selected_id, saved.id)
         |> assign_library()
         |> assign_form(selected_kind, saved)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :data))}
    end
  end

  def handle_event("clone_recipe", %{"id" => id}, socket) do
    recipe = Composer.clone_transition_recipe!(id)

    {:noreply,
     socket
     |> put_flash(:info, "Cloned transition recipe")
     |> assign_library()
     |> assign(:selected_kind, :transition_recipe)
     |> assign(:selected_id, recipe.id)
     |> assign_form(:transition_recipe, recipe)}
  end

  def handle_event("preview_start", _params, socket) do
    payload = preview_payload(socket)
    recipe = preview_recipe(socket)

    log =
      "#{DateTime.utc_now() |> DateTime.to_iso8601()} · recipe=#{recipe.slug} · #{recipe.path_technique} -> #{recipe.arrival_gesture}"

    {:noreply,
     socket
     |> assign(:preview_payload, payload)
     |> update(:preview_log, &[log | Enum.take(&1, 24)])
     |> push_event("composition_state", payload)}
  end

  def handle_event("preview_stop", _params, socket) do
    {:noreply,
     socket
     |> assign(:preview_payload, nil)
     |> push_event("composition_state", %{
       motif: %{name: "preview stopped", degrees: [], rhythm: []},
       transition_plan: %{active: false}
     })}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <main class="min-h-screen bg-zinc-950 text-zinc-100">
      <section class="mx-auto flex min-h-screen w-full max-w-screen-2xl flex-col gap-6 px-4 py-6 sm:px-6 lg:px-8">
        <div class="rounded-2xl border border-zinc-800 bg-zinc-900/80 p-4">
          <h1 class="text-3xl font-semibold text-white">Composer Miniapp</h1>
          <p class="mt-2 text-sm text-zinc-400">
            Human-authored rules for motifs, phrases, transitions, instruments, and chord vocabulary.
          </p>
        </div>

        <div class="grid flex-1 gap-5 xl:grid-cols-[300px_minmax(0,1fr)_360px]">
          <aside class="rounded-2xl border border-zinc-800 bg-zinc-900/80 p-4">
            <p class="text-xs uppercase tracking-[0.25em] text-zinc-500">Library</p>

            <div class="mt-3 flex flex-wrap gap-2">
              <button
                :for={kind <- @kinds}
                type="button"
                phx-click="select_kind"
                phx-value-kind={kind}
                class={[
                  "rounded-full px-3 py-1 text-xs",
                  @selected_kind == kind && "bg-cyan-300 text-zinc-900",
                  @selected_kind != kind && "bg-zinc-800 text-zinc-200 hover:bg-zinc-700"
                ]}
              >
                {label_for(kind)}
              </button>
            </div>

            <button
              type="button"
              phx-click="new_item"
              class="mt-4 inline-flex w-full justify-center rounded-lg bg-zinc-100 px-3 py-2 text-sm font-semibold text-zinc-900 hover:bg-white"
            >
              New {label_for(@selected_kind)}
            </button>

            <div class="mt-4 space-y-2">
              <button
                :for={item <- items_for_kind(assigns, @selected_kind)}
                type="button"
                phx-click="select_item"
                phx-value-kind={@selected_kind}
                phx-value-id={item.id}
                class={[
                  "w-full rounded-lg border p-2 text-left text-sm",
                  @selected_id == item.id && "border-cyan-300 bg-cyan-950/40",
                  @selected_id != item.id && "border-zinc-700 bg-zinc-950/50 hover:border-zinc-500"
                ]}
              >
                <p class="font-medium text-zinc-100">{item.name}</p>
                <p class="text-xs text-zinc-500">{item.status} · v{item.version}</p>
              </button>
            </div>
          </aside>

          <section class="rounded-2xl border border-zinc-800 bg-zinc-900/80 p-4">
            <p class="text-xs uppercase tracking-[0.25em] text-zinc-500">Editor</p>
            <p class="mt-2 text-sm text-zinc-400">{label_for(@selected_kind)}</p>

            <.form
              for={@form}
              as={:data}
              phx-change="validate"
              phx-submit="save"
              phx-value-kind={@selected_kind}
              class="mt-4 space-y-4"
            >
              <input type="hidden" name="kind" value={@selected_kind} />
              <.input field={@form[:name]} label="Name" />
              <.input field={@form[:slug]} label="Slug" />
              <.input field={@form[:status]} type="select" label="Status" options={@status_options} />
              <.input field={@form[:version]} type="number" label="Version" />
              <.input
                :if={@selected_kind != :transition_recipe}
                field={@form[:feel_notes]}
                type="textarea"
                label="Feel Notes"
              />

              <div :if={@selected_kind == :transition_recipe} class="grid gap-3 sm:grid-cols-2">
                <.input
                  field={@form[:from_period]}
                  type="select"
                  label="From Period"
                  options={@period_options}
                />
                <.input
                  field={@form[:to_period]}
                  type="select"
                  label="To Period"
                  options={@period_options}
                />
                <.input field={@form[:energy_band]} label="Energy Band" />
                <.input field={@form[:density_band]} label="Density Band" />
                <.input field={@form[:distance_class]} label="Distance Class" />
                <.input field={@form[:path_technique]} label="Path Technique" />
                <.input field={@form[:arrival_gesture]} label="Arrival Gesture" />
                <.input field={@form[:melodic_guide_behavior]} label="Melodic Guide Behavior" />
                <.input field={@form[:max_leap]} type="number" label="Max Leap" />
                <.input
                  field={@form[:harmonic_route_roles]}
                  type="textarea"
                  label="Harmonic Route Roles (csv)"
                />
                <.input field={@form[:avoid_moves]} type="textarea" label="Avoid Moves (csv)" />
                <.input
                  field={@form[:forbidden_colors]}
                  type="textarea"
                  label="Forbidden Colors (csv)"
                />
                <.input field={@form[:feel_notes]} type="textarea" label="Feel Notes" />
              </div>

              <div :if={@selected_kind == :motif} class="grid gap-3 sm:grid-cols-2">
                <.input
                  field={@form[:period_affinity]}
                  type="select"
                  label="Period Affinity"
                  options={@period_options}
                />
                <.input field={@form[:energy_min]} type="number" step="0.01" label="Energy Min" />
                <.input field={@form[:energy_max]} type="number" step="0.01" label="Energy Max" />
                <.input field={@form[:degrees]} type="textarea" label="Scale Degrees (csv ints)" />
                <.input field={@form[:rhythm]} type="textarea" label="Rhythm Steps (csv floats)" />
                <.input field={@form[:contour_hints]} type="textarea" label="Contour Hints (csv)" />
              </div>

              <div :if={@selected_kind == :instrument_rule} class="grid gap-3 sm:grid-cols-2">
                <.input
                  field={@form[:layer]}
                  type="select"
                  label="Layer"
                  options={["drone", "motif", "texture", "percussion"]}
                />
                <.input field={@form[:register_policy]} label="Register Policy" />
                <.input field={@form[:note_limit]} type="number" label="Note Limit" />
                <.input field={@form[:articulation]} label="Articulation" />
                <.input field={@form[:release_ms]} type="number" label="Release (ms)" />
                <.input
                  field={@form[:gesture_overrides]}
                  type="textarea"
                  label="Gesture Overrides (JSON)"
                />
              </div>

              <div :if={@selected_kind == :phrase} class="grid gap-3 sm:grid-cols-2">
                <.input field={@form[:bars]} type="number" label="Bars" />
                <.input field={@form[:role_sequence]} type="textarea" label="Role Sequence (csv)" />
                <.input
                  field={@form[:guide_tone_anchors]}
                  type="textarea"
                  label="Guide Tone Anchors (csv ints)"
                />
              </div>

              <div :if={@selected_kind == :chord_profile} class="grid gap-3 sm:grid-cols-2">
                <.input field={@form[:scale_slug]} label="Scale Slug" />
                <.input
                  field={@form[:characteristic_tones]}
                  type="textarea"
                  label="Characteristic Tones (csv ints)"
                />
                <.input field={@form[:avoid_tones]} type="textarea" label="Avoid Tones (csv ints)" />
                <.input field={@form[:arrival_options]} type="textarea" label="Arrival Options (csv)" />
                <.input field={@form[:chord_roles]} type="textarea" label="Chord Roles (JSON)" />
              </div>

              <div class="flex items-center gap-2">
                <.button type="submit">Save</.button>
                <.button
                  :if={@selected_kind == :transition_recipe && @selected_id}
                  type="button"
                  phx-click="clone_recipe"
                  phx-value-id={@selected_id}
                  class="bg-zinc-700 hover:bg-zinc-600"
                >
                  Clone Version
                </.button>
              </div>
            </.form>
          </section>

          <aside
            id="compose-audition"
            phx-hook="SuperSonicRuntime"
            class="rounded-2xl border border-zinc-800 bg-zinc-900/80 p-4"
          >
            <p class="text-xs uppercase tracking-[0.25em] text-zinc-500">Audition</p>
            <p class="mt-2 text-sm text-zinc-400">
              Preview deterministic transition generation and send state to the audio runtime hook.
            </p>

            <div class="mt-4 flex gap-2">
              <button
                id="audio-toggle"
                type="button"
                phx-click="preview_start"
                class="rounded-lg bg-cyan-300 px-3 py-2 text-sm font-semibold text-zinc-900"
              >
                Start preview
              </button>
              <button
                type="button"
                phx-click="preview_stop"
                class="rounded-lg bg-zinc-700 px-3 py-2 text-sm hover:bg-zinc-600"
              >
                Stop
              </button>
            </div>

            <div id="audio-status" class="mt-3 text-xs text-zinc-400">preview ready</div>

            <div class="mt-4 rounded-lg border border-zinc-800 bg-zinc-950/70 p-3 text-xs text-zinc-300">
              <p class="font-semibold text-zinc-100">Preview payload</p>
              <pre class="mt-2 max-h-56 overflow-auto">{inspect(@preview_payload, pretty: true, limit: :infinity)}</pre>
            </div>

            <div class="mt-4 rounded-lg border border-zinc-800 bg-zinc-950/70 p-3 text-xs text-zinc-300">
              <p class="font-semibold text-zinc-100">Diagnostics log</p>
              <ul class="mt-2 space-y-1">
                <li :for={line <- @preview_log}>{line}</li>
              </ul>
            </div>
          </aside>
        </div>
      </section>
    </main>
    """
  end

  defp assign_library(socket) do
    socket
    |> assign(:motifs, Composer.list_motifs())
    |> assign(:phrases, Composer.list_phrases())
    |> assign(:transition_recipes, Composer.list_transition_recipes())
    |> assign(:instrument_rules, Composer.list_instrument_rules())
    |> assign(:chord_profiles, Composer.list_chord_profiles())
  end

  defp assign_form(socket, kind, record) do
    socket
    |> assign(:record, record)
    |> assign(:form, to_form(change_record(kind, record, %{}), as: :data))
  end

  defp label_for(kind),
    do: kind |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()

  defp current_record(socket), do: socket.assigns.record

  defp items_for_kind(assigns, :transition_recipe), do: assigns.transition_recipes
  defp items_for_kind(assigns, :motif), do: assigns.motifs
  defp items_for_kind(assigns, :instrument_rule), do: assigns.instrument_rules
  defp items_for_kind(assigns, :phrase), do: assigns.phrases
  defp items_for_kind(assigns, :chord_profile), do: assigns.chord_profiles

  defp new_record(:transition_recipe),
    do: %TransitionRecipe{
      name: "New transition recipe",
      slug: "transition-#{System.unique_integer([:positive])}"
    }

  defp new_record(:motif),
    do: %Motif{name: "New motif", slug: "motif-#{System.unique_integer([:positive])}"}

  defp new_record(:instrument_rule),
    do: %InstrumentRule{
      name: "New instrument rule",
      slug: "instrument-#{System.unique_integer([:positive])}"
    }

  defp new_record(:phrase),
    do: %Phrase{name: "New phrase", slug: "phrase-#{System.unique_integer([:positive])}"}

  defp new_record(:chord_profile),
    do: %ChordProfile{
      name: "New chord profile",
      slug: "profile-#{System.unique_integer([:positive])}"
    }

  defp get_record!(:transition_recipe, id), do: Composer.get_transition_recipe!(id)
  defp get_record!(:motif, id), do: Composer.get_motif!(id)
  defp get_record!(:instrument_rule, id), do: Composer.get_instrument_rule!(id)
  defp get_record!(:phrase, id), do: Composer.get_phrase!(id)
  defp get_record!(:chord_profile, id), do: Composer.get_chord_profile!(id)

  defp change_record(:transition_recipe, record, attrs),
    do: Composer.change_transition_recipe(record, attrs)

  defp change_record(:motif, record, attrs), do: Composer.change_motif(record, attrs)

  defp change_record(:instrument_rule, record, attrs),
    do: Composer.change_instrument_rule(record, attrs)

  defp change_record(:phrase, record, attrs), do: Composer.change_phrase(record, attrs)

  defp change_record(:chord_profile, record, attrs),
    do: Composer.change_chord_profile(record, attrs)

  defp save_record(:transition_recipe, record, attrs),
    do: Composer.save_transition_recipe(record, attrs)

  defp save_record(:motif, record, attrs), do: Composer.save_motif(record, attrs)

  defp save_record(:instrument_rule, record, attrs),
    do: Composer.save_instrument_rule(record, attrs)

  defp save_record(:phrase, record, attrs), do: Composer.save_phrase(record, attrs)
  defp save_record(:chord_profile, record, attrs), do: Composer.save_chord_profile(record, attrs)

  defp preview_recipe(socket) do
    cond do
      socket.assigns.selected_kind == :transition_recipe &&
          match?(%TransitionRecipe{}, socket.assigns.record) ->
        socket.assigns.record

      socket.assigns.transition_recipes != [] ->
        List.first(socket.assigns.transition_recipes)

      true ->
        %TransitionRecipe{
          name: "default",
          slug: "default",
          path_technique: "voice_leading_migration",
          arrival_gesture: "modal_arrival"
        }
    end
  end

  defp preview_payload(socket) do
    epoch = Epoch.for_datetime(DateTime.utc_now())
    recipe = preview_recipe(socket)

    %{
      motif: %{
        name: epoch.motif.name,
        degrees: epoch.motif.scale_degrees,
        rhythm: epoch.motif.rhythm
      },
      transition_plan: %{
        active: true,
        phase: epoch.transition_plan.phase,
        path_technique: safe_atom(recipe.path_technique),
        arrival_gesture: safe_atom(recipe.arrival_gesture),
        harmonic_path: epoch.transition_plan.harmonic_path,
        melodic_path: epoch.transition_plan.melodic_path
      }
    }
  end

  defp safe_atom(nil), do: :unknown
  defp safe_atom(value) when is_atom(value), do: value
  defp safe_atom(value) when is_binary(value), do: String.to_atom(value)

  defp normalize_attrs(attrs, :transition_recipe) do
    attrs
    |> put_csv_list(:harmonic_route_roles)
    |> put_csv_list(:avoid_moves)
    |> put_csv_list(:forbidden_colors)
  end

  defp normalize_attrs(attrs, :motif) do
    attrs
    |> put_csv_ints(:degrees)
    |> put_csv_floats(:rhythm)
    |> put_csv_list(:contour_hints)
  end

  defp normalize_attrs(attrs, :instrument_rule), do: put_json_map(attrs, :gesture_overrides)

  defp normalize_attrs(attrs, :phrase) do
    attrs
    |> put_csv_list(:role_sequence)
    |> put_csv_ints(:guide_tone_anchors)
  end

  defp normalize_attrs(attrs, :chord_profile) do
    attrs
    |> put_csv_ints(:characteristic_tones)
    |> put_csv_ints(:avoid_tones)
    |> put_csv_list(:arrival_options)
    |> put_json_map(:chord_roles)
  end

  defp put_csv_list(attrs, key) do
    Map.update(attrs, Atom.to_string(key), [], fn raw ->
      raw
      |> to_string()
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
    end)
  end

  defp put_csv_ints(attrs, key) do
    Map.update(attrs, Atom.to_string(key), [], fn raw ->
      raw
      |> to_string()
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&Integer.parse/1)
      |> Enum.flat_map(fn
        {value, ""} -> [value]
        _ -> []
      end)
    end)
  end

  defp put_csv_floats(attrs, key) do
    Map.update(attrs, Atom.to_string(key), [], fn raw ->
      raw
      |> to_string()
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&Float.parse/1)
      |> Enum.flat_map(fn
        {value, ""} -> [value]
        _ -> []
      end)
    end)
  end

  defp put_json_map(attrs, key) do
    Map.update(attrs, Atom.to_string(key), %{}, fn raw ->
      raw = String.trim(to_string(raw))

      cond do
        raw == "" -> %{}
        true -> Jason.decode(raw) |> elem_or_default(%{})
      end
    end)
  end

  defp elem_or_default({:ok, value}, _default), do: value
  defp elem_or_default({:error, _}, default), do: default
end

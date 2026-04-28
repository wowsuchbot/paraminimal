defmodule Paraminimal.Composition.MotifEngine do
  @moduledoc """
  Canon operations for melodic transformation.

  All transformations are pure functions that operate on scale degrees
  and rhythm patterns. The engine tracks transformation lineage so
  every fragment can be traced back to its source motif.

  ## Supported operations

  * `:retrograde`           — time reversal
  * `:inversion`            — mirror intervals around the first note
  * `:augmentation`         — stretch rhythm by factor of 2
  * `:diminution`           — compress rhythm by factor of 2
  * `:transposition`        — shift all scale degrees by a constant
  * `:additive_permutation` — rotate the rhythm pattern by N positions
  """

  alias Paraminimal.Composition.Motif
  alias Paraminimal.Composition.TransformedMotif

  # ── Single operations ─────────────────────────────────────────────

  @doc "Reverses both scale_degrees and rhythm (time reversal)."
  @spec retrograde(Motif.t() | TransformedMotif.t()) :: TransformedMotif.t()
  def retrograde(%Motif{} = motif) do
    motif |> TransformedMotif.from_motif() |> retrograde()
  end

  def retrograde(%TransformedMotif{} = tm) do
    %{tm |
      scale_degrees: Enum.reverse(tm.scale_degrees),
      rhythm: Enum.reverse(tm.rhythm),
      transformations: tm.transformations ++ [{:retrograde, nil}]
    }
  end

  @doc """
  Mirrors intervals around the first note.

  The first degree stays fixed; each subsequent interval is flipped
  in direction. `[0, 2, 4, 5, 7]` becomes `[0, -2, -4, -5, -7]`.
  """
  @spec inversion(Motif.t() | TransformedMotif.t()) :: TransformedMotif.t()
  def inversion(%Motif{} = motif) do
    motif |> TransformedMotif.from_motif() |> inversion()
  end

  def inversion(%TransformedMotif{scale_degrees: [pivot | rest]} = tm) do
    # Compute successive intervals from the original, then flip each one
    {intervals, _} =
      Enum.map_reduce(rest, pivot, fn degree, prev ->
        interval = degree - prev
        {interval, degree}
      end)

    # Apply flipped intervals starting from the pivot
    inverted =
      Enum.reduce(intervals, [], fn interval, acc ->
        last = if acc == [], do: pivot, else: hd(acc)
        [last - interval | acc]
      end)
      |> Enum.reverse()

    %{tm |
      scale_degrees: [pivot | inverted],
      transformations: tm.transformations ++ [{:inversion, nil}]
    }
  end

  @doc "Multiplies all rhythm values by 2 (stretch in time)."
  @spec augmentation(Motif.t() | TransformedMotif.t()) :: TransformedMotif.t()
  def augmentation(%Motif{} = motif) do
    motif |> TransformedMotif.from_motif() |> augmentation()
  end

  def augmentation(%TransformedMotif{} = tm) do
    %{tm |
      rhythm: Enum.map(tm.rhythm, &(&1 * 2)),
      transformations: tm.transformations ++ [{:augmentation, nil}]
    }
  end

  @doc "Divides all rhythm values by 2 (compress in time)."
  @spec diminution(Motif.t() | TransformedMotif.t()) :: TransformedMotif.t()
  def diminution(%Motif{} = motif) do
    motif |> TransformedMotif.from_motif() |> diminution()
  end

  def diminution(%TransformedMotif{} = tm) do
    %{tm |
      rhythm: Enum.map(tm.rhythm, &(&1 / 2)),
      transformations: tm.transformations ++ [{:diminution, nil}]
    }
  end

  @doc "Adds a constant offset to all scale_degrees."
  @spec transposition(Motif.t() | TransformedMotif.t(), integer()) :: TransformedMotif.t()
  def transposition(%Motif{} = motif, offset) when is_integer(offset) do
    motif |> TransformedMotif.from_motif() |> transposition(offset)
  end

  def transposition(%TransformedMotif{} = tm, offset) when is_integer(offset) do
    %{tm |
      scale_degrees: Enum.map(tm.scale_degrees, &(&1 + offset)),
      transformations: tm.transformations ++ [{:transposition, offset}]
    }
  end

  @doc "Rotates the rhythm pattern by `n` positions (Messiaen technique)."
  @spec additive_permutation(Motif.t() | TransformedMotif.t(), integer()) :: TransformedMotif.t()
  def additive_permutation(%Motif{} = motif, n) when is_integer(n) do
    motif |> TransformedMotif.from_motif() |> additive_permutation(n)
  end

  def additive_permutation(%TransformedMotif{} = tm, n) when is_integer(n) do
    len = Kernel.length(tm.rhythm)
    shift = Integer.mod(n, len)
    rotated = Enum.drop(tm.rhythm, shift) ++ Enum.take(tm.rhythm, shift)

    %{tm |
      rhythm: rotated,
      transformations: tm.transformations ++ [{:additive_permutation, n}]
    }
  end

  # ── Chain composition ─────────────────────────────────────────────

  @doc """
  Applies a chain of transformations sequentially.

  Each operation in the list should be `{operation_atom, args}` or
  `operation_atom` (when the operation takes no argument).

  Returns a `TransformedMotif` recording the full lineage.

  ## Examples

      iex> apply_chain(motif, [{:retrograde, nil}, {:transposition, 2}])
      iex> apply_chain(motif, [:retrograde, {:transposition, 2}])
  """
  @spec apply_chain(Motif.t(), [{atom(), term()} | atom()]) :: TransformedMotif.t()
  def apply_chain(%Motif{} = motif, operations) when is_list(operations) do
    Enum.reduce(operations, TransformedMotif.from_motif(motif), fn
      {:retrograde, _}, tm -> retrograde(tm)
      {:inversion, _}, tm -> inversion(tm)
      {:augmentation, _}, tm -> augmentation(tm)
      {:diminution, _}, tm -> diminution(tm)
      {:transposition, offset}, tm -> transposition(tm, offset)
      {:additive_permutation, n}, tm -> additive_permutation(tm, n)
      :retrograde, tm -> retrograde(tm)
      :inversion, tm -> inversion(tm)
      :augmentation, tm -> augmentation(tm)
      :diminution, tm -> diminution(tm)
      op, _tm when is_atom(op) ->
        raise ArgumentError, "operation #{inspect(op)} requires an argument"
    end)
  end
end

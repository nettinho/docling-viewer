defmodule DoclingViewerWeb.CoreComponents.InputHelpers do
  @moduledoc """
  Helper functions for input styling.
  """

  @doc """
  Returns the border class based on whether there are errors.
  """
  def input_border(has_errors?) do
    if has_errors? do
      "border-rose-400"
    else
      "border-zinc-300"
    end
  end

  @doc """
  Returns the focus class based on whether there are errors.
  """
  def input_focus(has_errors?) do
    if has_errors? do
      "focus:border-rose-400"
    else
      "focus:border-zinc-400"
    end
  end
end

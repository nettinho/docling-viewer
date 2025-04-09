defmodule DoclingViewerWeb.HomeLive do
  use DoclingViewerWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl">
        <h1 class="text-3xl font-bold text-zinc-900">Docling</h1>
      </div>
    </div>
    """
  end
end

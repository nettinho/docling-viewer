defmodule DoclingViewerWeb.DocumentViewerLive do
  use DoclingViewerWeb, :live_view
  alias DoclingViewerWeb.DocumentTreeComponent

  @impl true
  def mount(_params, _session, socket) do
    case File.read(Application.app_dir(:docling_viewer, "priv/static/example.json")) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, document} ->
            {:ok,
             socket
             |> assign(:document, document)
             |> assign(:selected_node, nil)
             |> assign(:selected_path, nil)}

          {:error, _} ->
            {:ok,
             socket
             |> put_flash(:error, "Failed to parse document JSON")
             |> assign(:document, nil)
             |> assign(:selected_node, nil)
             |> assign(:selected_path, nil)}
        end

      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, "Failed to load document")
         |> assign(:document, nil)
         |> assign(:selected_node, nil)
         |> assign(:selected_path, nil)}
    end
  end

  @impl true
  def handle_event("select_node", %{"path" => path}, socket) do
    selected_node = find_node_by_path(socket.assigns.document, path)
    resolved_node = resolve_refs(selected_node, socket.assigns.document)

    {:noreply,
     socket
     |> assign(:selected_node, resolved_node)
     |> assign(:selected_path, path)}
  end

  # Helper functions to handle document references
  defp resolve_refs(%{"$ref" => ref} = node, document) do
    case get_ref_path(ref) do
      ["texts", index] ->
        texts = get_in(document, ["texts"])
        Enum.at(texts, String.to_integer(index), node)

      ["pictures", index] ->
        pictures = get_in(document, ["pictures"])
        Enum.at(pictures, String.to_integer(index), node)

      ["tables", index] ->
        tables = get_in(document, ["tables"])
        Enum.at(tables, String.to_integer(index), node)

      _ ->
        node
    end
  end

  defp resolve_refs(node, _document), do: node

  defp get_ref_path(ref) do
    ref
    |> String.trim_leading("#/")
    |> String.split("/")
  end

  defp find_node_by_path(nil, _path), do: nil
  defp find_node_by_path(%{"path" => path} = node, path), do: node

  defp find_node_by_path(%{"children" => children} = _node, path) when is_list(children) do
    Enum.find_value(children, fn child -> find_node_by_path(child, path) end)
  end

  defp find_node_by_path(%{"body" => %{"children" => children}} = _node, path)
       when is_list(children) do
    Enum.find_value(children, fn child -> find_node_by_path(child, path) end)
  end

  defp find_node_by_path(_node, _path), do: nil

  defp get_metadata_properties(node) do
    node
    |> Enum.reject(fn {key, _} ->
      key in ["children", "text", "image_data", "cells", "body", "content", "data"]
    end)
    |> Enum.map(fn {key, value} -> {String.capitalize(key), inspect(value, pretty: true)} end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-screen flex overflow-hidden bg-gray-100">
      <%!-- Sidebar Navigation Tree --%>
      <div class="w-64 flex-shrink-0 border-r border-gray-200 bg-white overflow-y-auto">
        <div class="p-4">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Document Structure</h2>
          <%= if @document do %>
            <div class="space-y-2">
              <.live_component
                module={DocumentTreeComponent}
                id="document-tree"
                node={@document}
                selected_path={@selected_path}
              />
            </div>
          <% else %>
            <div class="text-sm text-gray-500">
              No document loaded
            </div>
          <% end %>
        </div>
      </div>

      <%!-- Main Content Panel --%>
      <div class="flex-1 overflow-y-auto">
        <div class="p-8">
          <%= if @selected_node do %>
            <div class="bg-white shadow rounded-lg p-6">
              <%= case @selected_node do %>
                <% %{"type" => "image", "image_data" => image_data} -> %>
                  <img src={image_data} alt="Document Image" class="max-w-full h-auto" />
                <% %{"type" => "table", "cells" => cells} -> %>
                  <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                      <%= for row <- cells do %>
                        <tr class="divide-x divide-gray-200">
                          <%= for cell <- row do %>
                            <td class="px-4 py-2 text-sm">{cell}</td>
                          <% end %>
                        </tr>
                      <% end %>
                    </table>
                  </div>
                <% %{"text" => text} when not is_nil(text) -> %>
                  <div class="prose max-w-none">
                    <p class="text-gray-700">{text}</p>
                  </div>
                <% %{"body" => body} -> %>
                  <div class="prose max-w-none">
                    <h1 class="text-2xl font-bold mb-4">Document Body</h1>
                    <%= if body["children"] do %>
                      <div class="space-y-4">
                        <%= for child <- body["children"] do %>
                          <%= case resolve_refs(child, @document) do %>
                            <% %{"text" => text} -> %>
                              <p class="text-gray-700">{text}</p>
                            <% _ -> %>
                              <div class="text-gray-500">Unsupported content type</div>
                          <% end %>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                <% _ -> %>
                  <div class="text-gray-500">
                    No content available for this node type
                  </div>
              <% end %>
            </div>
          <% else %>
            <div class="text-center text-gray-500">
              Select an item from the navigation tree to view its content
            </div>
          <% end %>
        </div>
      </div>

      <%!-- Metadata Panel --%>
      <div class="w-72 flex-shrink-0 border-l border-gray-200 bg-white overflow-y-auto">
        <div class="p-4">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">Properties</h2>
          <%= if @selected_node do %>
            <div class="space-y-4">
              <%= for {key, value} <- get_metadata_properties(@selected_node) do %>
                <div class="text-sm">
                  <div class="font-medium text-gray-700">{key}</div>
                  <div class="mt-1 text-gray-600 break-all">
                    {value}
                  </div>
                </div>
              <% end %>
            </div>
          <% else %>
            <div class="text-sm text-gray-500">
              Select an item to view its properties
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end

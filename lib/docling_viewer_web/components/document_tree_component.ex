defmodule DoclingViewerWeb.DocumentTreeComponent do
  @moduledoc """
  A LiveComponent that renders a hierarchical tree view of a document structure.

  This component handles:
  - Rendering document nodes with appropriate icons and labels
  - Recursive rendering of child nodes
  - Node selection and highlighting
  - Text truncation for long content
  - Reference resolution for linked content
  """

  use DoclingViewerWeb, :live_component

  @max_text_length 30
  @ellipsis "..."

  @impl true
  def render(assigns) do
    ~H"""
    <div class="document-tree">
      <%= if @node do %>
        <div class="tree-node">
          <button
            phx-click="select_node"
            phx-value-path={@node["path"]}
            class={"flex items-center space-x-2 w-full text-left px-2 py-1 rounded hover:bg-gray-100 #{if @selected_path == @node["path"], do: "bg-blue-100 hover:bg-blue-200", else: ""}"}
          >
            <.node_icon type={node_type(@node)} />
            <span class="text-sm truncate">{node_label(@node)}</span>
          </button>

          <%= if has_children?(@node) do %>
            <div class="pl-4 mt-1 border-l border-gray-200">
              <%= for child <- get_children(@node) do %>
                <.live_component
                  module={__MODULE__}
                  id={"tree-#{get_ref(child)}"}
                  node={child}
                  selected_path={@selected_path}
                />
              <% end %>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  def node_icon(assigns) do
    assigns = assign(assigns, :icon, get_icon(assigns.type))

    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      class="w-4 h-4"
    >
      <path stroke-linecap="round" stroke-linejoin="round" d={@icon} />
    </svg>
    """
  end

  def get_icon(type) do
    case type do
      "section" ->
        "M3.75 12h16.5m-16.5 3.75h16.5M3.75 19.5h16.5M5.625 4.5h12.75a1.875 1.875 0 010 3.75H5.625a1.875 1.875 0 010-3.75z"

      "paragraph" ->
        "M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"

      "table" ->
        "M3.375 19.5h17.25m-17.25 0a1.125 1.125 0 01-1.125-1.125M3.375 19.5h7.5c.621 0 1.125-.504 1.125-1.125m-9.75 0V5.625m0 12.75v-1.5c0-.621.504-1.125 1.125-1.125m18.375 2.625V5.625m0 12.75c0 .621-.504 1.125-1.125 1.125m1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125m0 3.75h-7.5A1.125 1.125 0 0112 18.375m9.75-12.75c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125m19.5 0v1.5c0 .621-.504 1.125-1.125 1.125M2.25 5.625v1.5c0 .621.504 1.125 1.125 1.125m0 0h17.25m-17.25 0h7.5c.621 0 1.125.504 1.125 1.125M3.375 8.25c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125m17.25-3.75h-7.5c-.621 0-1.125.504-1.125 1.125m8.625-1.125c.621 0 1.125.504 1.125 1.125v1.5c0 .621-.504 1.125-1.125 1.125m-17.25 0h7.5m-7.5 0c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125M12 10.875v-1.5m0 1.5c0 .621-.504 1.125-1.125 1.125M12 10.875c0 .621.504 1.125 1.125 1.125m-2.25 0c.621 0 1.125.504 1.125 1.125M13.125 12h7.5m-7.5 0c-.621 0-1.125.504-1.125 1.125M20.625 12c.621 0 1.125.504 1.125 1.125v1.5c0 .621-.504 1.125-1.125 1.125m-17.25 0h7.5M12 14.625v-1.5m0 1.5c0 .621-.504 1.125-1.125 1.125M12 14.625c0 .621.504 1.125 1.125 1.125m-2.25 0c.621 0 1.125.504 1.125 1.125m0 1.5v-1.5m0 0c0-.621.504-1.125 1.125-1.125m0 0h7.5"

      "image" ->
        "M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25 6v12a1.5 1.5 0 001.5 1.5zm10.5-11.25h.008v.008h-.008V8.25zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z"

      _ ->
        "M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z"
    end
  end

  def node_type(%{"type" => type}), do: type

  def node_type(%{"$ref" => ref}) do
    [_, type | _] = String.split(ref, "/")
    String.trim_trailing(type, "s")
  end

  def node_type(%{"body" => _}), do: "section"
  def node_type(_), do: "unknown"

  def node_label(%{"type" => type, "text" => text}) when not is_nil(text) do
    prefix = "#{String.capitalize(type)}: "
    max_text = @max_text_length - String.length(prefix)

    shortened =
      if String.length(text) > max_text,
        do: String.slice(text, 0..(max_text - 1)) <> @ellipsis,
        else: text

    prefix <> shortened
  end

  def node_label(%{"$ref" => ref}) do
    [_, type | _] = String.split(ref, "/")
    "Ref: #{String.capitalize(type)}"
  end

  def node_label(%{"body" => _}) do
    "Document Body"
  end

  def node_label(%{"type" => type}) do
    String.capitalize(type)
  end

  def node_label(_) do
    "Unknown Node"
  end

  def has_children?(%{"children" => children}) when is_list(children), do: true
  def has_children?(%{"body" => %{"children" => children}}) when is_list(children), do: true
  def has_children?(_), do: false

  def get_children(%{"children" => children}) when is_list(children), do: children
  def get_children(%{"body" => %{"children" => children}}) when is_list(children), do: children
  def get_children(_), do: []

  def get_ref(%{"$ref" => ref}), do: ref
  def get_ref(%{"path" => path}), do: path
  def get_ref(_), do: "unknown-#{System.unique_integer()}"
end

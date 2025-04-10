defmodule DoclingViewerWeb.DocumentTreeComponentTest do
  use DoclingViewerWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias DoclingViewerWeb.DocumentTreeComponent
  import DoclingViewer.DocumentFixtures

  describe "render" do
    test "renders empty state when no node is provided" do
      html =
        render_component(DocumentTreeComponent,
          id: "test",
          node: nil,
          selected_path: nil
        )

      refute html =~ "tree-node"
    end

    test "renders a node with children" do
      node = sample_tree_node()

      html =
        render_component(DocumentTreeComponent,
          id: "test",
          node: node,
          selected_path: nil
        )

      assert html =~ "tree-node"
      assert html =~ "Section"
      assert html =~ "Paragraph: Sample paragraph te..."
      assert html =~ "Ref: Tables"
    end

    test "highlights selected node" do
      node = sample_tree_node()

      html =
        render_component(DocumentTreeComponent,
          id: "test",
          node: node,
          selected_path: "section_1"
        )

      assert html =~ "bg-blue-100"
    end
  end

  describe "node_type/1" do
    test "returns correct type for regular nodes" do
      node = %{"type" => "paragraph"}
      assert DocumentTreeComponent.node_type(node) == "paragraph"
    end

    test "returns type from ref for reference nodes" do
      node = %{"$ref" => "#/tables/0"}
      assert DocumentTreeComponent.node_type(node) == "table"
    end

    test "returns section for body nodes" do
      node = %{"body" => %{}}
      assert DocumentTreeComponent.node_type(node) == "section"
    end

    test "returns unknown for unrecognized nodes" do
      node = %{}
      assert DocumentTreeComponent.node_type(node) == "unknown"
    end
  end

  describe "node_label/1" do
    test "returns label with truncated text for text nodes" do
      text = String.duplicate("a", 40)

      node = %{
        "type" => "paragraph",
        "text" => text
      }

      label = DocumentTreeComponent.node_label(node)
      # Account for "Paragraph: " prefix (10 chars) plus "..." (3 chars)
      # Total length should be: prefix (10) + truncated text (20) + ellipsis (3) = 33
      assert String.length(label) == 33
      assert String.ends_with?(label, "...")
      assert String.starts_with?(label, "Paragraph: ")
    end

    test "returns ref type for reference nodes" do
      node = %{"$ref" => "#/tables/0"}
      assert DocumentTreeComponent.node_label(node) == "Ref: Tables"
    end

    test "returns Document Body for body nodes" do
      node = %{"body" => %{}}
      assert DocumentTreeComponent.node_label(node) == "Document Body"
    end

    test "returns capitalized type for type-only nodes" do
      node = %{"type" => "section"}
      assert DocumentTreeComponent.node_label(node) == "Section"
    end

    test "returns Unknown Node for unrecognized nodes" do
      node = %{}
      assert DocumentTreeComponent.node_label(node) == "Unknown Node"
    end
  end

  describe "has_children?/1" do
    test "returns true for nodes with children array" do
      node = %{"children" => [%{}]}
      assert DocumentTreeComponent.has_children?(node)
    end

    test "returns true for body nodes with children" do
      node = %{"body" => %{"children" => [%{}]}}
      assert DocumentTreeComponent.has_children?(node)
    end

    test "returns false for nodes without children" do
      node = %{}
      refute DocumentTreeComponent.has_children?(node)
    end
  end

  describe "get_children/1" do
    test "returns children array for regular nodes" do
      children = [%{"type" => "text"}]
      node = %{"children" => children}
      assert DocumentTreeComponent.get_children(node) == children
    end

    test "returns children from body for body nodes" do
      children = [%{"type" => "text"}]
      node = %{"body" => %{"children" => children}}
      assert DocumentTreeComponent.get_children(node) == children
    end

    test "returns empty list for nodes without children" do
      node = %{}
      assert DocumentTreeComponent.get_children(node) == []
    end
  end

  describe "get_ref/1" do
    test "returns ref for reference nodes" do
      ref = "#/tables/0"
      node = %{"$ref" => ref}
      assert DocumentTreeComponent.get_ref(node) == ref
    end

    test "returns path for nodes with path" do
      path = "some/path"
      node = %{"path" => path}
      assert DocumentTreeComponent.get_ref(node) == path
    end

    test "returns unique identifier for other nodes" do
      node = %{}
      ref = DocumentTreeComponent.get_ref(node)
      assert is_binary(ref)
      assert String.starts_with?(ref, "unknown-")
    end
  end
end

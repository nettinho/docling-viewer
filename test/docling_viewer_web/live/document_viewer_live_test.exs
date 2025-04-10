defmodule DoclingViewerWeb.DocumentViewerLiveTest do
  use DoclingViewerWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import DoclingViewer.DocumentFixtures
  import Mock

  describe "mount" do
    test "renders document structure when JSON is valid", %{conn: conn} do
      with_mock File, read: fn _ -> {:ok, Jason.encode!(sample_document())} end do
        {:ok, _view, html} = live(conn, "/")

        assert html =~ "Document Structure"
        assert html =~ "Select an item from the navigation tree"
        refute html =~ "Failed to parse document"
        refute html =~ "Failed to load document"
      end
    end

    test "shows error when JSON file cannot be read", %{conn: conn} do
      with_mock File, read: fn _ -> {:error, :enoent} end do
        {:ok, _view, html} = live(conn, "/")

        assert html =~ "Failed to load document"
      end
    end

    test "shows error when JSON is invalid", %{conn: conn} do
      with_mock File, read: fn _ -> {:ok, "invalid json"} end do
        {:ok, _view, html} = live(conn, "/")

        assert html =~ "Failed to parse document"
      end
    end
  end

  describe "node selection" do
    test "displays text content when text node is selected", %{conn: conn} do
      document = sample_document()

      with_mock File, read: fn _ -> {:ok, Jason.encode!(document)} end do
        {:ok, view, _html} = live(conn, "/")

        html =
          view
          |> element("button[phx-value-path='text_0']")
          |> render_click()

        assert html =~ "Sample text content"
      end
    end

    test "displays table when table node is selected", %{conn: conn} do
      document = sample_document()

      with_mock File, read: fn _ -> {:ok, Jason.encode!(document)} end do
        {:ok, view, _html} = live(conn, "/")

        html =
          view
          |> element("button[phx-value-path='table_0']")
          |> render_click()

        assert html =~ "A1"
        assert html =~ "B2"
      end
    end

    test "displays image when image node is selected", %{conn: conn} do
      document = sample_document()

      with_mock File, read: fn _ -> {:ok, Jason.encode!(document)} end do
        {:ok, view, _html} = live(conn, "/")

        html =
          view
          |> element("button[phx-value-path='picture_0']")
          |> render_click()

        assert html =~ "data:image/png;base64,abc123"
      end
    end
  end

  describe "reference resolution" do
    test "resolves text references correctly", %{conn: conn} do
      document = sample_document()

      with_mock File, read: fn _ -> {:ok, Jason.encode!(document)} end do
        {:ok, view, _html} = live(conn, "/")

        # Get a reference to a text node
        text_ref =
          get_in(document, ["body", "children"]) |> Enum.find(&(&1["$ref"] == "#/texts/0"))

        html =
          view
          |> element("button[phx-value-path='#{text_ref["path"]}']")
          |> render_click()

        assert html =~ "Sample text content"
      end
    end

    test "resolves table references correctly", %{conn: conn} do
      document = sample_document()

      with_mock File, read: fn _ -> {:ok, Jason.encode!(document)} end do
        {:ok, view, _html} = live(conn, "/")

        # Get a reference to a table node
        table_ref =
          get_in(document, ["body", "children"]) |> Enum.find(&(&1["$ref"] == "#/tables/0"))

        html =
          view
          |> element("button[phx-value-path='#{table_ref["path"]}']")
          |> render_click()

        assert html =~ "A1"
        assert html =~ "B2"
      end
    end

    test "resolves image references correctly", %{conn: conn} do
      document = sample_document()

      with_mock File, read: fn _ -> {:ok, Jason.encode!(document)} end do
        {:ok, view, _html} = live(conn, "/")

        # Get a reference to an image node
        image_ref =
          get_in(document, ["body", "children"]) |> Enum.find(&(&1["$ref"] == "#/pictures/0"))

        html =
          view
          |> element("button[phx-value-path='#{image_ref["path"]}']")
          |> render_click()

        assert html =~ "data:image/png;base64,abc123"
      end
    end
  end

  describe "metadata panel" do
    test "displays node properties when node is selected", %{conn: conn} do
      document = sample_document()

      with_mock File, read: fn _ -> {:ok, Jason.encode!(document)} end do
        {:ok, view, _html} = live(conn, "/")

        html =
          view
          |> element("button[phx-value-path='text_0']")
          |> render_click()

        assert html =~ "Path"
        assert html =~ "text_0"
        assert html =~ "Type"
        assert html =~ "text"
      end
    end

    test "hides sensitive properties in metadata panel", %{conn: conn} do
      document = sample_document()

      with_mock File, read: fn _ -> {:ok, Jason.encode!(document)} end do
        {:ok, view, _html} = live(conn, "/")

        html =
          view
          |> element("button[phx-value-path='text_0']")
          |> render_click()

        # Check that sensitive properties are not shown in the metadata panel
        refute html =~ ~r/class="font-medium text-gray-700">Text</
        refute html =~ ~r/class="font-medium text-gray-700">Children</
        refute html =~ ~r/class="font-medium text-gray-700">Image_data</
        refute html =~ ~r/class="font-medium text-gray-700">Cells</
        refute html =~ ~r/class="font-medium text-gray-700">Body</
      end
    end
  end
end

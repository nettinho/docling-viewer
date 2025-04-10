defmodule DoclingViewer.DocumentFixtures do
  @moduledoc """
  Test fixtures for document-related tests.

  This module provides sample document structures that match the expected format
  of documents in the application, including:
  - Document body with references
  - Text content
  - Tables
  - Images
  - Nested document structures
  """

  @doc """
  Returns a sample document structure for testing.
  """
  def sample_document do
    %{
      "body" => %{
        "children" => [
          %{
            "$ref" => "#/texts/0",
            "path" => "text_0"
          },
          %{
            "$ref" => "#/tables/0",
            "path" => "table_0"
          },
          %{
            "$ref" => "#/pictures/0",
            "path" => "picture_0"
          }
        ]
      },
      "texts" => [
        %{
          "type" => "text",
          "text" => "Sample text content",
          "path" => "text_0"
        }
      ],
      "tables" => [
        %{
          "type" => "table",
          "cells" => [["A1", "B1"], ["A2", "B2"]],
          "path" => "table_0"
        }
      ],
      "pictures" => [
        %{
          "type" => "image",
          "image_data" => "data:image/png;base64,abc123",
          "path" => "picture_0"
        }
      ]
    }
  end

  @doc """
  Returns a sample node for testing the tree component.
  """
  def sample_tree_node do
    %{
      "type" => "section",
      "path" => "section_1",
      "children" => [
        %{
          "type" => "paragraph",
          "text" => "Sample paragraph text",
          "path" => "para_1"
        },
        %{
          "$ref" => "#/tables/0",
          "path" => "table_ref_1"
        }
      ]
    }
  end
end

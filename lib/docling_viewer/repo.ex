defmodule DoclingViewer.Repo do
  use Ecto.Repo,
    otp_app: :docling_viewer,
    adapter: Ecto.Adapters.Postgres
end

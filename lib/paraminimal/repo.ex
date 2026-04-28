defmodule Paraminimal.Repo do
  use Ecto.Repo,
    otp_app: :paraminimal,
    adapter: Ecto.Adapters.Postgres
end

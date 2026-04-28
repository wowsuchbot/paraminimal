# Getting Started

## Prerequisites

- **Elixir** 1.14+ (`elixir -v`)
- **Erlang/OTP** 25+ (`erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell`)
- **Postgres** 14+ (`psql --version`)
- **Node.js** 18+ (for assets) (`node -v`)
- **Phoenix** (`mix archive.install hex phx_new`)

## Clone

```bash
git clone git@github.com:wowsuchbot/paraminimal.git
cd paraminimal
```

## Setup

```bash
# Install Elixir deps
mix deps.get

# Install Node deps (after Phoenix scaffold is in place)
cd assets && npm install && cd ..

# Setup database
mix ecto.setup
```

## Run

```bash
# Start Phoenix server
mix phx.server
# → http://localhost:4000

# Or with iex for live debugging
iex -S mix phx.server
```

## Environment

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

Required vars (for production deploy):

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | Postgres connection string |
| `SECRET_KEY_BASE` | Phoenix encryption key (`mix phx.gen.secret`) |
| `PORT` | Phoenix port (default 4000) |

## Deployment

Server: existing mxjxn.com infra. Caddy reverse proxy to `paraminimal.mxjxn.com`.

Process management: pm2 or systemd (TBD based on perf testing).

```bash
# Build release
MIX_ENV=prod mix release

# Or for development deploy
mix phx.server
```

## Testing

```bash
mix test                          # unit + integration
mix test --only composition       # composition engine tests
mix test --only transitions       # transition system tests
```

# paraminimal

Generative multiplayer music experience. Deterministic, time-synchronized, endless.

Inspired by Gödel, Escher, Bach — strange loops, self-reference, formal systems that contain themselves.

## Stack

- **Elixir / Phoenix LiveView** — server-rendered UI, server-authoritative epoch state
- **SuperSonic** (SuperCollider WASM) — client-side audio synthesis
- **Postgres** — epoch history, sessions, interactions
- **Smart contracts** (later) — moment NFTs, influence registry

## Deploy

`paraminimal.mxjxn.com` — Caddy reverse proxy to Phoenix port.

## Repo

[wowsuchbot/paraminimal](https://github.com/wowsuchbot/paraminimal) (private)

# Phase 5: Multiplayer & Persistence

## Goal

Make Paraminimal a shared synchronized experience. Multiple listeners should receive the same server-authoritative musical state, and epoch history should become queryable.

## Core Work

### Presence

Add Phoenix Presence to track connected listeners.

Initial behavior:

- Track active listener count.
- Display listener count in the LiveView.
- Broadcast join and leave changes.

Presence should not affect music at first. Listener influence belongs to Phase 6.

### Persistence

Use Postgres for epoch and session history.

Initial schemas:

- Epoch: id, period, scale, root, energy, density, transition state, generated timestamp, full serialized state.
- Session: listener/session identifier, connected_at, disconnected_at.

The composition engine should remain pure. Persistence should store the output of the engine, not become part of the engine itself.

### Server-Authoritative Sync

Move from per-LiveView local recomputation toward a shared broadcast model.

Target flow:

1. Server computes the current epoch.
2. Server persists or reuses the epoch record.
3. PubSub broadcasts state changes.
4. Connected LiveViews receive and render the same state.
5. Late joiners receive the current state immediately.

## Deliverable

Two browser tabs should show the same epoch and transition state, receive synchronized updates, and expose a listener count. Epoch history should be stored in Postgres and queryable from the app or IEx.

## Verification

- Presence tests cover join/leave behavior.
- Epoch persistence tests cover insert/reuse behavior.
- Multiple LiveViews receive the same broadcast state.
- Late joiners render the current epoch without waiting for the next tick.

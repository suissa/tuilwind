# Actor runtime and component catalog

The Actor layer is an optional module: source `compat.sh`, `ord.sh`, and `tui.sh`, then source `actor.sh`. It does not start a second event loop and does not fork processes. Actors are records in a process-local registry; the existing `event.sh` and `host.sh` remain the event and composition owners.

## Runtime API

- `tuish_actor_create ID TYPE [PARENT]`: register a component and initialize lifecycle state.
- `tuish_actor_set ID KEY VALUE` / `tuish_actor_get ID KEY`: access validated properties. Read values from `TUISH_ACTOR_VALUE`.
- `tuish_actor_on ID EVENT FUNCTION`: register a named callback.
- `tuish_actor_send ID MESSAGE`: deliver a message synchronously to the Actor callback.
- `tuish_actor_start ID`, `tuish_actor_stop ID`, `tuish_actor_destroy ID`: lifecycle.
- `tuish_actor_step ID ACTION [VALUE]`: shared state transitions for selection, progress, expansion, scrolling, confirmation and cancellation.\n- `tuish_actor_action ID ACTION [VALUE]`: type-checked domain actions for each component (e.g. `seek`, `ratio`, `input`, `scroll`, `tick`, `navigate`, `source`, `register`, `validate`).
- `tuish_actor_render_text ID [LABEL]`: minimal text representation; use the existing drawing primitives for full layouts.

Actor IDs and property keys are restricted to shell-safe identifiers. Property values cannot contain a newline or the record separator `|`; this prevents malformed registry records and avoids evaluating user-provided data as shell code. Callbacks are function names, never source strings.

## Component types

The runtime recognizes the components tracked by the project issues: progress, slide-motion, table, tree, split-view, text-input, text-area, viewport, spinner, tabs, mouse-adapter, fullscreen, command-launcher, list, help, keymap, cursor, confirm-dialog, file-picker, timer, paginator, markdown, code-editor, bics-plugin and bics-plugin-cli. Each component can own arbitrary validated properties and callbacks while using the common lifecycle and state transition contract. Existing primitives (viewport, canvas, buffer, key bindings, HID, host and draw) remain the rendering/input implementations; the Actor layer does not duplicate them.

This is deliberately a foundation, not a claim that all 25 component types have bespoke rendering implementations. Component-specific rendering and input adapters can be added incrementally without changing the Actor contract.

The first concrete component adapter is [Progress](progress.md), which adds clamped percentage updates, resize handling, animation ticks, and a reusable text renderer.

## Live dashboard

Run `sh examples/agent_dashboard.sh` in a terminal. It refreshes host, OS, uptime, load average, memory use, process count and terminal/session information, and manages three heartbeat worker processes. Use Up/Down to select an agent, Enter to start/stop it, R to redraw, and Q to exit. The worker processes are lifecycle demonstrations, not production AI agents; replace their heartbeat body with an application-owned agent command.

Metrics are best-effort. Linux procfs supplies uptime, load, memory and process counts; unavailable values are shown as `n/a`. No root privileges or external monitoring service is required.

## Tests and CI

`tests/unit/test_actors.sh` runs through the existing unit-test glob in `.github/workflows/ci.yml`, across the shell matrix. It verifies registration, type identity, lifecycle, message delivery, selection transitions and destruction for every supported component type. The test does not assert that each component already has a bespoke renderer.

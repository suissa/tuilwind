# Actor runtime and Elm/MVU message broker

The Actor layer is an optional module: source `compat.sh`, `ord.sh`, and `tui.sh`, then source `actor.sh`. It does not start a second event loop and does not fork processes. Actors are process-local records; the existing `event.sh` and `host.sh` remain the event-loop and composition owners.

## Runtime API

- `tuish_actor_create ID TYPE [PARENT]`: register an Actor and initialize lifecycle state.
- `tuish_actor_set ID KEY VALUE` / `tuish_actor_get ID KEY`: access validated properties. Read values from `TUISH_ACTOR_VALUE`.
- `tuish_actor_on ID EVENT FUNCTION`: register a named callback. Callbacks are function names, never evaluated source.
- `tuish_actor_program ID MESSAGE UPDATE VIEW EFFECT [CHILD_MESSAGE] [INIT] [SHUTDOWN]`: register the Elm/MVU behavior callbacks.
- `tuish_actor_post ID MSG`: append a message to the process-wide FIFO mailbox without dispatching.
- `tuish_actor_send ID MSG`: append and synchronously drain the FIFO mailbox.
- `tuish_actor_dispatch`: drain queued messages. Dispatch is non-reentrant; messages posted by a callback are appended and processed after the current message. The configurable `TUISH_ACTOR_DISPATCH_LIMIT` (default 256) bounds a drain; status 75 means work remains and a later dispatch can continue it.
- `tuish_actor_send_child CHILD MSG`: send a child-originated message to its registered parent through `on_child_message`.
- `tuish_actor_cmd ID EFFECT`: enqueue an effect descriptor. Effects run after the current update via `on_effect`; they are data, not shell source.
- `tuish_actor_render ID [ARG]`: invoke the view callback separately from update.
- `tuish_actor_start ID`, `tuish_actor_stop ID`, `tuish_actor_destroy ID`: lifecycle operations.

The message flow is `Event → Msg → Update(state) → View(render) → Cmd(effects)`. Message and update callbacks receive `ACTOR_ID MESSAGE`; view and effect callbacks receive `ACTOR_ID ARG`; the child-message callback receives `PARENT_ID CHILD_ID|MESSAGE`. Init and shutdown callbacks receive the Actor ID. Update logic is application-owned and should remain deterministic; I/O belongs in the effect callback. The view callback is invoked by the app's existing redraw handler, not automatically by the broker.

Messages/effect descriptors cannot contain newlines or the record separator `|`. Actor IDs and property keys are restricted to shell-safe identifiers. This keeps the in-memory protocol parseable and prevents user data from becoming shell code.

## Lifecycle and terminal safety

The Actor module does not own terminal mode. Applications should keep terminal setup and teardown in the existing `tuish_init` / `tuish_fini` lifecycle, whose EXIT and signal traps restore the saved `stty` state. Actor shutdown callbacks are invoked by `tuish_actor_destroy`; applications should use them to release Actor-owned resources, not to replace terminal restoration.

## Components

The runtime recognizes the component types tracked by the project issues: progress, slide-motion, table, tree, split-view, text-input, text-area, viewport, spinner, tabs, mouse-adapter, fullscreen, command-launcher, list, help, keymap, cursor, confirm-dialog, file-picker, timer, paginator, markdown, code-editor, bics-plugin and bics-plugin-cli. Component-specific adapters continue to use the existing drawing, canvas, buffer, HID, event and host modules.

## Example and tests

Run `sh examples/actor_mvu_demo.sh` for a parent/child broker walkthrough. `tests/unit/test_actor_mvu.sh` verifies FIFO ordering, non-reentrant posts, effects, separate view dispatch, child-to-parent delivery, lifecycle callbacks and message validation. The normal unit-test glob includes it in the existing shell matrix.

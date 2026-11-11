# Progress Actor

Source `src/actor.sh` and `src/progress.sh` to use the standalone progress component.

```sh
tuish_progress_create build 30 "Build"
tuish_actor_on build tick on_build_tick
tuish_actor_on build progress_change on_progress_changed
tuish_actor_on build render on_progress_render
tuish_actor_on build resize on_progress_resize

tuish_progress_start build
tuish_progress_set build 65
tuish_progress_tick build       # called by the application's idle/timer event
tuish_progress_render build
tuish_progress_resize build 40  # call from the terminal resize event
tuish_progress_stop build       # stop before destroying the Actor
tuish_actor_destroy build
```

The component stores percentage, width, label, animation frame and active state on the Actor. Percentages are clamped to 0–100; invalid non-integer values are rejected. Width is restricted to 1–200 columns. Rendering emits a portable ASCII bar and percentage; optional `start_color` and `end_color` Actor properties accept numeric ANSI SGR parameters.

## Event contract

The Actor runtime dispatches registered callbacks synchronously through `tuish_actor_send`. The progress component emits:

- `progress_change` after a clamped percentage update;
- `tick` after advancing the animated marker;
- `render` immediately before producing the frame;
- `resize` after accepting a new width.

Register callbacks with `tuish_actor_on ID EVENT FUNCTION`. The application owns the clock: call `tuish_progress_tick` from its idle/timer event and render after a state change. The module deliberately creates no timer, fork, or background process. `tuish_progress_start` and `tuish_progress_stop` are idempotent lifecycle transitions; ticks are ignored while stopped. This makes non-TTY/static rendering deterministic and gives the caller an explicit cleanup point.

Run `sh examples/progress_demo.sh` for a standalone demonstration.

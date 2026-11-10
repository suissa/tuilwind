# Progress Actor

Source `src/actor.sh` and `src/progress.sh` to use the standalone progress component.

```sh
tuish_progress_create build 30 "Build"
tuish_progress_set build 65
tuish_progress_render build
tuish_progress_tick build
tuish_progress_resize build 40
tuish_actor_destroy build
```

The API stores percentage, width, label and animation state on the Actor. Percentages are clamped to 0–100; invalid non-integer values are rejected. Width is restricted to 1–200 columns. Rendering emits a portable ASCII bar and percentage; optional `start_color` and `end_color` Actor properties accept numeric ANSI SGR parameters. The start color is used until completion and the end color at 100%.

Run `sh examples/progress_demo.sh` for a standalone animated demonstration. The demo uses a bounded sleep loop; the component itself does not create timers or background processes.

# SlideMotion Actor

Source `src/actor.sh` and `src/slide_motion.sh` to use a deterministic timeline with explicit time advancement and frame scrubbing.

```sh
tuish_motion_create intro 10000 101 "Intro"
tuish_motion_set_trajectory intro "chapter-1,chapter-2"
tuish_motion_enter intro
tuish_motion_advance intro 250
tuish_motion_scrub intro 50
tuish_motion_wait intro
tuish_motion_resume intro
tuish_motion_finish intro
tuish_motion_render intro
tuish_actor_destroy intro
```

The `trajectory` property stores an optional application-owned descriptor through `tuish_motion_set_trajectory ID VALUE`; the core adapter does not interpret that descriptor. The current frame/time mapping is driven by `duration_ms` and `frame_count`, with `easing_type` initialized to `linear`.

The API uses zero-based frame indexes. `duration_ms` must be a positive integer and `frame_count` must be between 1 and 100000. Advancing by an elapsed-time delta maps time to a frame with integer arithmetic; the last frame is reached exactly at the duration boundary. Scrubbing maps a frame back to its corresponding elapsed time and clamps out-of-range frames to the first or last frame.

The caller owns the clock: `tuish_motion_advance` consumes an explicit millisecond delta and never sleeps, polls, starts a timer or runs a background loop. A timeline starts in `idle`, enters `running`, can transition to `waiting`, and ends in `finished`, `exited` or `cancelled`. A finished timeline cannot advance again; a waiting timeline must be resumed before advancing.

Register callbacks with `tuish_actor_on ID enter|advance|scrub|wait|exit|finish|resize FUNCTION`. The callback receives the Actor ID and event payload (frame index for advance/scrub/finish, frame count for resize). The generic `tuish_actor_action ID seek|advance|enter|wait|resume|exit|finish|cancel VALUE` routes to the adapter when this module is loaded.

Run `sh examples/slide_motion_demo.sh` for a blocking command-driven demo: `n` advances one second, `p` scrubs backward one frame, `w` waits, `r` resumes and `q` exits. Input is line-based so it works without shell-specific key-reading extensions.

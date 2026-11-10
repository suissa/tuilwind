# SplitView Actor

Source `actor.sh`, then `split_view.sh`. The adapter calculates bounded logical pane rectangles; it does not write terminal escape sequences or start another event loop. Feed its geometry to `tuish_host_slot` / `tuish_host_commit` to mount child applications, or draw directly through `canvas.sh`.

## API

- `tuish_split_view_create ID horizontal|vertical WIDTH HEIGHT [RATIO] [GAP]`
- `tuish_split_view_add_pane ID PANE_ID [LABEL]` (two panes maximum)
- `tuish_split_view_set_ratio ID 1..99`
- `tuish_split_view_set_gap ID 0..20`
- `tuish_split_view_set_constraints ID MIN_FIRST MIN_SECOND`
- `tuish_split_view_resize ID WIDTH HEIGHT`
- `tuish_split_view_focus ID PANE_ID`
- `tuish_split_view_pointer ID X Y` (sets `TUISH_SPLIT_VIEW_HIT`)
- `tuish_split_view_child_exit ID PANE_ID`
- `tuish_split_view_layout ID` (prints one `pane|row|column|width|height` record per pane)
- `tuish_split_view_render ID` (prints a compact textual layout)

Horizontal means side-by-side; vertical means stacked. Coordinates are 1-based. The gap is excluded from both pane rectangles. The ratio is the first pane's percentage of the remaining dimension after the gap. Minimum constraints are enforced before geometry is committed; an undersized resize fails with status 2 and leaves the previous valid dimensions intact. Stable pane IDs preserve focus across resize. If a child exits, it is removed and the remaining pane expands to the full region.

Callbacks: `data_change`, `layout`, `focus`, `resize`, `pointer`, `child_exit`, and `render`. Callback functions receive the SplitView ID and event payload.

Run `sh examples/split_view_demo.sh` for a geometry and resize demonstration.

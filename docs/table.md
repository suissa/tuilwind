# Interactive Data Table Actor

Source `src/actor.sh` and `src/table.sh`. The table stores headers, rows, widths, cursor, stable row keys and viewport state in the common Actor registry.

```sh
tuish_table_create inventory 3 3 10
tuish_table_set_header inventory 1 Product
tuish_table_set_header inventory 2 Quantity
tuish_table_set_header inventory 3 Status
tuish_table_set_row inventory 1 sku-1 Keyboard 12 Available
tuish_table_set_row inventory 2 sku-2 Mouse 4 Pending
tuish_table_set_row inventory 3 sku-3 Monitor 8 Available
tuish_table_select inventory 2
tuish_table_move inventory 1
tuish_table_scroll inventory 1
tuish_table_resize inventory 5
tuish_table_render inventory
tuish_actor_destroy inventory
```

Rows and columns are one-based. Column count is fixed at creation (1–64); row count may be changed with `tuish_table_set_rows ID COUNT`. Each row is assigned a stable key and exactly one value per column through `tuish_table_set_row ID ROW KEY CELL...`. Individual cells can be changed with `tuish_table_set_cell`; headers and column widths use `tuish_table_set_header` and `tuish_table_set_width`.

Selection is tracked by both cursor position and stable row key. When rows are reordered and the selected key is found at a new index, the cursor follows that key. Navigation is clamped to the available rows; viewport offset is adjusted to keep the selected row visible. The renderer truncates cells to configured display widths, using `str.sh` Unicode-aware display-width handling when that module is loaded. Empty datasets retain their header and show the configured empty-state label.

Callbacks can be registered with `tuish_actor_on ID data_change|select|scroll|resize|render FUNCTION`. They receive the Actor ID and an event payload. Generic actions are available through `tuish_actor_action ID next|previous|select|scroll|resize|render VALUE`.

Run `sh examples/table_demo.sh` for a command-driven interactive example. Enter `j` / `k` to move, `s` to scroll, `r` to resize the viewport, and `q` to exit.

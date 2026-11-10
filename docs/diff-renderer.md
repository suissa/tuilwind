# DiffRenderer

The DiffRenderer compares a current CellBuffer with a renderer-owned snapshot and emits only changed cells. It redraws a cell when its glyph, foreground, background or SGR attributes change.

## API

- `tuish_diff_render PREVIOUS CURRENT [force]` compares frames, draws the differences and then replaces PREVIOUS with a snapshot of CURRENT.
- `tuish_diff_invalidate` forces a full redraw on the next call. Use it after terminal reset, resize or external writes to the screen.
- `TUISH_DIFF_CHANGED_CELLS` reports how many populated or removed cells were redrawn by the last call.

Source `diff.sh` after `cellbuf.sh`, `term.sh`, `str.sh` and `draw.sh`.

PREVIOUS is owned by the renderer: do not mutate it between calls. CURRENT remains application-owned and can be changed between frames. The first call, a dimension change, or explicit invalidation clears the affected viewport before drawing the current frame. A removed cell is erased with spaces spanning its previous display width. Shorter replacement text is padded to the old width so trailing characters do not remain on screen.

## Example

```sh
tuish_cellbuf_init frame 60 16
tuish_cellbuf_set frame 2 3 'TUILWIND // LIVE' fg=51 attrs=1
tuish_diff_render previous frame

# Update only one cell in the next frame.
tuish_cellbuf_set frame 2 3 'TUILWIND // READY' fg=51 attrs=1
tuish_diff_render previous frame
printf 'Redrawn cells: %s\n' "$TUISH_DIFF_CHANGED_CELLS"
```

The renderer treats each stored glyph as a drawable text run anchored at its row and column. The width calculation uses `str.sh` when loaded; the fallback counts shell characters and is intended for simple ASCII-only environments.

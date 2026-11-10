# CellBuffer and Compositor

The CellBuffer is a sparse, named grid. A cell stores a glyph and optional foreground, background and attribute metadata. Coordinates are 1-based. Unset cells are transparent, so overlays do not erase content beneath them.

## CellBuffer API

- `tuish_cellbuf_init NAME WIDTH HEIGHT`
- `tuish_cellbuf_size NAME` → `TUISH_CELLBUF_WIDTH`, `TUISH_CELLBUF_HEIGHT`
- `tuish_cellbuf_set NAME ROW COL GLYPH [fg=N] [bg=N] [attrs=TEXT]`
- `tuish_cellbuf_get NAME ROW COL` → `TUISH_CELL_GLYPH`, `TUISH_CELL_FG`, `TUISH_CELL_BG`, `TUISH_CELL_ATTRS`
- `tuish_cellbuf_clear NAME`
- `tuish_cellbuf_fill NAME GLYPH [FG] [BG]`

Buffer names use letters, digits, underscore and hyphen. Glyphs and metadata cannot contain the record separator (`|`) or newlines. Invalid coordinates and malformed values are rejected.

## Layered composition

Source `compositor.sh` after `cellbuf.sh` and `draw.sh`.

- `tuish_compositor_add BUFFER Z` registers or updates a layer.
- `tuish_compositor_remove BUFFER` removes it.
- `tuish_compositor_clear` removes every layer.
- `tuish_compositor_compose TARGET` clears TARGET and composites registered layers in ascending z-order. Higher z values cover lower ones; equal z values preserve registration order.
- `tuish_compositor_render BUFFER` paints populated cells through `tuish_draw_text`.

The implementation uses portable shell strings and sparse records: no associative arrays, external processes or new terminal escape handling. Composition is intentionally separate from rendering, so tests and applications can inspect the finished frame before writing it to the terminal.

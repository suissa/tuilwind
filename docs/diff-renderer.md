# DiffRenderer

Source `diff_renderer.sh` after `cellbuf.sh` and `draw.sh`.

The renderer compares two named CellBuffers with identical dimensions and emits only changed cells through `tuish_draw_text`. It compares glyph, foreground, background and SGR attributes. Sparse cells are transparent in the CellBuffer; when a populated cell disappears from the current frame, the renderer writes a blank at that coordinate.

## API

- `tuish_diff_render PREVIOUS CURRENT` — emit only changed cells. Returns status 2 when dimensions differ and status 1 when either buffer is unknown.
- `tuish_diff_render_full CURRENT` — paint the complete rectangular buffer, including blank cells. Use for the initial frame.
- `tuish_diff_invalidate` — force the next `tuish_diff_render` call to perform a full render. Call after resize, terminal reset, alternate-screen changes, or any write that bypasses the renderer.

The diff is deterministic and keeps frame composition separate from terminal output. It uses shell built-ins and the existing CellBuffer/Draw APIs; it adds no process or runtime dependency. The caller owns the previous-frame buffer and should update it only after a successful render.

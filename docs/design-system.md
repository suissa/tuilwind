# Futuristic Design System

Source `theme.sh` after `term.sh`, then `ui.sh` after `draw.sh`. These modules add a semantic palette and reusable visual primitives without changing the terminal lifecycle or existing drawing APIs.

## Visual direction

The default `cyber` theme uses near-black surfaces, cyan as the primary signal, violet as a secondary accent, subdued borders and restrained semantic colors. `midnight` is lower contrast; `mono` is a monochrome fallback. Colors use the terminal's 256-color palette.

## Theme API

- `tuish_theme_use cyber|midnight|mono`
- `tuish_theme_set TOKEN 0..255`
- `tuish_theme_get TOKEN` (result in `TUISH_THEME_VALUE`)

Tokens: `bg`, `surface`, `surface_alt`, `text`, `muted`, `primary`, `secondary`, `success`, `warning`, `danger`, `border`, `focus`.

## UI primitives

- `tuish_ui_panel ROW COL WIDTH HEIGHT TITLE [state=active|idle|warning|danger]`
- `tuish_ui_badge ROW COL LABEL [tone=primary|success|warning|danger|muted]`
- `tuish_ui_progress ROW COL WIDTH PERCENT [LABEL]`
- `tuish_ui_section ROW COL TEXT [tone=primary|muted]`

All primitives delegate positioning, clipping and border rendering to existing `draw.sh` and `term.sh` APIs. The progress bar uses Unicode block glyphs; applications targeting ASCII-only terminals can keep using the lower-level drawing primitives or select a future ASCII variant.

Run `sh examples/futuristic_dashboard.sh` to see the visual language in a dashboard composition.

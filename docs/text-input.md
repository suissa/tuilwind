# TextInput Actor

Source `actor.sh`, `str.sh`, then `text_input.sh`. This adapter owns single-line editing state and does not start an event loop or alter terminal modes.

## API

- `tuish_text_input_create ID [PLACEHOLDER] [MAX_LENGTH] [MASK_CHAR]`
- `tuish_text_input_set ID TEXT`
- `tuish_text_input_insert ID TEXT`
- `tuish_text_input_move ID DELTA`
- `tuish_text_input_backspace ID`
- `tuish_text_input_delete ID`
- `tuish_text_input_paste ID [TEXT]` (uses `TUISH_PASTE` when set)
- `tuish_text_input_focus ID 0|1`
- `tuish_text_input_validate ID [FUNCTION]`
- `tuish_text_input_render ID`

The cursor is a zero-based grapheme-cluster index and is clamped to the value bounds. Combining marks, variation selectors, emoji skin-tone modifiers, regional-indicator pairs and common ZWJ emoji sequences are treated as single cursor/deletion units. The maximum length is measured in grapheme clusters; zero means unlimited. Input and paste remove C0 control bytes and DEL before insertion. Over-limit writes fail with status 2 and do not truncate. A non-empty mask character replaces each codepoint in rendered output while the stored value remains unchanged.

The adapter deliberately keeps terminal lifecycle outside the component: applications that enable raw mode, bracketed paste or other device features must restore them in their normal `tuish_fini` path. Validation functions receive the value as their first argument and return zero for valid input.

Run `sh examples/text_input_demo.sh` for a minimal state/editing demonstration.

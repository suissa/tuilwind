# Expandable Tree View Actor

Source `actor.sh`, then `tree.sh`. The adapter stores a flat, stable-ID node registry in the Actor record store; parent links define the hierarchy. No subprocesses or external utilities are required.

## API

- `tuish_tree_create TREE_ID [ROOT_LABEL] [VISIBLE_ROWS]`
- `tuish_tree_add_node TREE_ID NODE_ID PARENT_ID LABEL`
- `tuish_tree_set_label TREE_ID NODE_ID LABEL`
- `tuish_tree_set_parent TREE_ID NODE_ID PARENT_ID` (rejects root reparenting and ancestry cycles)
- `tuish_tree_select TREE_ID NODE_ID` (only currently visible nodes)
- `tuish_tree_move TREE_ID DELTA` (clamped keyboard-style navigation)
- `tuish_tree_toggle TREE_ID [NODE_ID]` (defaults to selected node)
- `tuish_tree_resize TREE_ID VISIBLE_ROWS`
- `tuish_tree_render TREE_ID`

Node IDs are stable shell-safe identifiers and remain unchanged when labels or parent positions change. Adding a node requires an existing parent. The tree enforces an internal maximum of 10,000 nodes and 64 levels; attempts to exceed either bound are rejected before the hierarchy is mutated. Render output is clipped to the configured viewport and selection is preserved by ID while the node remains visible. If a collapsed branch hides the selected node, selection returns to the root.

Callbacks: `data_change`, `select`, `expand`, `collapse`, `toggle`, `navigate`, `resize`, and `render`. Callback functions receive the tree ID and the event payload.

Run `sh examples/tree_demo.sh` for a keyboard-navigation demonstration.

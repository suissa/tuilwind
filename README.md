<!--
SPDX-FileCopyrightText: 2026 Alexandre Gomes Gaigalas <alganet@gmail.com>

SPDX-License-Identifier: ISC
-->

# tuilwind

A terminal UI toolkit written in portable shell scripts. It provides terminal lifecycle management, event handling, drawing primitives, text and layout utilities, and optional UI components. No compilation step is required.

![Demo](https://i.imgur.com/t8NZbSe.gif)

## Quick start

Load the core modules in dependency order, then register event handlers and start the application:

```sh
#!/bin/sh
. ./src/compat.sh
. ./src/ord.sh
. ./src/tui.sh
. ./src/term.sh
. ./src/event.sh
. ./src/hid.sh
. ./src/keybind.sh

tuish_bind 'ctrl-w' 'tuish_quit'
tuish_bind 'idle' '_render'

_render () {
    tuish_vmove 1 1
    tuish_print "Hello from tuilwind -- press Ctrl+W to quit"
}

tuish_start
```

## Implemented modules

All modules are optional unless an application uses their API. Load `compat.sh` first; load other modules after their dependencies.

| Module | Implemented functionality |
|---|---|
| `compat.sh`, `ord.sh` | Shell compatibility helpers and ordinal/character lookup |
| `tui.sh`, `term.sh` | Terminal lifecycle, state restoration, cursor, colors and text attributes |
| `event.sh`, `hid.sh`, `keybind.sh` | Event loop, keyboard/mouse event decoding and declarative key bindings |
| `draw.sh`, `canvas.sh`, `viewport.sh` | Drawing primitives, clipped regions and viewport modes |
| `str.sh`, `buf.sh` | String/Unicode display-width helpers and indexed line buffers |
| `clip.sh` | OSC 52 clipboard output |
| `hl.sh`, `md.sh` | Generic code highlighting and Markdown-to-record-stream conversion |
| `host.sh` | Hosting child applications, including cooperative hosting |
| `actor.sh` | Actor lifecycle, FIFO mailbox and Elm/MVU message/update/effect dispatch |
| `progress.sh`, `slide_motion.sh` | Progress component and deterministic timeline/frame scrubbing |
| `table.sh`, `tree.sh`, `split_view.sh`, `text_input.sh` | Interactive table, expandable tree, two-pane layout and single-line text input |
| `theme.sh`, `ui.sh` | Semantic color themes and reusable terminal UI primitives |
| `cellbuf.sh`, `compositor.sh` | Sparse cell buffers and z-ordered layer composition |
| `monitor.sh` | Best-effort host/system metrics |

## Examples

Existing runnable examples are in [`examples/`](examples/). The Actor-specific walkthroughs are collected in [`docs/examples/`](docs/examples/):

| Actor | Run |
|---|---|
| Core Actor runtime and MVU broker | `sh docs/examples/actor-runtime.sh` |
| Progress | `sh docs/examples/progress.sh` |
| SlideMotion | `sh docs/examples/slide-motion.sh` |
| Table | `sh docs/examples/table.sh` |
| Tree | `sh docs/examples/tree.sh` |
| SplitView | `sh docs/examples/split-view.sh` |
| TextInput | `sh docs/examples/text-input.sh` |

The demos invoke the corresponding runnable examples from the repository root; run them from any working directory.

## Documentation

- [Getting started](docs/getting-started.md)
- [Core terminal lifecycle](docs/tui.md)
- [Terminal output](docs/term.md)
- [Event loop](docs/event.md)
- [Keyboard and mouse events](docs/hid.md)
- [Viewport modes](docs/viewport.md)
- [Hosting and contexts](docs/hosting.md)
- [Actor runtime](docs/actors.md)
- [Progress Actor](docs/progress.md)
- [SlideMotion Actor](docs/slide-motion.md)
- [Interactive table](docs/table.md)
- [Expandable tree](docs/tree.md)
- [SplitView](docs/split-view.md)
- [TextInput](docs/text-input.md)
- [Design system](docs/design-system.md)
- [CellBuffer and compositor](docs/cellbuf-compositor.md)
- [Box drawing](docs/draw.md)
- [String utilities](docs/str.md)
- [Line buffer](docs/buf.md)
- [Key bindings](docs/keybind.md)
- [System clipboard](docs/clip.md)
- [Code highlighting](docs/hl.md)
- [Markdown](docs/md.md)
- [Shell compatibility](docs/compatibility.md)

## Supported shells

The project currently documents support for bash 4+, zsh 5+, ksh93 AJM 93u+, mksh R59+ and busybox sh 1.30+.

## License

ISC

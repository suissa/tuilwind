#!/bin/sh
# SPDX-License-Identifier: ISC
# SlideMotion Actor timeline.
# Run from any working directory; the implementation remains in examples/.
ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
exec sh "$ROOT/examples/slide_motion_demo.sh" "$@"

#!/bin/bash
# SPDX-License-Identifier: ISC
# Progress Actor component.
# Run from any working directory; the implementation remains in examples/.
ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
exec bash "$ROOT/examples/progress_demo.sh" "$@"

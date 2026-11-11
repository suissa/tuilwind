#!/bin/sh
# SPDX-License-Identifier: ISC
# SplitView Actor layout.
# Run from any working directory; the implementation remains in examples/.
ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
exec sh "$ROOT/examples/split_view_demo.sh" "$@"

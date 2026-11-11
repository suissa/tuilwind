#!/bin/sh
# SPDX-License-Identifier: ISC
# Expandable tree Actor.
# Run from any working directory; the implementation remains in examples/.
ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
exec sh "$ROOT/examples/tree_demo.sh" "$@"

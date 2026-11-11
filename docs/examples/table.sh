#!/bin/sh
# SPDX-License-Identifier: ISC
# Interactive table Actor.
# Run from any working directory; the implementation remains in examples/.
ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
exec sh "$ROOT/examples/table_demo.sh" "$@"

#!/bin/sh
# SPDX-License-Identifier: ISC
# TextInput Actor editing.
# Run from any working directory; the implementation remains in examples/.
ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
exec sh "$ROOT/examples/text_input_demo.sh" "$@"

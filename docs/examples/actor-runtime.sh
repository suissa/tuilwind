#!/bin/sh
# SPDX-License-Identifier: ISC
# Core Actor runtime and Elm/MVU broker.
# Run from any working directory; the implementation remains in examples/.
ROOT=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
exec sh "$ROOT/examples/actor_mvu_demo.sh" "$@"

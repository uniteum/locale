#!/usr/bin/env bash
# StringLookup — Bitsy chain-local string lookup, deployed via Nick.
set -euo pipefail
source "$(git rev-parse --show-toplevel)/lib/crucible/script/proto.sh"

mask=0xfff000000000000000000000000000000000ffff
target=0x555000000000000000000000000000000000e300
proto_predict StringLookup 0x000000000000000000000000000000000000000000000000000000000a51697a

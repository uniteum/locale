#!/usr/bin/env bash
# StringLookup — Bitsy chain-local string lookup, deployed via Nick.
set -euo pipefail
source "$(git rev-parse --show-toplevel)/lib/crucible/script/proto.sh"

mask=0xfff000000000000000000000000000000000ffff
target=0xc25f00000000000000000000000000000000e220
proto_predict StringLookup 0x0000000000000000000000000000000000000000000000000000000000798d6a

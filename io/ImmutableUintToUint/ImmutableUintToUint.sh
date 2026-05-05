#!/usr/bin/env bash
# ImmutableUintToUint — Bitsy uint→uint lookup, deployed via Nick.
set -euo pipefail
source "$(git rev-parse --show-toplevel)/lib/crucible/script/lib.sh"

mask=0xfff000000000000000000000000000000000ffff
target=0xc2c000000000000000000000000000000000e220
proto_predict ImmutableUintToUint 0x000000000000000000000000000000000000000000000000000000003558f6b5

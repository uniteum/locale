#!/usr/bin/env bash
# ImmutableUintToUint — Bitsy uint→uint lookup, deployed via Nick.
set -euo pipefail
source "$(git rev-parse --show-toplevel)/lib/crucible/script/proto.sh"

mask=0xfff000000000000000000000000000000000ffff
target=0xc2c000000000000000000000000000000000e300
proto_predict ImmutableUintToUint 0x0000000000000000000000000000000000000000000000000000000001ef64e7

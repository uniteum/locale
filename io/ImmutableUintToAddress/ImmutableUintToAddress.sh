#!/usr/bin/env bash
# ImmutableUintToAddress — Bitsy uint→address lookup, deployed via Nick.
set -euo pipefail
source "$(git rev-parse --show-toplevel)/lib/crucible/script/proto.sh"

mask=0xfff000000000000000000000000000000000ffff
target=0xc2a000000000000000000000000000000000e300
proto_predict ImmutableUintToAddress 0x000000000000000000000000000000000000000000000000000000000153c5b3

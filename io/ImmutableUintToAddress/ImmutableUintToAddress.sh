#!/usr/bin/env bash
# ImmutableUintToAddress — Bitsy uint→address lookup, deployed via Nick.
set -euo pipefail
source "$(git rev-parse --show-toplevel)/lib/crucible/script/lib.sh"

mask=0xfff000000000000000000000000000000000ffff
target=0xc2a000000000000000000000000000000000e220
proto_predict ImmutableUintToAddress 0x0000000000000000000000000000000000000000000000000000000027c304b3

#!/usr/bin/env bash
# AddressLookup — Bitsy chain-local address lookup, deployed via Nick.
set -euo pipefail
source "$(git rev-parse --show-toplevel)/lib/crucible/script/proto.sh"

mask=0xfff000000000000000000000000000000000ffff
target=0xadd000000000000000000000000000000000e221
proto_predict AddressLookup 0x000000000000000000000000000000000000000000000000000000000bae067d

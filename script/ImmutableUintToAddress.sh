source .env
salt=0x0000000000000000000000000000000000000000000000000000000000000000
initcode=$(forge inspect ImmutableUintToAddress bytecode)
initcodehash=$(cast keccak $initcode)
echo "initcodehash=$initcodehash"
ImmutableUintToAddress=$(cast create2 --deployer $deployer --salt $salt --init-code $initcode)
echo "ImmutableUintToAddress=$ImmutableUintToAddress"
input=$(cast concat-hex $salt $initcode)
printf '%s' "$input" > io/ImmutableUintToAddress/$ImmutableUintToAddress.txt
forge verify-contract $ImmutableUintToAddress ImmutableUintToAddress --verifier etherscan --show-standard-json-input | jq '.'> io/ImmutableUintToAddress/$ImmutableUintToAddress.json

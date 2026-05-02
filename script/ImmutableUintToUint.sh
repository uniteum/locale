source .env
salt=0x000000000000000000000000000000000000000000000000000000008ff92ba1 
initcode=$(forge inspect ImmutableUintToUint bytecode)
initcodehash=$(cast keccak $initcode)
echo "initcodehash=$initcodehash"
ImmutableUintToUint=$(cast create2 --deployer $deployer --salt $salt --init-code $initcode)
echo "ImmutableUintToUint=$ImmutableUintToUint"
input=$(cast concat-hex $salt $initcode)
printf '%s' "$input" > io/ImmutableUintToUint/$ImmutableUintToUint.txt
forge verify-contract $ImmutableUintToUint ImmutableUintToUint --verifier etherscan --show-standard-json-input | jq '.'> io/ImmutableUintToUint/$ImmutableUintToUint.json

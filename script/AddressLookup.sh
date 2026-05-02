source .env
salt=0x0000000000000000000000000000000000000000000000000000000012ee0dfd
initcode=$(forge inspect AddressLookup bytecode)
initcodehash=$(cast keccak $initcode)
echo "initcodehash=$initcodehash"
AddressLookup=$(cast create2 --deployer $deployer --salt $salt --init-code $initcode)
echo "AddressLookup=$AddressLookup"
input=$(cast concat-hex $salt $initcode)
printf '%s' "$input" > io/AddressLookup/$AddressLookup.txt
forge verify-contract $AddressLookup AddressLookup --verifier etherscan --show-standard-json-input | jq '.'> io/AddressLookup/$AddressLookup.json

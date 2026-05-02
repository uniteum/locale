source .env
salt=0x0000000000000000000000000000000000000000000000000000000000000000
initcode=$(forge inspect AddressLookup bytecode)
initcodehash=$(cast keccak $initcode)
echo "initcodehash=$initcodehash"
input=$(cast concat-hex $salt $initcode)
printf '%s' "$input" > script/AddressLookup.txt
AddressLookup=$(cast create2 --deployer $deployer --salt $salt --init-code $initcode)
echo "AddressLookup=$AddressLookup"
forge verify-contract $AddressLookup AddressLookup --verifier etherscan --show-standard-json-input | jq '.'> script/AddressLookup.json

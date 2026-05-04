deployer=0x4e59b44847b379578588920cA78FbF26c0B4956C
contract=StringLookup
dir=io/$contract
initcode=$(forge inspect $contract bytecode)
initcodehash=$(cast keccak $initcode)
echo "initcodehash=$initcodehash"

salt=0x00000000000000000000000000000000000000000000000000000000da484b73
home=$(cast create2 --deployer $deployer --salt $salt --init-code $initcode)
echo "home=$home"

input=$(cast concat-hex $salt $initcode)
printf '%s' "$input" > $dir/$home.txt

forge verify-contract $home $contract --verifier etherscan --show-standard-json-input | jq '.'> $dir/$home.json

mask=0xffff00000000000000000000000000000000ffff
target=0xc25f00000000000000000000000000000000e210

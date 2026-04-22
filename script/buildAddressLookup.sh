forge script script/AddressLookupProto.s.sol -f $chain
transaction=$(jq -r '.transactions[0]' broadcast/AddressLookupProto.s.sol/$chain/dry-run/run-latest.json)
AddressLookupProto=$(echo "$transaction" | jq -r '.contractAddress')
forge verify-contract $AddressLookupProto AddressLookup --chain $chain --verifier etherscan --show-standard-json-input | jq '.'> io/AddressLookupProto.json
echo "$transaction" | jq -r '.transaction.input' > io/AddressLookupProtoInput.txt

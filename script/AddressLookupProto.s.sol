// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {AddressLookup} from "../src/AddressLookup.sol";

/// @notice Deploy the AddressLookup factory/implementation contract.
/// @dev Usage: proto=AddressLookupProto.json forge script script/AddressLookupProto.s.sol -f $chain --private-key $tx_key --broadcast --verify --delay 10 --retries 10
contract AddressLookupProto is Script {
    function run() external {
        console2.log("script   : AddressLookupProto");
        address predicted = vm.computeCreate2Address(0x0, keccak256(type(AddressLookup).creationCode));
        console2.log("predicted:", predicted);
        if (predicted.code.length == 0) {
            vm.startBroadcast();
            AddressLookup actual = new AddressLookup{salt: 0x0}();
            vm.stopBroadcast();
            console2.log("actual   :", address(actual));
        } else {
            console2.log("already deployed");
        }

        string memory dir = string.concat("io/", vm.envString("chain"));
        string memory path = string.concat(dir, "/", vm.envString("proto"));
        vm.createDir(dir, true);
        vm.writeJson(vm.toString(predicted), path);
    }
}

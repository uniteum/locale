// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {ImmutableUintToUint} from "../src/ImmutableUintToUint.sol";

/// @notice Deploy the ImmutableUintToUint protofactory contract.
/// @dev Usage: proto=UintToUintProto.json forge script script/UintToUintProto.s.sol -f $chain --private-key $tx_key --broadcast --verify --delay 10 --retries 10
contract UintToUintProto is Script {
    function run() external {
        console2.log("script   : UintToUintProto");
        address predicted = vm.computeCreate2Address(0x0, keccak256(type(ImmutableUintToUint).creationCode));
        console2.log("predicted: ", predicted);
        if (predicted.code.length == 0) {
            vm.startBroadcast();
            ImmutableUintToUint deployed = new ImmutableUintToUint{salt: 0x0}();
            vm.stopBroadcast();
            console2.log("deployed : ", address(deployed));
        } else {
            console2.log("already deployed");
        }

        string memory dir = string.concat("io/", vm.envString("chain"));
        string memory path = string.concat(dir, "/", vm.envString("proto"));
        vm.createDir(dir, true);
        vm.writeJson(vm.toString(predicted), path);
    }
}

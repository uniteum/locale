// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {ImmutableUintToAddress} from "../src/ImmutableUintToAddress.sol";

/// @notice Deploy the ImmutableUintToAddress protofactory contract.
/// @dev Usage: proto=io/$chain/UintToAddressProto.json forge script script/UintToUintProto.s.sol -f $chain --private-key $tx_key --broadcast --verify --delay 10 --retries 10
contract UintToAddressProto is Script {
    function run() external {
        address predicted = vm.computeCreate2Address(0x0, keccak256(type(ImmutableUintToAddress).creationCode));
        console2.log("predicted: ", predicted);
        if (predicted.code.length == 0) {
            vm.startBroadcast();
            ImmutableUintToAddress actual = new ImmutableUintToAddress{salt: 0x0}();
            vm.stopBroadcast();
            console2.log("actual   : ", address(actual));
        } else {
            console2.log("already deployed");
        }

        vm.writeJson(vm.toString(predicted), vm.envString("proto"));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";

/// @notice Base script for deploying protofactory contracts via CREATE2 with salt 0x0.
/// @dev Subclasses provide the contract name and creation code.
///      The predicted address is written to io/$chain/$name.json.
abstract contract ProtoScript is Script {
    function name() internal pure virtual returns (string memory);
    function creationCode() internal pure virtual returns (bytes memory);

    function run() external {
        string memory n = name();
        bytes memory code = creationCode();

        console2.log("script   :", n);
        address predicted = vm.computeCreate2Address(0x0, keccak256(code));
        console2.log("predicted:", predicted);
        if (predicted.code.length == 0) {
            vm.startBroadcast();
            address actual;
            assembly {
                actual := create2(0, add(code, 0x20), mload(code), 0x0)
            }
            vm.stopBroadcast();
            require(actual != address(0), "create2 failed");
            console2.log("actual   :", actual);
        } else {
            console2.log("already deployed");
        }

        string memory dir = string.concat("io/", vm.envString("chain"));
        string memory path = string.concat(dir, "/", n, ".json");
        vm.createDir(dir, true);
        vm.writeJson(vm.toString(predicted), path);
    }
}

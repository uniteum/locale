// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {IUintToAddressMaker} from "ilookup/IUintToAddressMaker.sol";

/// @notice Deploy an ImmutableUintToAddress clone ONLY if it doesn't already exist (idempotent).
/// @dev Environment variables (required):
///   - proto  : address of the IUintToAddressMaker contract
///   - config : path to JSON config file with { env, id, keyValues }
///   - clone  : path to JSON file that will contain the deployed address
/// @dev Example:
/// proto=io/$chain/UintToAddressProto.json config=io/testnet/dvn/google-cloud.json clone=io/$chain/dvn/google-cloud.json forge script script/UintToAddressMake.s.sol -f $chain --private-key $tx_key --broadcast
contract UintToAddressMake is Script {
    struct Config {
        string env;
        string id;
        IUintToAddressMaker.KeyValue[] keyValues;
    }

    function run() external {
        console2.log("== UintToAddressMake ==");
        address proto = abi.decode(vm.parseJson(vm.readFile(vm.envString("proto"))), (address));
        console2.log("proto     :", proto);

        Config memory config = abi.decode(vm.parseJson(vm.readFile(vm.envString("config"))), (Config));
        console2.log("id        :", config.id);
        console2.log("env       :", config.env);

        (, address predicted,) = IUintToAddressMaker(proto).made(config.keyValues);
        console2.log("predicted :", predicted);

        // Idempotent deploy (only broadcast if bytecode missing)
        string memory action = "reused";
        address clone = predicted;
        if (clone.code.length == 0) {
            vm.startBroadcast();
            clone = IUintToAddressMaker(proto).make(config.keyValues);
            vm.stopBroadcast();
            action = "deployed";
        }

        // Result logs
        console2.log("action    :", action);
        console2.log("clone     :", clone);

        vm.writeJson(vm.toString(clone), vm.envString("clone"), string.concat(".", config.id));
    }
}

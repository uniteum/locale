// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Script, console2} from "forge-std/Script.sol";
import {IUintToUintMaker} from "ilookup/IUintToUintMaker.sol";

/// @notice Deploy an ImmutableUintToUint clone ONLY if it doesn't already exist (idempotent).
/// @dev Environment variables (required):
///   - env    : deployment environment ("prod" or "test")
///   - chain  : numerical chain ID (e.g. "42161")
///   - proto  : address of the IUintToUintMaker contract
///   - config : path to JSON config file with { env, id, keyValues }
///   - clone  : path to JSON file that will contain the deployed address
/// @dev Usage: env=test chain=11155111 proto=UintToUintProto.json config=io/test/endpointMapper.json clone=messaging.json forge script script/UintToUintMake.s.sol -f $chain --private-key $tx_key --broadcast
contract UintToUintMake is Script {
    struct Config {
        string env;
        string id;
        IUintToUintMaker.KeyValue[] keyValues;
    }

    function run() external {
        console2.log("script   : UintToUintMake");
        string memory dir = string.concat("io/", vm.envString("env"), "/", vm.envString("chain"));

        // forge-lint: disable-next-line(unsafe-cheatcode)
        address proto = abi.decode(vm.parseJson(vm.readFile(string.concat(dir, "/", vm.envString("proto")))), (address));
        console2.log("proto    :", proto);

        // forge-lint: disable-next-line(unsafe-cheatcode)
        Config memory config = abi.decode(vm.parseJson(vm.readFile(vm.envString("config"))), (Config));
        console2.log("id       :", config.id);
        console2.log("env      :", config.env);

        (, address predicted,) = IUintToUintMaker(proto).made(config.keyValues, 0);
        console2.log("predicted:", predicted);

        // Idempotent deploy (only broadcast if bytecode missing)
        string memory action = "reused";
        address clone = predicted;
        if (clone.code.length == 0) {
            vm.startBroadcast();
            clone = IUintToUintMaker(proto).make(config.keyValues, 0);
            console2.log("clone     :", clone);
            vm.stopBroadcast();
            action = "deployed";
        }

        // Result logs

        string memory path = string.concat(dir, "/", vm.envString("clone"));
        vm.createDir(dir, true);
        vm.writeJson(vm.serializeAddress("tmp", config.id, clone), path);
    }
}

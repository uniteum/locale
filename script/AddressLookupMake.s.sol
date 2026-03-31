// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Script, console2} from "forge-std/Script.sol";
import {AddressLookup, IUintToAddressMaker} from "../src/AddressLookup.sol";

/// @notice Deploy an AddressLookup clone ONLY if it doesn't already exist (idempotent).
/// @dev Environment variables (required):
///   - env : name of the environment ("prod" or "test")
///   - chain : id of the chain (e.g. "11155111")
///   - config  : name of JSON config file with { env, id, keyValues }
/// @dev Usage: config=USDC.json forge script script/AddressLookupMake.s.sol -f $chain --private-key $tx_key --broadcast
contract AddressLookupMake is Script {
    struct Config {
        string env;
        string id;
        AddressLookup.KeyValue[] keyValues;
    }

    function run() external {
        console2.log("script   : AddressLookupMake");

        string memory indir = string.concat("io/", vm.envString("env"), "/");
        string memory dir = string.concat(indir, vm.envString("chain"), "/");
        string memory protoPath = string.concat(dir, "AddressLookupProto.json");
        string memory configEnv = vm.envString("config");
        string memory configPath = string.concat(indir, configEnv);
        string memory clonePath = string.concat(dir, configEnv);

        // forge-lint: disable-next-line(unsafe-cheatcode)
        address proto = abi.decode(vm.parseJson(vm.readFile(protoPath)), (address));
        console2.log("proto    :", proto);

        // forge-lint: disable-next-line(unsafe-cheatcode)
        Config memory config = abi.decode(vm.parseJson(vm.readFile(configPath)), (Config));
        console2.log("id       :", config.id);
        console2.log("env      :", config.env);
        console2.log("length   :", config.keyValues.length);

        (, address predicted,) = IUintToAddressMaker(proto).made(config.keyValues);
        console2.log("predicted:", predicted);

        string memory action = "reused";
        address actual = predicted;
        if (actual.code.length == 0) {
            vm.startBroadcast();
            actual = IUintToAddressMaker(proto).make(config.keyValues);
            vm.stopBroadcast();
            action = "deployed";
        }

        console2.log("action   :", action);
        console2.log("actual   :", actual);

        vm.createDir(dir, true);
        vm.writeJson(vm.serializeAddress("tmp", config.id, actual), clonePath);
    }
}

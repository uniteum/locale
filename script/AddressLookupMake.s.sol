// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {AddressLookup, IUintToAddressMaker} from "../src/AddressLookup.sol";

/// @notice Deploy an AddressLookup clone ONLY if it doesn't already exist (idempotent).
/// @dev Environment variables (required):
///   - proto : address of the AddressLookup (IUintToAddressMaker) contract
///   - config  : path to JSON config file with { env, id, keyValues }
/// @dev Usage: proto=AddressLookupProto.json config=io/testnet/blocker.json clone=blocker.json forge script script/AddressLookupMake.s.sol -f $chain --private-key $tx_key --broadcast
contract AddressLookupMake is Script {
    struct Config {
        string env;
        string id;
        AddressLookup.KeyValue[] keyValues;
    }

    function run() external {
        console2.log("script   : AddressLookupMake");

        string memory dir = string.concat("io/", vm.envString("chain"));

        // forge-lint: disable-next-line(unsafe-cheatcode)
        address proto = abi.decode(vm.parseJson(vm.readFile(string.concat(dir, "/", vm.envString("proto")))), (address));
        console2.log("proto    :", proto);

        // forge-lint: disable-next-line(unsafe-cheatcode)
        Config memory config = abi.decode(vm.parseJson(vm.readFile(vm.envString("config"))), (Config));
        console2.log("id       :", config.id);
        console2.log("env      :", config.env);

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

        console2.log("actual   :", actual);

        string memory path = string.concat(dir, "/", vm.envString("clone"));
        vm.createDir(dir, true);
        vm.writeJson(vm.serializeAddress("tmp", config.id, actual), path);
    }
}

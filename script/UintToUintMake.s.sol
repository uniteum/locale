// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {IUintToUintMaker} from "ilookup/IUintToUintMaker.sol";

/// @notice Deploy an ImmutableUintToUint clone ONLY if it doesn't already exist (idempotent).
/// @dev Environment variables (required):
///   - proto  : address of the IUintToUintMaker contract
///   - config : path to JSON config file with { env, id, keyValues }
///   - clone  : path to JSON file that will contain the deployed address
/// @dev Example:
/// proto=io/$chain/UintToUintProto.json config=io/testnet/endpointMapper.json clone=io/$chain/messaging.json forge script script/UintToUintMake.s.sol -f $chain --private-key $tx_key --broadcast
contract UintToUintMake is Script {
    struct Config {
        string env;
        string id;
        IUintToUintMaker.KeyValue[] keyValues;
    }

    function run() external {
        console2.log("script   : UintToUintMake");
        // forge-lint: disable-next-line(unsafe-cheatcode)
        address proto = abi.decode(vm.parseJson(vm.readFile(vm.envString("proto"))), (address));
        console2.log("proto    :", proto);

        // forge-lint: disable-next-line(unsafe-cheatcode)
        Config memory config = abi.decode(vm.parseJson(vm.readFile(vm.envString("config"))), (Config));
        console2.log("id       :", config.id);
        console2.log("env      :", config.env);

        (, address predicted,) = IUintToUintMaker(proto).made(config.keyValues);
        console2.log("predicted:", predicted);

        // Idempotent deploy (only broadcast if bytecode missing)
        string memory action = "reused";
        address clone = predicted;
        if (clone.code.length == 0) {
            vm.startBroadcast();
            clone = IUintToUintMaker(proto).make(config.keyValues);
            console2.log("clone     :", clone);
            vm.stopBroadcast();
            action = "deployed";
        }

        // Result logs

        vm.writeJson(vm.serializeAddress("tmp", config.id, clone), vm.envString("clone"));
    }
}

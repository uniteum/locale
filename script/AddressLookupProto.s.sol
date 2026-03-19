// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AddressLookup} from "../src/AddressLookup.sol";
import {ProtoScript} from "./ProtoScript.s.sol";

/// @notice Deploy the AddressLookup protofactory contract.
/// @dev Usage: forge script script/AddressLookupProto.s.sol -f $chain --private-key $tx_key --broadcast --verify --delay 10 --retries 10
contract AddressLookupProto is ProtoScript {
    function name() internal pure override returns (string memory) {
        return "AddressLookupProto";
    }

    function creationCode() internal pure override returns (bytes memory) {
        return type(AddressLookup).creationCode;
    }
}

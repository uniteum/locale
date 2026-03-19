// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ImmutableUintToUint} from "../src/ImmutableUintToUint.sol";
import {ProtoScript} from "./ProtoScript.s.sol";

/// @notice Deploy the ImmutableUintToUint protofactory contract.
/// @dev Usage: forge script script/UintToUintProto.s.sol -f $chain --private-key $tx_key --broadcast --verify --delay 10 --retries 10
contract UintToUintProto is ProtoScript {
    function name() internal pure override returns (string memory) {
        return "UintToUintProto";
    }

    function creationCode() internal pure override returns (bytes memory) {
        return type(ImmutableUintToUint).creationCode;
    }
}

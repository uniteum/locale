// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ImmutableUintToAddress} from "../src/ImmutableUintToAddress.sol";
import {ProtoScript} from "./ProtoScript.s.sol";

/// @notice Deploy the ImmutableUintToAddress protofactory contract.
/// @dev Usage: forge script script/UintToAddressProto.s.sol -f $chain --private-key $tx_key --broadcast --verify --delay 10 --retries 10
contract UintToAddressProto is ProtoScript {
    function name() internal pure override returns (string memory) {
        return "UintToAddressProto";
    }

    function creationCode() internal pure override returns (bytes memory) {
        return type(ImmutableUintToAddress).creationCode;
    }
}

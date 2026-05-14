// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IStringLookup} from "ilookup/IStringLookup.sol";
import {IUintToStringMaker} from "ilookup/IUintToStringMaker.sol";
import {Prototype} from "proto/Prototype.sol";

/**
 * @notice Immutably map a single predictable address to a chain-specific string.
 * @dev A trustless cross-chain reference with no governance or upgrade risk.
 * Contracts, SDKs, and UIs can hardcode one address and resolve to the local
 * value on any chain.
 * @dev The implementation is also a factory; anyone may deploy a StringLookup.
 * @author Paul Reinholdtsen (reinholdtsen.eth)
 */
contract StringLookup is Prototype, IStringLookup, IUintToStringMaker {
    string public constant version = "3.0.0";

    /**
     * @inheritdoc IStringLookup
     */
    string public value;

    /**
     * @notice ABI-encode the typed args used to derive a clone's address.
     * @param keyValues The array of key value pairs sorted by key.
     * @return args The bytes blob consumed by {make} and {made}.
     */
    function encode(
        KeyValue[] memory keyValues
    ) public pure returns (bytes memory args) {
        args = abi.encode(keyValues);
    }

    /**
     * @inheritdoc IUintToStringMaker
     */
    function made(
        KeyValue[] memory keyValues,
        uint256 variant
    ) external view returns (bool exists, address home, bytes32 salt) {
        (exists, home, salt) = this.made(encode(keyValues), variant);
    }

    /**
     * @inheritdoc IUintToStringMaker
     */
    function make(
        KeyValue[] memory keyValues,
        uint256 variant
    ) external returns (address home) {
        (, home, ) = this.make(encode(keyValues), variant);
    }

    /**
     * @inheritdoc Prototype
     * @dev Decodes the keyValues array and stores the entry matching the current chain id.
     */
    function zzInit(bytes calldata args, uint256) external override onlyProto {
        KeyValue[] memory keyValues = abi.decode(args, (KeyValue[]));
        for (uint256 i; i < keyValues.length; ++i) {
            if (keyValues[i].key == block.chainid) {
                value = keyValues[i].value;
                break;
            }
        }
    }
}

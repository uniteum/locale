// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IUintToUint} from "ilookup/IUintToUint.sol";
import {IUintToUintMaker} from "ilookup/IUintToUintMaker.sol";
import {Prototype} from "proto/Prototype.sol";

/**
 * @notice Immutable map from uint256 to uint256, with no governance or upgrade risk.
 * @dev Deterministic deployment yields identical addresses across chains.
 * The implementation is also a factory; anyone may deploy an instance.
 */
contract ImmutableUintToUint is Prototype, IUintToUint, IUintToUintMaker {
    string public constant version = "3.0.0";

    /**
     * @inheritdoc IUintToUint
     */
    uint256[] public keyAt;

    /**
     * @inheritdoc IUintToUint
     */
    mapping(uint256 => uint256) public valueOf;

    /**
     * @inheritdoc IUintToUint
     */
    function length() external view returns (uint256) {
        return keyAt.length;
    }

    /**
     * @notice ABI-encode the typed args used to derive a clone's address.
     * @param keyValues The array of key value pairs sorted by key.
     * @return args The bytes blob consumed by {make} and {made}.
     */
    function encode(KeyValue[] memory keyValues) public pure returns (bytes memory args) {
        args = abi.encode(keyValues);
    }

    /**
     * @inheritdoc IUintToUintMaker
     */
    function made(KeyValue[] memory keyValues, uint256 variant)
        external
        view
        returns (bool exists, address home, bytes32 salt)
    {
        (exists, home, salt) = this.made(encode(keyValues), variant);
    }

    /**
     * @inheritdoc IUintToUintMaker
     */
    function make(KeyValue[] memory keyValues, uint256 variant) external returns (address home) {
        (, home,) = this.make(encode(keyValues), variant);
    }

    /**
     * @inheritdoc Prototype
     * @dev Decodes the keyValues array and stores every entry.
     */
    function zzInit(bytes calldata args, uint256 variant) public override {
        super.zzInit(args, variant);
        KeyValue[] memory keyValues = abi.decode(args, (KeyValue[]));
        for (uint256 i; i < keyValues.length; ++i) {
            keyAt.push(keyValues[i].key);
            valueOf[keyValues[i].key] = keyValues[i].value;
        }
    }
}

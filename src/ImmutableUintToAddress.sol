// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IUintToAddress} from "ilookup/IUintToAddress.sol";
import {IUintToAddressMaker} from "ilookup/IUintToAddressMaker.sol";
import {Clones} from "clones/Clones.sol";

/**
 * @notice Immutable map from uint256 to address, with no governance or upgrade risk.
 * @dev Deterministic deployment yields identical addresses across chains.
 * The implementation is also a factory; anyone may deploy an instance.
 */
contract ImmutableUintToAddress is IUintToAddress, IUintToAddressMaker {
    string public constant version = "2.2.0";

    address public immutable proto = address(this);

    /**
     * @inheritdoc IUintToAddress
     */
    uint256[] public keyAt;

    /**
     * @inheritdoc IUintToAddress
     */
    mapping(uint256 => address) public valueOf;

    /**
     * @inheritdoc IUintToAddress
     */
    function length() external view returns (uint256) {
        return keyAt.length;
    }

    /**
     * @inheritdoc IUintToAddressMaker
     */
    function made(
        KeyValue[] memory keyValues,
        uint256 variant
    ) public view returns (bool exists, address home, bytes32 salt) {
        salt = keccak256(abi.encode(keyValues)) ^ bytes32(variant);
        home = Clones.predictDeterministicAddress(proto, salt, proto);
        exists = home.code.length > 0;
    }

    /**
     * @inheritdoc IUintToAddressMaker
     */
    function make(
        KeyValue[] memory keyValues,
        uint256 variant
    ) public returns (address home) {
        if (address(this) != proto)
            return ImmutableUintToAddress(proto).make(keyValues, variant);
        bool exists;
        bytes32 salt;
        (exists, home, salt) = made(keyValues, variant);
        if (!exists) {
            Clones.cloneDeterministic(proto, salt, 0);
            ImmutableUintToAddress(home).zzInit(keyValues);
            emit Made(home, salt);
        }
    }

    /**
     * @dev Initializer; callable only by proto from {make}.
     * @param keyValues The array of key value pairs sorted by key.
     */
    function zzInit(KeyValue[] memory keyValues) public {
        if (msg.sender != proto) revert Unauthorized();
        for (uint256 i; i < keyValues.length; ++i) {
            keyAt.push(keyValues[i].key);
            valueOf[keyValues[i].key] = keyValues[i].value;
        }
    }
}

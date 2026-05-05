// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IUintToUint} from "ilookup/IUintToUint.sol";
import {IUintToUintMaker} from "ilookup/IUintToUintMaker.sol";
import {Clones} from "clones/Clones.sol";

/**
 * @notice Immutable map from uint256 to uint256, with no governance or upgrade risk.
 * @dev Deterministic deployment yields identical addresses across chains.
 * The implementation is also a factory; anyone may deploy an instance.
 */
contract ImmutableUintToUint is IUintToUint, IUintToUintMaker {
    string public constant version = "2.2.0";

    address public immutable proto = address(this);

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
     * @inheritdoc IUintToUintMaker
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
     * @inheritdoc IUintToUintMaker
     */
    function make(
        KeyValue[] memory keyValues,
        uint256 variant
    ) public returns (address home) {
        if (address(this) != proto)
            return ImmutableUintToUint(proto).make(keyValues, variant);
        bool exists;
        bytes32 salt;
        (exists, home, salt) = made(keyValues, variant);
        if (!exists) {
            Clones.cloneDeterministic(proto, salt, 0);
            ImmutableUintToUint(home).zzInit(keyValues);
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

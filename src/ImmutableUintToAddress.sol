// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {IUintToAddress} from "ilookup/IUintToAddress.sol";
import {IUintToAddressMaker} from "ilookup/IUintToAddressMaker.sol";
import {Clones} from "clones/Clones.sol";

/// @notice Immutable map from uint256 to address with no governance or upgrade risk.
/// The implementation is also a factory, allowing anyone to easily deploy an instance.
/// Deterministic deployment ensures identical addresses across chains.
contract ImmutableUintToAddress is IUintToAddress, IUintToAddressMaker {
    address public immutable PROTO = address(this);

    /// @inheritdoc IUintToAddress
    uint256[] public keyAt;

    /// @inheritdoc IUintToAddress
    mapping(uint256 => address) public valueOf;

    function length() external view returns (uint256) {
        return keyAt.length;
    }

    /// @inheritdoc IUintToAddressMaker
    function made(KeyValue[] memory kvs) public view returns (bool exists, address expected, bytes32 salt) {
        salt = keccak256(abi.encode(kvs));
        expected = Clones.predictDeterministicAddress(PROTO, salt, PROTO);
        exists = expected.code.length > 0;
    }

    /// @inheritdoc IUintToAddressMaker
    function make(KeyValue[] memory kvs) public returns (address home) {
        bool exists;
        bytes32 salt;
        (exists, home, salt) = made(kvs);
        if (!exists) {
            Clones.cloneDeterministic(PROTO, salt, 0);
            ImmutableUintToAddress(home).zzInit(kvs);
            emit Made(home, salt);
        }
    }

    /// @dev Only PROTO should call zzInit.
    /// @param kvs The array of key value pairs sorted by key.
    function zzInit(KeyValue[] memory kvs) public {
        if (msg.sender != PROTO) revert Unauthorized();
        for (uint256 i; i < kvs.length; ++i) {
            keyAt.push(kvs[i].key);
            valueOf[kvs[i].key] = kvs[i].value;
        }
    }
}

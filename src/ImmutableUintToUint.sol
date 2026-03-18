// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IUintToUint} from "ilookup/IUintToUint.sol";
import {IUintToUintMaker} from "ilookup/IUintToUintMaker.sol";
import {Clones} from "clones/Clones.sol";

/// @notice Immutable map from uint256 to uint256 with no governance or upgrade risk.
/// The implementation is also a factory, allowing anyone to easily deploy an instance.
/// Deterministic deployment ensures identical addresses across chains.
contract ImmutableUintToUint is IUintToUint, IUintToUintMaker {
    address public immutable PROTO = address(this);

    /// @inheritdoc IUintToUint
    uint256[] public keyAt;

    /// @inheritdoc IUintToUint
    mapping(uint256 => uint256) public valueOf;

    /// @inheritdoc IUintToUint
    function length() external view returns (uint256) {
        return keyAt.length;
    }

    /// @inheritdoc IUintToUintMaker
    function made(KeyValue[] memory kvs) public view returns (bool exists, address expected, bytes32 salt) {
        salt = keccak256(abi.encode(kvs));
        expected = Clones.predictDeterministicAddress(PROTO, salt, PROTO);
        exists = expected.code.length > 0;
    }

    /// @inheritdoc IUintToUintMaker
    function make(KeyValue[] memory kvs) public returns (address home) {
        bool exists;
        bytes32 salt;
        (exists, home, salt) = made(kvs);
        if (!exists) {
            Clones.cloneDeterministic(PROTO, salt, 0);
            ImmutableUintToUint(home).zzInit(kvs);
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

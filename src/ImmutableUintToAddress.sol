// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IUintToAddress} from "ilookup/IUintToAddress.sol";
import {IUintToAddressMaker} from "ilookup/IUintToAddressMaker.sol";
import {Clones} from "clones/Clones.sol";

/// @notice Immutable map from uint256 to address with no governance or upgrade risk.
/// The implementation is also a factory, allowing anyone to easily deploy an instance.
/// Deterministic deployment ensures identical addresses across chains.
/// @author Paul Reinholdtsen (reinholdtsen.eth)
contract ImmutableUintToAddress is IUintToAddress, IUintToAddressMaker {
    address public immutable PROTO = address(this);

    /// @inheritdoc IUintToAddress
    function keyCount() external view returns (uint256) {
        return _keys.length;
    }

    /// @inheritdoc IUintToAddress
    function keyAt(uint256 index) external view returns (uint256 key) {
        return _keys[index];
    }

    /// @inheritdoc IUintToAddress
    function valueOf(uint256 key) external view returns (address value) {
        return _values[key];
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

    uint256[] private _keys;
    mapping(uint256 => address) private _values;
    bool private _initialized;

    /// @dev Prevent the implementation contract from being initialized.
    constructor() {
        _initialized = true;
    }

    /// @dev Only the cloner should call __init.
    /// @param kvs The array of key value pairs sorted by key.
    function zzInit(KeyValue[] memory kvs) public {
        if (_initialized) revert MadeAlready();
        _initialized = true;
        for (uint256 i; i < kvs.length; ++i) {
            _keys.push(kvs[i].key);
            _values[kvs[i].key] = kvs[i].value;
        }
    }
}

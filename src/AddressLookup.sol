// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IAddressLookup} from "ilookup/IAddressLookup.sol";
import {IUintToAddressMaker} from "ilookup/IUintToAddressMaker.sol";
import {Clones} from "clones/Clones.sol";

/// @notice Immutably map a single predictable contract address to a chain specific address.
/// The same contract deployed to the same address on different chains can return
/// different values based on the chain ID.
/// @dev Deterministic deployment provides a trustless reference with no governance or upgrade risk.
/// Contracts, SDKs, and UIs can hardcode one address and resolve everywhere.
/// Typical uses include cross-chain endpoints (oracles, messengers, executors), wallets,
/// bridges, and explorers that require a single uniform reference across chains.
/// @dev The implementation is also a factory, allowing anyone to easily deploy an AddressLookups.
/// @author Paul Reinholdtsen (reinholdtsen.eth)
contract AddressLookup is IAddressLookup, IUintToAddressMaker {
    address public immutable PROTO = address(this);

    /// @inheritdoc IAddressLookup
    address public value;

    /// @inheritdoc IUintToAddressMaker
    function made(KeyValue[] memory keyValues) public view returns (bool exists, address home, bytes32 salt) {
        salt = keccak256(abi.encode(keyValues));
        home = Clones.predictDeterministicAddress(PROTO, salt, PROTO);
        exists = home.code.length > 0;
    }

    /// @inheritdoc IUintToAddressMaker
    function make(KeyValue[] memory keyValues) public returns (address home) {
        bool exists;
        bytes32 salt;
        (exists, home, salt) = made(keyValues);
        if (!exists) {
            address value_;
            for (uint256 i; i < keyValues.length; ++i) {
                if (keyValues[i].key == block.chainid) {
                    value_ = keyValues[i].value;
                    break;
                }
            }
            Clones.cloneDeterministic(address(this), salt, 0);
            AddressLookup(home).zzInit(value_);
            emit Made(home, salt);
        }
    }

    bool private _initialized;

    /// @dev Prevent the implementation contract from being initialized.
    constructor() {
        _initialized = true;
    }

    /// @dev Only let the owner set the value address after cloning.
    /// @param value_ The value address for the current chain.
    function zzInit(address value_) public {
        if (_initialized) revert MadeAlready();
        _initialized = true;
        value = value_;
    }
}

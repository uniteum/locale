// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IAddressLookup} from "ilookup/IAddressLookup.sol";
import {IUintToAddressMaker} from "ilookup/IUintToAddressMaker.sol";
import {Prototype} from "proto/Prototype.sol";

/**
 * @notice Immutably map a single predictable address to a chain-specific address.
 * @dev A trustless cross-chain reference with no governance or upgrade risk.
 * Contracts, SDKs, and UIs can hardcode one address and resolve to the local
 * value on any chain.
 * @dev The implementation is also a factory; anyone may deploy an AddressLookup.
 */
contract AddressLookup is Prototype, IAddressLookup, IUintToAddressMaker {
    string public constant version = "3.0.0";

    /**
     * @inheritdoc IAddressLookup
     */
    address public value;

    /**
     * @notice ABI-encode the typed args used to derive a clone's address.
     * @param keyValues The array of key value pairs sorted by key.
     * @return args The bytes blob consumed by {make} and {made}.
     */
    function encode(KeyValue[] memory keyValues) public pure returns (bytes memory args) {
        args = abi.encode(keyValues);
    }

    /**
     * @inheritdoc IUintToAddressMaker
     */
    function made(KeyValue[] memory keyValues, uint256 variant)
        external
        view
        returns (bool exists, address home, bytes32 salt)
    {
        (exists, home, salt) = this.made(encode(keyValues), variant);
    }

    /**
     * @inheritdoc IUintToAddressMaker
     */
    function make(KeyValue[] memory keyValues, uint256 variant) external returns (address home) {
        bool exists;
        bytes32 salt;
        (exists, home, salt) = this.make(encode(keyValues), variant);
        if (!exists) emit Made(home, salt);
    }

    /**
     * @inheritdoc Prototype
     * @dev Decodes the keyValues array and stores the entry matching the current chain id.
     */
    function zzInit(
        bytes calldata args,
        uint256 /*variant*/
    )
        public
        override
        onlyProto
    {
        KeyValue[] memory keyValues = abi.decode(args, (KeyValue[]));
        for (uint256 i; i < keyValues.length; ++i) {
            if (keyValues[i].key == block.chainid) {
                value = keyValues[i].value;
                break;
            }
        }
    }
}

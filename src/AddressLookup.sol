// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IAddressLookup} from "ilookup/IAddressLookup.sol";
import {IUintToAddressMaker} from "ilookup/IUintToAddressMaker.sol";
import {Prototype} from "proto/Prototype.sol";

/**
 * @notice Immutably map a single predictable address to a chain-specific address.
 * @dev A trustless cross-chain reference with no governance or upgrade risk.
 * Contracts, SDKs, and UIs can hardcode one address and resolve to the local
 * value on any chain.
 *
 * The implementation is also a factory; anyone may deploy an AddressLookup.
 * @author Paul Reinholdtsen (reinholdtsen.eth)
 */
contract AddressLookup is IAddressLookup, IUintToAddressMaker, Prototype {
    string public constant version = "3.0.0";

    /**
     * @inheritdoc IAddressLookup
     */
    address public value;

    /**
     * @inheritdoc IUintToAddressMaker
     */
    function made(Entry[] calldata entries, uint256 variant)
        external
        view
        returns (bool exists, address home, bytes32 salt)
    {
        (exists, home, salt) = this.made(encode(entries), variant);
    }

    /**
     * @inheritdoc IUintToAddressMaker
     */
    function make(Entry[] calldata entries, uint256 variant) external returns (address home) {
        (, home,) = this.make(encode(entries), variant);
    }

    /**
     * @inheritdoc Prototype
     * @dev Decodes the entries array and stores the entry matching the current chain id.
     */
    function zzInit(bytes calldata args, uint256) external override onlyProto {
        Entry[] memory entries = abi.decode(args, (Entry[]));
        for (uint256 i; i < entries.length; ++i) {
            if (entries[i].key == block.chainid) {
                value = entries[i].value;
                break;
            }
        }
    }

    /**
     * @notice ABI-encode the typed args used to derive a clone's address.
     * @param entries The array of key value pairs sorted by key.
     * @return args The bytes blob consumed by {make} and {made}.
     */
    function encode(Entry[] calldata entries) public pure returns (bytes memory args) {
        args = abi.encode(entries);
    }
}

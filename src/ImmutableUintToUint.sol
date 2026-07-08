// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IUintToUint} from "ilookup/IUintToUint.sol";
import {IUintToUintMaker} from "ilookup/IUintToUintMaker.sol";
import {Prototype} from "proto/Prototype.sol";

/**
 * @notice Immutable map from uint256 to uint256.
 * @dev A trustless on-chain lookup with no governance or upgrade risk.
 * Deterministic deployment yields identical addresses across chains for identical maps.
 *
 * The implementation is also a factory; anyone may deploy an ImmutableUintToUint.
 * @author Paul Reinholdtsen (reinholdtsen.eth)
 */
contract ImmutableUintToUint is IUintToUint, IUintToUintMaker, Prototype {
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
     * @inheritdoc IUintToUintMaker
     */
    function made(Entry[] memory entries, uint256 variant)
        external
        view
        returns (bool exists, address home, bytes32 salt)
    {
        (exists, home, salt) = this.made(encode(entries), variant);
    }

    /**
     * @inheritdoc IUintToUintMaker
     */
    function make(Entry[] memory entries, uint256 variant) external returns (address home) {
        (, home,) = this.make(encode(entries), variant);
    }

    /**
     * @inheritdoc Prototype
     * @dev Decodes the entries array and stores every entry.
     */
    function zzInit(bytes calldata args, uint256) external override onlyProto {
        Entry[] memory entries = abi.decode(args, (Entry[]));
        for (uint256 i; i < entries.length; ++i) {
            keyAt.push(entries[i].key);
            valueOf[entries[i].key] = entries[i].value;
        }
    }

    /**
     * @notice ABI-encode the typed args used to derive a clone's address.
     * @param entries The array of key value pairs sorted by key.
     * @return args The bytes blob consumed by {make} and {made}.
     */
    function encode(Entry[] memory entries) public pure returns (bytes memory args) {
        args = abi.encode(entries);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IUintToAddress} from "ilookup/IUintToAddress.sol";
import {IUintToAddressMaker} from "ilookup/IUintToAddressMaker.sol";
import {Clones} from "clones/Clones.sol";

/**
 * @notice Immutable map from uint256 to address with no governance or upgrade risk.
 * The implementation is also a factory, allowing anyone to easily deploy an instance.
 * Deterministic deployment ensures identical addresses across chains.
 */
contract ImmutableUintToAddress is IUintToAddress, IUintToAddressMaker {
    string public constant version = "2.0.0";

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
    function made(KeyValue[] memory kvs, uint256 variant)
        public
        view
        returns (bool exists, address expected, bytes32 salt)
    {
        salt = keccak256(abi.encode(kvs, variant));
        expected = Clones.predictDeterministicAddress(proto, salt, proto);
        exists = expected.code.length > 0;
    }

    /**
     * @inheritdoc IUintToAddressMaker
     */
    function make(KeyValue[] memory kvs, uint256 variant) public returns (address home) {
        bool exists;
        bytes32 salt;
        (exists, home, salt) = made(kvs, variant);
        if (!exists) {
            Clones.cloneDeterministic(proto, salt, 0);
            ImmutableUintToAddress(home).zzInit(kvs);
            emit Made(home, salt);
        }
    }

    /**
     * @dev Only proto should call zzInit.
     * @param kvs The array of key value pairs sorted by key.
     */
    function zzInit(KeyValue[] memory kvs) public {
        if (msg.sender != proto) revert Unauthorized();
        for (uint256 i; i < kvs.length; ++i) {
            keyAt.push(kvs[i].key);
            valueOf[kvs[i].key] = kvs[i].value;
        }
    }
}

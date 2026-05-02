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
    string public constant version = "2.0.0";

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
     * @inheritdoc IUintToUintMaker
     */
    function make(KeyValue[] memory kvs, uint256 variant) public returns (address home) {
        bool exists;
        bytes32 salt;
        (exists, home, salt) = made(kvs, variant);
        if (!exists) {
            Clones.cloneDeterministic(proto, salt, 0);
            ImmutableUintToUint(home).zzInit(kvs);
            emit Made(home, salt);
        }
    }

    /**
     * @dev Initializer; callable only by proto from {make}.
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

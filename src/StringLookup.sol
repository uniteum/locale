// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IStringLookup} from "ilookup/IStringLookup.sol";
import {IUintToStringMaker} from "ilookup/IUintToStringMaker.sol";
import {Clones} from "clones/Clones.sol";

/**
 * @notice Immutably map a single predictable address to a chain-specific string.
 * @dev A trustless cross-chain reference with no governance or upgrade risk.
 * Contracts, SDKs, and UIs can hardcode one address and resolve to the local
 * value on any chain.
 * @dev The implementation is also a factory; anyone may deploy a StringLookup.
 */
contract StringLookup is IStringLookup, IUintToStringMaker {
    string public constant version = "2.1.0";

    address public immutable proto = address(this);

    /**
     * @inheritdoc IStringLookup
     */
    string public value;

    /**
     * @inheritdoc IUintToStringMaker
     */
    function made(KeyValue[] memory keyValues, uint256 variant)
        public
        view
        returns (bool exists, address home, bytes32 salt)
    {
        salt = keccak256(abi.encode(keyValues)) ^ bytes32(variant);
        home = Clones.predictDeterministicAddress(proto, salt, proto);
        exists = home.code.length > 0;
    }

    /**
     * @inheritdoc IUintToStringMaker
     */
    function make(KeyValue[] memory keyValues, uint256 variant) public returns (address home) {
        if (address(this) != proto) return StringLookup(proto).make(keyValues, variant);
        bool exists;
        bytes32 salt;
        (exists, home, salt) = made(keyValues, variant);
        if (!exists) {
            string memory value_;
            for (uint256 i; i < keyValues.length; ++i) {
                if (keyValues[i].key == block.chainid) {
                    value_ = keyValues[i].value;
                    break;
                }
            }
            Clones.cloneDeterministic(proto, salt, 0);
            StringLookup(home).zzInit(value_);
            emit Made(home, salt);
        }
    }

    /**
     * @dev Initializer; callable only by proto from {make}.
     * @param value_ The value string for the current chain.
     */
    function zzInit(string memory value_) public {
        if (msg.sender != proto) revert Unauthorized();
        value = value_;
    }
}

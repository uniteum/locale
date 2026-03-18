// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ImmutableUintToUint} from "../src/ImmutableUintToUint.sol";
import {IUintToUintMaker} from "ilookup/IUintToUintMaker.sol";
import {Test} from "forge-std/Test.sol";

contract ImmutableUintToUintTest is Test {
    ImmutableUintToUint proto;
    Config config;

    // The contract maps a key and a network to a KV lookup table
    struct Config {
        string env;
        string id;
        IUintToUintMaker.KeyValue[] keyValues;
    }

    // setUp() is always run before each test
    function setUp() public {
        // forge-lint: disable-next-line(unsafe-cheatcode)
        config = abi.decode(vm.parseJson(vm.readFile("test/endpointMapper.json")), (Config));
        proto = new ImmutableUintToUint{salt: 0x0}();
        assertNotEq(address(proto), address(0), "proto is unexpectedly zero in setup().");
    }

    // Test make()
    function test_UintToUintClone() public {
        // Simple canonical deployment
        address address1 = proto.make(config.keyValues);
        assertNotEq(address1, address(0), "address1 is unexpectedly zero.");
    }

    // Test redundant make()
    function test_UintToUintClone2() public {
        // Clone for the first time
        address address1 = proto.make(config.keyValues);
        assertNotEq(address1, address(0), "address1 is unexpectedly zero.");

        // Test that a second make looks just like the first make
        address address2 = proto.make(config.keyValues);
        assertNotEq(address2, address(0), "address2 is unexpectedly zero.");

        // Test that the second make() was returning the same values as the first
        assertEq(address1, address2, "Second make should return address1.");
    }

    // Test that make() clones to the address that made() predicts
    function test_UintToUintCloneAddress() public {
        // Call made() and make() for comparison
        (, address address1,) = proto.made(config.keyValues);
        address address2 = proto.make(config.keyValues);

        // Both should return the same address and salt
        assertEq(address1, address2, "made() and make() disagree on deployed address.");
    }

    // Test that different KVs affect the resulting address.
    function test_UintToUintCloneDifferentKVsGivesDifferentAddress() public {
        // Make a copy of the config KV's and change the first element
        IUintToUintMaker.KeyValue[] memory altered = config.keyValues;
        altered[0].value = 42;

        // Deploy with both sets of KVs
        address address1 = proto.make(config.keyValues);
        address address2 = proto.make(altered);

        // Make sure that we get two non-zero address
        assertNotEq(address1, address(0), "make of KVs failed.");
        assertNotEq(address2, address(0), "make of modified KVs failed.");
        assertNotEq(address1, address2, "Distinct KVs should yield different make addresses");
    }

    // Test that empty KVs is acceptable (This should probably be reversed but it's currently allowed)
    function test_UintToUintEmptyConfigIsDeterministic() public {
        // Need an empty set of KVs
        IUintToUintMaker.KeyValue[] memory empty;

        // Call made() on the empty set of KVs
        (, address address1, bytes32 salt1) = proto.made(empty);
        assertNotEq(address1, address(0), "made() on empty KVs failed.");
        assertNotEq(salt1, 0, "salt1 unexpectedly zero.");

        // Call make() on the empty set of KVs
        address address2 = proto.make(empty);
        assertNotEq(address2, address(0), "make() on empty KVs failed.");

        // Expect made() and make() to return the same address and salt
        assertEq(address1, address2, "made() and make() should return the same address.");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {StringLookup} from "../src/StringLookup.sol";
import {IUintToStringMaker} from "ilookup/IUintToStringMaker.sol";

import {Test} from "forge-std/Test.sol";

contract StringLookupTest is Test {
    StringLookup proto;
    Config config;

    // The contract maps a key and a network to a KV lookup table
    struct Config {
        string env;
        string id;
        IUintToStringMaker.KeyValue[] keyValues;
    }

    // setUp() is always run before each test
    function setUp() public {
        // forge-lint: disable-next-line(unsafe-cheatcode)
        config = abi.decode(vm.parseJson(vm.readFile("test/endpointString.json")), (Config));
        // CREATE2 for proto, so its address is stable across our snapshots
        proto = new StringLookup{salt: 0x0}();
        assertNotEq(address(proto), address(0), "proto is unexpectedly zero in setup().");
    }

    // Test make()
    function test_StringLookupMake() public {
        address address1 = proto.make(config.keyValues, 0);
        assertNotEq(address1, address(0), "address1 is unexpectedly zero.");
    }

    // Test redundant make()
    function test_StringLookupMake2() public {
        address address1 = proto.make(config.keyValues, 0);
        assertNotEq(address1, address(0), "address1 is unexpectedly zero.");

        address address2 = proto.make(config.keyValues, 0);
        assertNotEq(address2, address(0), "address2 is unexpectedly zero.");

        assertEq(address1, address2, "Second make should return address1.");
    }

    // Test that make() clones to the address that made() predicts
    function test_StringLookupMakeAddress() public {
        (, address address1,) = proto.made(config.keyValues, 0);
        address address2 = proto.make(config.keyValues, 0);
        assertEq(address1, address2, "made() and make() disagree on deployed address.");
    }

    // Test that different KVs affect the resulting address.
    function test_StringLookupMakeDifferentKVsGivesDifferentAddress() public {
        IUintToStringMaker.KeyValue[] memory altered = config.keyValues;
        altered[0].value = "https://different.example/rpc";
        address address1 = proto.make(config.keyValues, 0);
        address address2 = proto.make(altered, 0);
        assertNotEq(address1, address(0), "make of KVs failed.");
        assertNotEq(address2, address(0), "make of modified KVs failed.");
        assertNotEq(address1, address2, "Distinct KVs should yield different make addresses");
    }

    // Test that empty KVs is acceptable (This should probably be reversed but it's currently allowed)
    function test_StringLookupEmptyConfigIsDeterministic() public {
        IUintToStringMaker.KeyValue[] memory empty;
        (, address address1, bytes32 salt1) = proto.made(empty, 0);
        assertNotEq(address1, address(0), "made() on empty KVs failed.");
        assertNotEq(salt1, 0, "salt1 unexpectedly zero.");
        address address2 = proto.make(empty, 0);
        assertNotEq(address2, address(0), "make() on empty KVs failed.");
        assertEq(address1, address2, "made() and make() should return the same address.");
    }

    // Salt is keccak256(abi.encode(keyValues)) XOR bytes32(variant), not abi.encode(keyValues, variant).
    function test_StringLookupSaltIsXorOfVariant() public view {
        uint256 variant = 7;
        (,, bytes32 salt) = proto.made(config.keyValues, variant);

        bytes32 xorSalt = keccak256(abi.encode(config.keyValues)) ^ bytes32(variant);
        bytes32 absorbedSalt = keccak256(abi.encode(config.keyValues, variant));

        assertEq(salt, xorSalt, "salt should be keccak(abi.encode(kvs)) XOR variant");
        assertNotEq(salt, absorbedSalt, "salt should not absorb variant inside abi.encode");
    }

    // With variant=0 the XOR form leaves the kv-only hash unchanged; the absorbed form does not.
    function test_StringLookupSaltZeroVariantEqualsKvHash() public view {
        (,, bytes32 salt) = proto.made(config.keyValues, 0);

        bytes32 kvHash = keccak256(abi.encode(config.keyValues));
        bytes32 absorbedSalt = keccak256(abi.encode(config.keyValues, uint256(0)));

        assertEq(salt, kvHash, "salt with variant=0 should equal keccak(abi.encode(kvs))");
        assertNotEq(salt, absorbedSalt, "salt should not equal abi.encode(kvs, 0) hash");
    }

    // Helper for switching chain-ids during made()
    function _predictUnder(uint256 newChainId) internal returns (address predicted, bytes32 salt) {
        uint256 prev = block.chainid;
        vm.chainId(newChainId);
        (, predicted, salt) = proto.made(config.keyValues, 0);
        vm.chainId(prev);
    }

    // Helper for switching chain-ids during make()
    function _deployUnder(uint256 newChainId) internal returns (address deployed) {
        uint256 prev = block.chainid;
        vm.chainId(newChainId);
        deployed = proto.make(config.keyValues, 0);
        vm.chainId(prev);
    }

    // Show determinism across chain IDs (prediction)
    function test_StringLookupSamePredictedAddressAcrossChainIds() public {
        uint256 chainA = 1;
        uint256 chainB = 8453;

        (address pA, bytes32 sA) = _predictUnder(chainA);
        (address pB, bytes32 sB) = _predictUnder(chainB);

        assertEq(pA, pB, "Predicted make address should be identical across chain IDs");
        assertEq(sA, sB, "Predicted salt should be identical across chain IDs");
    }

    // Show determinism across chain IDs (deployment)
    function test_StringLookupSameDeployedAddressAcrossChainIds() public {
        uint256 chainA = 1;
        uint256 chainB = 8453;

        // Take a clean snapshot of the world right after setUp()
        uint256 snap = vm.snapshotState();

        // Deploy under chainA
        address dA = _deployUnder(chainA);
        assertNotEq(dA, address(0), "Deploy on chainA failed");

        // Roll back state so we can deploy "fresh" again
        vm.revertToState(snap);

        // Deploy under chainB
        address dB = _deployUnder(chainB);
        assertNotEq(dB, address(0), "Deploy on chainB failed");

        assertEq(dA, dB, "Deployed make address should match across chain IDs");
    }

    // Test that the value stored matches the keyValue for the current chain.
    function test_StringLookupValueMatchesCurrentChain() public {
        uint256 expectedKey = config.keyValues[0].key;
        string memory expectedValue = config.keyValues[0].value;

        vm.chainId(expectedKey);
        StringLookup home = StringLookup(proto.make(config.keyValues, 0));

        assertEq(home.value(), expectedValue, "value() should match the keyValue for the current chain");
    }

    // Test that an unmatched chain leaves value empty.
    function test_StringLookupValueEmptyWhenNoMatch() public {
        // Pick a chain id that is not in the config.
        uint256 unmatched = 424242;
        for (uint256 i; i < config.keyValues.length; ++i) {
            require(config.keyValues[i].key != unmatched, "test fixture collides with unmatched id");
        }

        vm.chainId(unmatched);
        StringLookup home = StringLookup(proto.make(config.keyValues, 0));

        assertEq(home.value(), "", "value() should be empty when no key matches block.chainid");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AddressLookup} from "../src/AddressLookup.sol";

import {Test} from "forge-std/Test.sol";

contract AddressLookupTest is Test {
    AddressLookup proto;
    Config config;

    // The contract maps a key and a network to a KV lookup table
    struct Config {
        string env;
        string id;
        AddressLookup.KeyValue[] keyValues;
    }

    // setUp() is always run before each test
    function setUp() public {
        // forge-lint: disable-next-line(unsafe-cheatcode)
        config = abi.decode(vm.parseJson(vm.readFile("test/endpoint.json")), (Config));
        // CREATE2 for proto, so its address is stable across our snapshots
        proto = new AddressLookup{salt: 0x0}();
        assertNotEq(address(proto), address(0), "proto is unexpectedly zero in setup().");
    }

    // Test make()
    function test_AddressLookupMake() public {
        address address1 = proto.make(config.keyValues);
        assertNotEq(address1, address(0), "address1 is unexpectedly zero.");
    }

    // Test redundant make()
    function test_AddressLookupMake2() public {
        address address1 = proto.make(config.keyValues);
        assertNotEq(address1, address(0), "address1 is unexpectedly zero.");

        address address2 = proto.make(config.keyValues);
        assertNotEq(address2, address(0), "address2 is unexpectedly zero.");

        assertEq(address1, address2, "Second make should return address1.");
    }

    // Test that make() clones to the address that made() predicts
    function test_AddressLookupMakeAddress() public {
        (, address address1,) = proto.made(config.keyValues);
        address address2 = proto.make(config.keyValues);
        assertEq(address1, address2, "made() and make() disagree on deployed address.");
    }

    // Test that different KVs affect the resulting address.
    function test_AddressLookupMakeDifferentKVsGivesDifferentAddress() public {
        AddressLookup.KeyValue[] memory altered = config.keyValues;
        altered[0].value = address(42);
        address address1 = proto.make(config.keyValues);
        address address2 = proto.make(altered);
        assertNotEq(address1, address(0), "make of KVs failed.");
        assertNotEq(address2, address(0), "make of modified KVs failed.");
        assertNotEq(address1, address2, "Distinct KVs should yield different make addresses");
    }

    // Test that empty KVs is acceptable (This should probably be reversed but it's currently allowed)
    function test_AddressLookupEmptyConfigIsDeterministic() public {
        AddressLookup.KeyValue[] memory empty;
        (, address address1, bytes32 salt1) = proto.made(empty);
        assertNotEq(address1, address(0), "made() on empty KVs failed.");
        assertNotEq(salt1, 0, "salt1 unexpectedly zero.");
        address address2 = proto.make(empty);
        assertNotEq(address2, address(0), "make() on empty KVs failed.");
        assertEq(address1, address2, "made() and make() should return the same address.");
    }

    // Helper for switching chain-ids during made()
    function _predictUnder(uint256 newChainId) internal returns (address predicted, bytes32 salt) {
        uint256 prev = block.chainid;
        vm.chainId(newChainId);
        (, predicted, salt) = proto.made(config.keyValues);
        vm.chainId(prev);
    }

    // Helper for switching chain-ids during make()
    function _deployUnder(uint256 newChainId) internal returns (address deployed) {
        uint256 prev = block.chainid;
        vm.chainId(newChainId);
        deployed = proto.make(config.keyValues);
        vm.chainId(prev);
    }

    // Show determinism across chain IDs (prediction)
    function test_AddressLookupSamePredictedAddressAcrossChainIds() public {
        // Pick any two distinct chain IDs you care about
        uint256 chainA = 1; // Ethereum mainnet
        uint256 chainB = 8453; // Base mainnet (example)

        (address pA, bytes32 sA) = _predictUnder(chainA);
        (address pB, bytes32 sB) = _predictUnder(chainB);

        // If your salt/bytecode/deployer are the same and you don't bake chainid into your salt,
        // these should be identical.
        assertEq(pA, pB, "Predicted make address should be identical across chain IDs");
        assertEq(sA, sB, "Predicted salt should be identical across chain IDs");
    }

    // Show determinism across chain IDs (deployment)
    function test_AddressLookupSameDeployedAddressAcrossChainIds() public {
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

        // If chain ID is not included in your salt/derivation, these must match
        assertEq(dA, dB, "Deployed make address should match across chain IDs");
    }
}

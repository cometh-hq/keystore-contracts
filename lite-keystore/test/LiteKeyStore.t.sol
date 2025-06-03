// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Test.sol";
import "../src/LiteKeyStore.sol";

contract LiteKeyStoreTest is Test {
    LiteKeyStore public keystore;
    address public safe;
    address public owner1;
    address public owner2;
    address public owner3;

    function setUp() public {
        keystore = new LiteKeyStore();
        safe = makeAddr("safe");
        owner1 = makeAddr("owner1");
        owner2 = makeAddr("owner2");
        owner3 = makeAddr("owner3");
    }

    // --- Add Owner ---

    function test_AddOwner() public {
        vm.prank(safe);
        keystore.addOwner(safe, owner1);

        assertTrue(keystore.isOwner(safe, owner1));
        address[] memory owners = keystore.getOwners(safe);
        assertEq(owners.length, 1);
        assertEq(owners[0], owner1);
    }

    function test_AddOwner_RevertIfNotSafe() public {
        vm.prank(owner1);
        vm.expectRevert("Not authorized: caller is not account");
        keystore.addOwner(safe, owner1);
    }

    function test_AddOwner_RevertIfZeroAddress() public {
        vm.prank(safe);
        vm.expectRevert(LiteKeyStore.InvalidOwner.selector);
        keystore.addOwner(safe, address(0));
    }

    function test_AddOwner_RevertIfSentinel() public {
        vm.prank(safe);
        vm.expectRevert(LiteKeyStore.InvalidOwner.selector);
        keystore.addOwner(safe, address(0x1));
    }

    function test_AddOwner_RevertIfContractItself() public {
        vm.prank(safe);
        vm.expectRevert(LiteKeyStore.InvalidOwner.selector);
        keystore.addOwner(safe, address(keystore));
    }

    function test_AddOwner_RevertIfDuplicate() public {
        vm.startPrank(safe);
        keystore.addOwner(safe, owner1);
        vm.expectRevert(LiteKeyStore.DuplicateOwner.selector);
        keystore.addOwner(safe, owner1);
    }

    function test_AddOwner_EmitsEvent() public {
        vm.startPrank(safe);
        vm.expectEmit(true, false, false, true);
        emit IKeystore.AddedOwner(owner1);
        keystore.addOwner(safe, owner1);
    }

    // --- Remove Owner ---

    function test_RemoveOwner() public {
        vm.startPrank(safe);
        keystore.addOwner(safe, owner1);
        keystore.addOwner(safe, owner2);
        keystore.removeOwner(safe, owner2, owner1);

        assertFalse(keystore.isOwner(safe, owner1));
        assertTrue(keystore.isOwner(safe, owner2));

        address[] memory owners = keystore.getOwners(safe);
        assertEq(owners.length, 1);
        assertEq(owners[0], owner2);
    }

    function test_RemoveOwner_RevertIfNotSafe() public {
        vm.startPrank(safe);
        keystore.addOwner(safe, owner1);
        vm.stopPrank();

        vm.prank(owner1);
        vm.expectRevert("Not authorized: caller is not account");
        keystore.removeOwner(safe, address(0x1), owner1);
    }

    function test_RemoveOwner_RevertIfLastOwner() public {
        vm.prank(safe);
        keystore.addOwner(safe, owner1);

        vm.prank(safe);
        vm.expectRevert(LiteKeyStore.LastOwnerRemovalNotAllowed.selector);
        keystore.removeOwner(safe, address(0x1), owner1);
    }

    function test_RemoveOwner_RevertIfInvalidPrevOwner() public {
        vm.startPrank(safe);
        keystore.addOwner(safe, owner1);
        keystore.addOwner(safe, owner2);

        vm.expectRevert(LiteKeyStore.OwnerMismatch.selector);
        keystore.removeOwner(safe, owner1, owner2);
    }

    function test_RemoveOwner_RevertIfInvalidOwner() public {
        vm.startPrank(safe);
        keystore.addOwner(safe, owner1);
        keystore.addOwner(safe, owner2);

        vm.expectRevert(LiteKeyStore.OwnerMismatch.selector);
        keystore.removeOwner(safe, address(0), owner2);
    }

    function test_RemoveOwner_EmitsEvent() public {
        vm.startPrank(safe);
        keystore.addOwner(safe, owner1);
        keystore.addOwner(safe, owner2);

        vm.expectEmit(true, false, false, true);
        emit IKeystore.RemovedOwner(owner1);
        keystore.removeOwner(safe, owner2, owner1);
    }

    // --- Swap Owner ---

    function test_SwapOwner() public {
        vm.startPrank(safe);
        keystore.addOwner(safe, owner1);
        keystore.addOwner(safe, owner2);
        keystore.swapOwner(safe, owner2, owner1, owner3);

        assertFalse(keystore.isOwner(safe, owner1));
        assertTrue(keystore.isOwner(safe, owner2));
        assertTrue(keystore.isOwner(safe, owner3));

        address[] memory owners = keystore.getOwners(safe);
        assertEq(owners.length, 2);
        assertTrue((owners[0] == owner2 && owners[1] == owner3) || (owners[0] == owner3 && owners[1] == owner2));
    }

    function test_SwapOwner_RevertIfNotSafe() public {
        vm.startPrank(safe);
        keystore.addOwner(safe, owner1);
        vm.stopPrank();

        vm.prank(owner1);
        vm.expectRevert("Not authorized: caller is not account");
        keystore.swapOwner(safe, address(0x1), owner1, owner2);
    }

    function test_SwapOwner_RevertIfInvalidNewOwner() public {
        vm.startPrank(safe);
        keystore.addOwner(safe, owner1);

        vm.expectRevert(LiteKeyStore.InvalidOwner.selector);
        keystore.swapOwner(safe, address(0x1), owner1, address(0));
    }

    function test_SwapOwner_RevertIfDuplicate() public {
        vm.startPrank(safe);
        keystore.addOwner(safe, owner1);
        keystore.addOwner(safe, owner2);

        vm.expectRevert(LiteKeyStore.DuplicateOwner.selector);
        keystore.swapOwner(safe, address(0x1), owner1, owner2);
    }

    function test_SwapOwner_RevertIfInvalidPrevOwner() public {
        vm.startPrank(safe);
        keystore.addOwner(safe, owner1);
        keystore.addOwner(safe, owner2);

        vm.expectRevert(LiteKeyStore.OwnerMismatch.selector);
        keystore.swapOwner(safe, owner1, owner2, owner3);
    }

    function test_SwapOwner_RevertIfInvalidOldOwner() public {
        vm.startPrank(safe);
        keystore.addOwner(safe, owner1);
        keystore.addOwner(safe, owner2);

        vm.expectRevert(LiteKeyStore.OwnerMismatch.selector);
        keystore.swapOwner(safe, address(0), owner2, owner3);
    }

    function test_SwapOwner_EmitsEvents() public {
        vm.startPrank(safe);
        keystore.addOwner(safe, owner1);
        keystore.addOwner(safe, owner2);

        vm.expectEmit(true, false, false, true);
        emit IKeystore.RemovedOwner(owner1);
        vm.expectEmit(true, false, false, true);
        emit IKeystore.AddedOwner(owner3);

        keystore.swapOwner(safe, owner2, owner1, owner3);
    }

    // --- GetOwners ---

    function test_GetOwners() public {
        vm.startPrank(safe);
        keystore.addOwner(safe, owner1);
        keystore.addOwner(safe, owner2);
        keystore.addOwner(safe, owner3);

        address[] memory owners = keystore.getOwners(safe);
        assertEq(owners.length, 3);
        assertEq(owners[0], owner3);
        assertEq(owners[1], owner2);
        assertEq(owners[2], owner1);
    }
}

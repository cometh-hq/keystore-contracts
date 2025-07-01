// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Test.sol";
import "../src/SlimKeyStore.sol";

contract SlimKeyStoreTest is Test {
    SlimKeyStore public keystore;
    address public safe;
    address public owner1;
    address public owner2;
    address public owner3;

    function setUp() public {
        keystore = new SlimKeyStore();
        safe = makeAddr("safe");
        owner1 = makeAddr("owner1");
        owner2 = makeAddr("owner2");
        owner3 = makeAddr("owner3");

        vm.prank(safe);
        keystore.addOwnerWithThreshold(safe, owner1, 1);
    }

    // --- Add Owner With Threshold ---

    function test_AddOwnerWithThreshold_RevertIfNotSafe() public {
        vm.prank(owner1);
        vm.expectRevert("Not authorized: caller is not account");
        keystore.addOwnerWithThreshold(safe, owner2, 1);
    }

    function test_AddOwnerWithThreshold_RevertIfInvalidOwner() public {
        vm.startPrank(safe);
        vm.expectRevert(SlimKeyStore.InvalidOwner.selector);
        keystore.addOwnerWithThreshold(safe, address(0), 1);

        vm.expectRevert(SlimKeyStore.InvalidOwner.selector);
        keystore.addOwnerWithThreshold(safe, address(0x1), 1);

        vm.expectRevert(SlimKeyStore.InvalidOwner.selector);
        keystore.addOwnerWithThreshold(safe, address(keystore), 1);
    }

    function test_AddOwnerWithThreshold_RevertIfDuplicate() public {
        vm.prank(safe);
        vm.expectRevert(SlimKeyStore.DuplicateOwner.selector);
        keystore.addOwnerWithThreshold(safe, owner1, 1);
    }

    function test_AddOwnerWithThreshold_RevertIfThresholdTooHigh() public {
        vm.prank(safe);
        vm.expectRevert(SlimKeyStore.ThresholdExceedsOwnerCount.selector);
        keystore.addOwnerWithThreshold(safe, owner2, 3);
    }

    function test_AddOwnerWithThreshold_RevertIfThresholdZero() public {
        vm.prank(safe);
        vm.expectRevert(SlimKeyStore.ThresholdMustBePositive.selector);
        keystore.addOwnerWithThreshold(safe, owner2, 0);
    }

    function test_AddOwnerWithThreshold_Works() public {
        vm.prank(safe);
        keystore.addOwnerWithThreshold(safe, owner2, 2);
        assertTrue(keystore.isOwner(safe, owner2));
        assertEq(keystore.getThreshold(safe), 2);
    }

    // --- Remove Owner With Threshold ---

    function test_RemoveOwnerWithThreshold_RevertIfNotSafe() public {
        vm.prank(owner1);
        vm.expectRevert("Not authorized: caller is not account");
        keystore.removeOwnerWithThreshold(safe, address(0x1), owner1, 1);
    }

    function test_RemoveOwnerWithThreshold_RevertIfInvalid() public {
        vm.prank(safe);
        vm.expectRevert(SlimKeyStore.LastOwnerRemovalNotAllowed.selector);
        keystore.removeOwnerWithThreshold(safe, address(0x1), owner1, 0);
    }

    function test_RemoveOwnerWithThreshold_RevertIfThresholdTooHigh() public {
        vm.startPrank(safe);
        keystore.addOwnerWithThreshold(safe, owner2, 2);
        vm.expectRevert(SlimKeyStore.ThresholdExceedsOwnerCount.selector);
        keystore.removeOwnerWithThreshold(safe, owner2, owner1, 3);
    }

    function test_RemoveOwnerWithThreshold_RevertIfThresholdZero() public {
        vm.startPrank(safe);
        keystore.addOwnerWithThreshold(safe, owner2, 2);
        vm.expectRevert(SlimKeyStore.ThresholdMustBePositive.selector);
        keystore.removeOwnerWithThreshold(safe, owner2, owner1, 0);
    }

    function test_RemoveOwnerWithThreshold_RevertIfInvalidPrevOwner() public {
        vm.startPrank(safe);
        keystore.addOwnerWithThreshold(safe, owner2, 2);
        vm.expectRevert(SlimKeyStore.OwnerMismatch.selector);
        keystore.removeOwnerWithThreshold(safe, owner1, owner2, 1);
    }

    function test_RemoveOwnerWithThreshold_Works() public {
        vm.startPrank(safe);
        keystore.addOwnerWithThreshold(safe, owner2, 2);
        keystore.removeOwnerWithThreshold(safe, owner2, owner1, 1);
        assertFalse(keystore.isOwner(safe, owner1));
        assertEq(keystore.getThreshold(safe), 1);
    }

    // --- Swap Owner ---

    function test_SwapOwner_RevertIfNotSafe() public {
        vm.prank(owner1);
        vm.expectRevert("Not authorized: caller is not account");
        keystore.swapOwner(safe, address(0x1), owner1, owner2);
    }

    function test_SwapOwner_RevertIfInvalidNewOwner() public {
        vm.prank(safe);
        vm.expectRevert(SlimKeyStore.InvalidOwner.selector);
        keystore.swapOwner(safe, address(0x1), owner1, address(0));
    }

    function test_SwapOwner_RevertIfDuplicate() public {
        vm.startPrank(safe);
        keystore.addOwnerWithThreshold(safe, owner2, 2);
        vm.expectRevert(SlimKeyStore.DuplicateOwner.selector);
        keystore.swapOwner(safe, owner2, owner1, owner2);
    }

    function test_SwapOwner_RevertIfInvalidPrevOwner() public {
        vm.startPrank(safe);
        keystore.addOwnerWithThreshold(safe, owner2, 2);
        vm.expectRevert(SlimKeyStore.OwnerMismatch.selector);
        keystore.swapOwner(safe, owner1, owner2, owner3);
    }

    function test_SwapOwner_Works() public {
        vm.startPrank(safe);
        keystore.addOwnerWithThreshold(safe, owner2, 2);
        keystore.swapOwner(safe, owner2, owner1, owner3);
        assertTrue(keystore.isOwner(safe, owner3));
        assertFalse(keystore.isOwner(safe, owner1));
    }

    // --- Change Threshold ---

    function test_ChangeThreshold_RevertIfNotSafe() public {
        vm.prank(owner1);
        vm.expectRevert("Not authorized: caller is not account");
        keystore.changeThreshold(safe, 2);
    }

    function test_ChangeThreshold_RevertIfZero() public {
        vm.prank(safe);
        vm.expectRevert(SlimKeyStore.ThresholdMustBePositive.selector);
        keystore.changeThreshold(safe, 0);
    }

    function test_ChangeThreshold_RevertIfAboveOwnerCount() public {
        vm.prank(safe);
        vm.expectRevert(SlimKeyStore.ThresholdExceedsOwnerCount.selector);
        keystore.changeThreshold(safe, 2);
    }

    function test_ChangeThreshold_Works() public {
        vm.startPrank(safe);
        keystore.addOwnerWithThreshold(safe, owner2, 2);
        keystore.changeThreshold(safe, 1);
        assertEq(keystore.getThreshold(safe), 1);
    }

    // --- Get Owners ---

    function test_GetOwners_ReturnsAll() public {
        vm.startPrank(safe);
        keystore.addOwnerWithThreshold(safe, owner2, 2);
        keystore.addOwnerWithThreshold(safe, owner3, 2);
        address[] memory owners = keystore.getOwners(safe);
        assertEq(owners.length, 3);
    }
}

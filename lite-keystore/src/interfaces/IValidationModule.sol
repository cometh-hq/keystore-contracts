// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IModule is IERC165 {
    /// @notice Initialize module data for the modular account.
    /// @dev Called by the modular account during `installExecution`.
    /// @param data Optional bytes array to be decoded and used by the module to setup initial module data for the
    /// modular account.
    function onInstall(bytes calldata data) external;

    /// @notice Clear module data for the modular account.
    /// @dev Called by the modular account during `uninstallExecution`.
    /// @param data Optional bytes array to be decoded and used by the module to clear module data for the modular
    /// account.
    function onUninstall(bytes calldata data) external;

    /// @notice Return a unique identifier for the module.
    /// @dev This function MUST return a string in the format "vendor.module.semver". The vendor and module
    /// names MUST NOT contain a period character.
    /// @return The module ID.
    function moduleId() external view returns (string memory);
}

interface IValidationModule is IModule {
    /// @notice Run the user operation validation function specified by the `entityId`.
    /// @param entityId An identifier that routes the call to different internal implementations, should there
    /// be more than one.
    /// @param userOp The user operation.
    /// @param userOpHash The user operation hash.
    /// @return Packed validation data for validAfter (6 bytes), validUntil (6 bytes), and authorizer (20 bytes).
    function validateUserOp(uint32 entityId, PackedUserOperation calldata userOp, bytes32 userOpHash)
        external
        returns (uint256);

    /// @notice Validates a signature using ERC-1271.
    /// @dev To indicate the entire call should revert, the function MUST revert.
    /// @param account the account to validate for.
    /// @param entityId An identifier that routes the call to different internal implementations, should there
    /// be more than one.
    /// @param sender the address that sent the ERC-1271 request to the smart account
    /// @param hash the hash of the ERC-1271 request
    /// @param signature the signature of the ERC-1271 request
    /// @return the ERC-1271 `MAGIC_VALUE` if the signature is valid, or 0xFFFFFFFF if invalid.
    function validateSignature(address account, uint32 entityId, address sender, bytes32 hash, bytes calldata signature)
        external
        view
        returns (bytes4);
}

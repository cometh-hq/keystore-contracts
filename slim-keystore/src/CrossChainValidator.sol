// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { IValidationModule, IModule as IERC6900Module } from "./interfaces/IValidationModule.sol";

import { IStorageVerifier } from "./interfaces/IStorageVerifier.sol";

import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";
import { ValidationData as ValidationData4337 } from "@ERC4337/account-abstraction/contracts/core/Helpers.sol";
import { ERC7579ValidatorBase } from "modulekit/module-bases/ERC7579ValidatorBase.sol";
import { IModule as IERC7579Module } from "modulekit/accounts/common/interfaces/IERC7579Module.sol";
import { _packValidationData as _packValidationData4337 } from "modulekit/external/ERC4337.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { MPT } from "./lib/MPT.sol";

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

contract CrossChainValidator is ERC7579ValidatorBase, IValidationModule {
    struct StorageProofData {
        uint256 chainId;
        address owner;
        uint256 slotValue;
        MPT.Account account;
        bytes[] accountProof;
        bytes[] storageProof;
    }

    struct SignatureData {
        StorageProofData storageProofData;
        bytes signature;
    }

    error UnsupportedOperation();
    error InvalidSignatureLength();
    error InvalidTargetAccount();
    error InvalidChainId();
    error ExternalRecoverNotAllowed();

    IStorageVerifier public storageVerifier;
    address public slimKeyStore;
    uint256 public constant LITE_KEY_STORE_OWNERS_SLOT = 0;

    constructor(IStorageVerifier _storageVerifier, address _slimKeyStore) {
        storageVerifier = _storageVerifier;
        slimKeyStore = _slimKeyStore;
    }

    function getKeyStoreOwnersSlot(address account, address owner) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(owner, keccak256(abi.encode(account, LITE_KEY_STORE_OWNERS_SLOT)))));
    }

    /**
     * @dev This function is called by the smart account during installation of the module
     *
     * @param data We expect the data to be formatted as `abi.encode(uint248)`
     * MUST revert on error (i.e. if module is already enabled)
     */
    function onInstall(bytes calldata data) external override(IERC6900Module, IERC7579Module) { }

    /**
     * @dev This function is called by the smart account during uninstallation of the module
     *
     * MUST revert on error
     */
    function onUninstall(bytes calldata) external override(IERC6900Module, IERC7579Module) { }

    /**
     * @dev Returns boolean value if module is a certain type
     * @param moduleTypeId the module type ID according the ERC-7579 spec
     *
     * MUST return true if the module is of the given type and false otherwise
     */
    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return moduleTypeId == TYPE_VALIDATOR;
    }

    function validateUserOp(uint32, PackedUserOperation calldata userOp, bytes32 userOpHash)
        public
        view
        override
        returns (uint256)
    {
        return ValidationData.unwrap(validateUserOp(userOp, userOpHash));
    }

    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash)
        public
        view
        override
        returns (ValidationData)
    {
        SignatureData calldata data = _decodeUserOpSignature(userOp.signature);

        StorageProofData calldata storageProofData = data.storageProofData;

        if (storageProofData.chainId != block.chainid) revert InvalidChainId();

        if (slimKeyStore != storageProofData.account.accountAddress) revert InvalidTargetAccount();

        MPT.StorageSlot memory ownersSlot = MPT.StorageSlot({
            position: getKeyStoreOwnersSlot(userOp.sender, storageProofData.owner),
            value: storageProofData.slotValue
        });

        // Verify the Merkle proof which ensure the provided data are valid
        bool isValid = storageVerifier._verifyStorage(
            storageProofData.account, ownersSlot, storageProofData.accountProof, storageProofData.storageProof
        );

        if (!isValid) return VALIDATION_FAILED;

        bytes calldata masterOwnerSignature = data.signature;

        // Try catch to enable simulation with a mock signature
        try this.recoverSigner(userOpHash, masterOwnerSignature) returns (address recoveredSigner) {
            address signer = recoveredSigner;

            if (signer != storageProofData.owner) return VALIDATION_FAILED;
        } catch {
            return VALIDATION_FAILED;
        }

        return VALIDATION_SUCCESS;
    }

    // Add external function for use in try-catch
    function recoverSigner(bytes32 hash, bytes calldata signature) external view returns (address) {
        if (msg.sender != address(this)) revert ExternalRecoverNotAllowed();
        if (signature.length != 65) revert InvalidSignatureLength();

        (bytes32 r, bytes32 s, uint8 v) = _parseSignature(signature);
        return ECDSA.recover(hash, v, r, s);
    }

    /// @dev This function assumes `signature` is already of length 65.
    /// @param signature - The signature to parse.
    /// @return r - The r component of the signature.
    /// @return s - The s component of the signature.
    /// @return v - The v component of the signature.
    function _parseSignature(bytes calldata signature) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        /// @solidity memory-safe-assembly
        assembly {
            r := calldataload(signature.offset)
            s := calldataload(add(signature.offset, 0x20))
            v := byte(0, calldataload(add(signature.offset, 0x40)))
        }
    }

    function _decodeUserOpSignature(bytes calldata signature) internal pure returns (SignatureData calldata out) {
        /// @solidity memory-safe-assembly
        assembly {
            out := signature.offset
        }
    }

    function isValidSignatureWithSender(address, bytes32, bytes calldata) external pure override returns (bytes4) {
        revert UnsupportedOperation();
    }

    function validateSignature(address, uint32, address, bytes32, bytes calldata) external pure returns (bytes4) {
        revert UnsupportedOperation();
    }

    function moduleId() external pure returns (string memory) {
        return "cometh.ecdsa.v0.1.0";
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IValidationModule).interfaceId || interfaceId == type(IERC6900Module).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    function isInitialized(address smartAccount) external view override returns (bool) { }
}

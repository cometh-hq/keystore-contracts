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
    struct OwnerData {
        address owner;
        address prevOwner;
        uint256 ownerSlotValue;
        bytes[] ownerStorageProof;
        bytes signature;
    }

    struct ThresholdData {
        uint256 threshold;
        uint256 thresholdSlotValue;
        bytes[] thresholdStorageProof;
    }

    struct CrosschainValidationData {
        uint256 chainId;
        MPT.Account account;
        bytes[] accountProof;
        OwnerData[] ownerData;
        ThresholdData thresholdData;
    }

    error UnsupportedOperation();
    error InvalidSignatureLength();
    error InvalidTargetAccount();
    error InvalidChainId();
    error ExternalRecoverNotAllowed();

    IStorageVerifier public storageVerifier;
    address public slimKeyStoreAddress;
    uint256 public constant SLIM_KEYSTORE_OWNERS_SLOT = 0;
    uint256 public constant SLIM_KEYSTORE_THRESHOLD_SLOT = 2;

    constructor(IStorageVerifier _storageVerifier, address _slimKeyStore) {
        storageVerifier = _storageVerifier;
        slimKeyStoreAddress = _slimKeyStore;
    }

    /**
     * @dev This function is called to get the owners slot for a given account and owner
     *
     * @param account The account to get the owners slot
     * @param prevOwner The previous owner to get the owners slot for
     *
     * @return The owners slot for the given account and owner
     */
    function getKeyStoreOwnersSlot(address account, address prevOwner) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(prevOwner, keccak256(abi.encode(account, SLIM_KEYSTORE_OWNERS_SLOT)))));
    }

    /**
     * @dev This function is called to get the threshold slot for a given account
     *
     * @param account The account to get the threshold slot for
     *
     * @return The threshold slot for the given account
     */
    function getKeyStoreThresholdSlot(address account) public pure returns (uint256) {
        return uint256(keccak256(abi.encode(account, SLIM_KEYSTORE_THRESHOLD_SLOT)));
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
        CrosschainValidationData calldata data = _decodeUserOpSignature(userOp.signature);
        if (slimKeyStoreAddress != data.account.accountAddress) revert InvalidTargetAccount();

        bool isAccountValid = storageVerifier._verifyAccount(data.account, data.accountProof);
        if (!isAccountValid) return VALIDATION_FAILED;

        // Verify threshold storage proof
        ThresholdData calldata thresholdData = data.thresholdData;

        MPT.StorageSlot memory thresholdSlot = MPT.StorageSlot({
            position: getKeyStoreThresholdSlot(userOp.sender),
            value: thresholdData.thresholdSlotValue
        });

        bool isThresholdValid =
            storageVerifier._verifyStorageSlot(data.account, thresholdSlot, thresholdData.thresholdStorageProof);
        if (!isThresholdValid) return VALIDATION_FAILED;
        if (data.ownerData.length < thresholdData.threshold) return VALIDATION_FAILED;
        ////////////////////////////////////////////////////////////////

        // Verify owners storage proofs
        address[] memory verifiedOwners = new address[](thresholdData.threshold);
        uint256 validSignatures;

        for (uint256 i = 0; i < data.ownerData.length; i++) {
            OwnerData calldata ownerData = data.ownerData[i];

            MPT.StorageSlot memory ownersSlot = MPT.StorageSlot({
                position: getKeyStoreOwnersSlot(userOp.sender, ownerData.prevOwner),
                value: ownerData.ownerSlotValue
            });

            bool isOwnerValid =
                storageVerifier._verifyStorageSlot(data.account, ownersSlot, ownerData.ownerStorageProof);
            if (!isOwnerValid) return VALIDATION_FAILED;

            try this.recoverSigner(userOpHash, ownerData.signature) returns (address recoveredSigner) {
                if (recoveredSigner != ownerData.owner) return VALIDATION_FAILED;

                for (uint256 j = 0; j < validSignatures; j++) {
                    if (verifiedOwners[j] == recoveredSigner) return VALIDATION_FAILED;
                }

                verifiedOwners[validSignatures] = recoveredSigner;
                validSignatures++;
            } catch {
                return VALIDATION_FAILED;
            }
        }
        ////////////////////////////////////////////////////////////////

        if (validSignatures < thresholdData.threshold) return VALIDATION_FAILED;

        return VALIDATION_SUCCESS;
    }

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

    function _decodeUserOpSignature(bytes calldata signature)
        internal
        pure
        returns (CrosschainValidationData calldata out)
    {
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

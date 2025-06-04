// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { MPT } from "./MPT.sol";
import { IStorageVerifier } from "../interfaces/IStorageVerifier.sol";
import { StateRootStorage } from "@cometh/state-root-bridger/StateRootStorage.sol";

contract StorageVerifier is IStorageVerifier {
    StateRootStorage public blockStorage;

    error InvalidAccountProof();
    error InvalidStorageProof();

    constructor(address stateRootStorage) {
        blockStorage = StateRootStorage(stateRootStorage);
    }

    /**
     * @notice Verify ownership of given account
     * @param account The account
     * @param contractSlot The storage value of the keystore owners slot (the next owner in the chained list after the provided owner)
     * @param accountProof The proof of the account
     * @param storageProof The proof of the storage slot from account
     * @return True if the proof is verified
     */
    function _verifyStorage(
        MPT.Account memory account,
        MPT.StorageSlot memory contractSlot,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) public view returns (bool) {
        if (!MPT.verifyAccount(blockStorage.stateRoot(), account, accountProof)) revert InvalidAccountProof();

        if (!MPT.verifyStorageSlot(account.storageRoot, contractSlot, storageProof)) revert InvalidStorageProof();

        return true;
    }
}

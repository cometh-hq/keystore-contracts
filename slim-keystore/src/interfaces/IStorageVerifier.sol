// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { MPT } from "../lib/MPT.sol";

interface IStorageVerifier {
    function _verifyAccount(MPT.Account memory account, bytes[] memory accountProof) external view returns (bool);

    function _verifyStorageSlot(MPT.Account memory account, MPT.StorageSlot memory slot, bytes[] memory storageProof)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { MPT } from "../lib/MPT.sol";

interface IStorageVerifier {
    function _verifyStorage(
        MPT.Account memory account,
        MPT.StorageSlot memory slot,
        bytes[] memory accountProof,
        bytes[] memory storageProof
    ) external view returns (bool);
}

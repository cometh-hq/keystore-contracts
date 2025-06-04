// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @notice Represents the stateRoot of a given block
 * @dev The payload is sent to every supported child chain through layerZero
*/
struct StateRootProof {
    bytes32 stateRoot; // The state root hash of the block.
    uint256 blockNumber; // The block number at which the proof is generated.
    bytes32 blockHash; // The block hash of the block.
}

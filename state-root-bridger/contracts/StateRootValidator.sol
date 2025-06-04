// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "solidity-rlp/contracts/RLPReader.sol";
import {StateRootDistributor} from "./StateRootDistributor.sol";
import {StateRootProof} from "./lib/ValidorStructs.sol";

contract StateRootValidator is StateRootDistributor {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    uint public savedBlockNumber;

    error BlockNumberTooOld(uint providedBlockNumber, uint currentBlockNumber);

    event BlockHeaderAdded(uint blockNumber, bytes32 stateRoot, bytes32 blockHash);
    event ReconstructedBlockHash(bytes32 blockHash);
    event ReconstructedBlockHashFromRlp(bytes32 blockHash);
    event ChainBlockNumber(uint blockNumber);
    event ProvidedBlockNumber(uint blockNumber);
    constructor(address _owner, address _endpoint, uint32[] memory _validatorDestIds) StateRootDistributor(_owner , _endpoint, _validatorDestIds) {
    }

    function addBlockHeader(bytes calldata _rlpHeader, bytes calldata _options) payable external {
        // Decode the RLP and extract parentHash.
        RLPReader.RLPItem[] memory items = _rlpHeader.toRlpItem().toList();
        bytes32 stateRoot = bytes32(items[3].toBytes());
        uint blockNumber = uint(items[8].toUint());

        // Verify the hash of the RLP header matches the on chain block hash at given blockNumber.
        bytes32 targetBlockHash = blockhash(blockNumber);

        emit ReconstructedBlockHash(targetBlockHash);
        emit ReconstructedBlockHashFromRlp(keccak256(_rlpHeader));

        require(keccak256(_rlpHeader) == targetBlockHash, "Invalid block hash");

        // If this is the first block, skip parentHash check.
        if (savedBlockNumber != 0) {
            require(savedBlockNumber < blockNumber, "Given Block header is older than saved block");
        }

        // Update to latest block number
        savedBlockNumber = blockNumber;

        // Propagate the new block header
        propagateNewBlock(StateRootProof(stateRoot, blockNumber, targetBlockHash), _options);
        emit BlockHeaderAdded(blockNumber, stateRoot, targetBlockHash);
    }
}

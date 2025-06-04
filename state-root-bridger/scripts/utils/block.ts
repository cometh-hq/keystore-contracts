import { network } from "hardhat";
import { ethers } from "ethers";
import { RLP } from '@ethereumjs/rlp'

export async function getBlock(blockNumber: string = "latest") {
    const block: any = await network.provider.request({
        method: "eth_getBlockByNumber",
        params: [blockNumber, false]
    });

    return block;
}

function formatEmpty(data: string): string {
    return data == '0x0' ? '0x' : data
}

export function encodeBlock(block: any): { encodedHeader: any, recreatedBlockHash: string } {
    const header = [
        block.parentHash,
        block.sha3Uncles,
        block.miner,
        block.stateRoot,
        block.transactionsRoot,
        block.receiptsRoot,
        block.logsBloom,
        block.difficulty,
        block.number,
        block.gasLimit,
        block.gasUsed,
        block.timestamp,
        block.extraData,
        block.mixHash,
        block.nonce,
    ];

    // Post-London (EIP-1559)
    if (block.baseFeePerGas !== undefined) {
        header.push(block.baseFeePerGas);
    }

    // Post-Shanghai (EIP-4895)
    if (block.withdrawalsRoot !== undefined) {
        header.push(block.withdrawalsRoot);
    }

    // Post-Cancun (EIP-4844)
    if (block.blobGasUsed !== undefined) {
        header.push(block.blobGasUsed);
        header.push(block.excessBlobGas);
    }

    // Post-Dencun (EIP-4788)
    if (block.parentBeaconBlockRoot !== undefined) {
        header.push(block.parentBeaconBlockRoot);
    }

    // Post-Pectra (EIP-7685)
    if (block.requestsHash !== undefined) {
        header.push(block.requestsHash);
    }

    const encodedHeader = RLP.encode(header.map(formatEmpty));
    const encodedHeaderHex = Buffer.from(encodedHeader).toString('hex');
    const recreatedBlockHash = ethers.utils.keccak256('0x' + encodedHeaderHex);

    return { encodedHeader, recreatedBlockHash }
}

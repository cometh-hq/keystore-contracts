import { ethers } from "hardhat"
import { getAccount, getEnv } from "./utils/env"
import { Options } from "@layerzerolabs/lz-v2-utilities";
import { encodeBlock, getBlock } from "./utils/block";
import assert from "assert";

const main = async () => {
    const validatorAddress = getEnv(`CONTRACT_ROOT_VALIDATOR`)
    const ownerMain: any = await getAccount(0)
    const ownerMainAddress = await ownerMain.getAddress()

    console.log(`account[${ownerMainAddress}] >> contract[${validatorAddress}]`)
    const Validator = await ethers.getContractFactory('StateRootValidator')

    const validator: any = new ethers.Contract(validatorAddress, Validator.interface, ownerMain)

    const options = Options.newOptions().addExecutorLzReceiveOption(200000, 0).toHex().toString()

    const block = await getBlock()
    const stateRoot = block.stateRoot
    const hash = block.hash
    const blockNumber = block.number
    console.log(`blockNumber: ${parseInt(blockNumber)}`)
    const encoded = encodeBlock(block)
    const recreatedBlockHash = encoded.recreatedBlockHash
    const encodedHeader = encoded.encodedHeader

    assert(hash === recreatedBlockHash, 'Block hash mismatch')
    const totalFees = await validator.fullQuote({
        stateRoot: stateRoot,
        blockNumber: blockNumber,
        blockHash: hash
    }, options)

    console.log(`Total fees: ${totalFees.toString()}`)

    const tx = await validator.addBlockHeader(encodedHeader, options, {
        value: totalFees
    })
    console.log('Transaction hash:', tx.hash)
    await tx.wait()
    console.log(`Transaction confirmed [stateRoot= ${stateRoot}, blockNumber= ${blockNumber}]`)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})

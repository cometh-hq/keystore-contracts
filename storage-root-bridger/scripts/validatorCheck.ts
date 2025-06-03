import {ethers} from "hardhat"
import {getAccount, getEnv} from "./utils/env"

const main = async () => {
    const validatorAddress = getEnv(`CONTRACT_ROOT_VALIDATOR`)
    const ownerMain = await getAccount(0)
    const ownerMainAddress = await ownerMain.getAddress()

    console.log(`account[${ownerMainAddress}] >> contract[${validatorAddress}]`)
    const Validator = await ethers.getContractFactory('StateRootValidator')

    const validator: any = new ethers.Contract(validatorAddress, Validator.interface, ownerMain)

    console.log(`- Validator: ${validator.address}`)
    console.log(`- Saved blockNumber: ${await validator.savedBlockNumber()}`)
    console.log(`- destIds[0]: ${await validator.validatorDestIds(0)}`)
    console.log(`- destIds[1]: ${await validator.validatorDestIds(1)}`)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})

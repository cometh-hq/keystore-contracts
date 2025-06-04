import {ethers} from "hardhat"
import {getAccount, getEnv} from "./utils/env"

const main = async () => {
    const storageAddress = getEnv(`CONTRACT_ROOT_STORAGE`)
    const ownerMain = await getAccount(0)
    const ownerMainAddress = await ownerMain.getAddress()

    console.log(`account[${ownerMainAddress}] >> contract[${storageAddress}]`)
    const Storage = await ethers.getContractFactory('StateRootStorage')

    const storage: any = new ethers.Contract(storageAddress, Storage.interface, ownerMain)
    console.log(`- Storage: ${storage.address}`)
    console.log(`- Saved blockNumber: ${await storage.blockNumber()}`)
    console.log(`- Saved stateRoot: ${await storage.stateRoot()}`)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})

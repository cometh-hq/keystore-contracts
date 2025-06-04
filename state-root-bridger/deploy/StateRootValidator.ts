import assert from 'assert'

import {type DeployFunction} from 'hardhat-deploy/types'
import {getEnv} from "../scripts/utils/env";

const contractName = 'StateRootValidator'

function getDestIds(): number[] {
    const supportedNetworks = getEnv('SUPPORTED_NETWORKS')
    return supportedNetworks.split(',').map((chainId) => {
        return parseInt(getEnv(`L0_DESTEID_${chainId}`))
    })
}

const deploy: DeployFunction = async (hre) => {
    const {getNamedAccounts, deployments} = hre

    const {deploy} = deployments
    const {deployer} = await getNamedAccounts()

    assert(deployer, 'Missing named deployer account')

    console.log(`Deploying on Network: ${hre.network.name}`)
    console.log(`Deployer: ${deployer}`)
    const networkName = hre.network.name.toUpperCase()

    const owner = process.env.DEPLOYER_ADDRESS
    if (!owner) {
        throw new Error('DEPLOYER_ADDRESS is required')
    }
    const l0Endpoint = process.env[`L0_ENDPOINT_${networkName}`]
    if (!l0Endpoint) {
        throw new Error(`L0_ENDPOINT_${networkName} is required`)
    }

    const destIds = getDestIds()
    const {address} = await deploy(contractName, {
        from: deployer,
        args: [owner, l0Endpoint, destIds],
        log: true,
        skipIfAlreadyDeployed: false,
        deterministicDeployment: true
    })

    console.log(`Deployed contract: ${contractName}, network: ${hre.network.name}, address: ${address}`)
}

deploy.tags = [contractName, 'validator']

export default deploy

import { EndpointId } from '@layerzerolabs/lz-definitions'

import type { OAppOmniGraphHardhat } from '@layerzerolabs/toolbox-hardhat'

type Contract = {
    eid: EndpointId
    contractName: string
}

const stateRootStorage: { [key: string]: { eid: number, contractName: string } } = {
    // sepolia: {
    //     eid: EndpointId.SEPOLIA_V2_TESTNET,
    //     contractName: 'StateRootStorage',
    // },
    // amoy: {
    //     eid: EndpointId.AMOY_V2_TESTNET,
    //     contractName: 'StateRootStorage',
    // },
    baseTest: {
        eid: EndpointId.BASESEP_V2_TESTNET,
        contractName: 'StateRootStorage',
    },
    arbitrumTest: {
        eid: EndpointId.ARBSEP_V2_TESTNET,
        contractName: 'StateRootStorage',
    }
}

const stateRootValidator: { [key: string]: { eid: number, contractName: string } } = {
    // sepolia: {
    //     eid: EndpointId.SEPOLIA_V2_TESTNET,
    //     contractName: 'StateRootValidator',
    // },
    // amoy: {
    //     eid: EndpointId.AMOY_V2_TESTNET,
    //     contractName: 'StateRootValidator',
    // },
    baseTest: {
        eid: EndpointId.BASESEP_V2_TESTNET,
        contractName: 'StateRootValidator',
    },
    /*  arbitrumTest: {
         eid: EndpointId.ARBSEP_V2_TESTNET,
         contractName: 'StateRootValidator',
     } */
}

type Connection = {
    from: Contract
    to: Contract
}

const buildContracts = (): { contract: Contract }[] => {
    const result = []
    for (const network in stateRootStorage) {
        result.push({ contract: stateRootStorage[network] })
    }
    for (const network in stateRootValidator) {
        result.push({ contract: stateRootValidator[network] })
    }
    return result
}

const networkConfig: { [key: string]: any } = {
    sepolia: {
        // sendLibrary: "0xcc1ae8Cf5D3904Cef3360A9532B477529b177cCE",
        // receiveLibraryConfig: {
        //     receiveLibrary: "0xdAf00F5eE2158dD58E0d3857851c432E34A3A851",
        //     gracePeriod: BigInt(0)
        // }
    },
    amoy: {
        // sendLibrary: "0x1d186C560281B8F1AF831957ED5047fD3AB902F9",
        // receiveLibraryConfig: {
        //     receiveLibrary: "0x53fd4C4fBBd53F6bC58CaE6704b92dB1f360A648",
        //     gracePeriod: BigInt(0)
        // }
    },
    baseTest: {
        // sendLibrary: "0xC1868e054425D378095A003EcbA3823a5D0135C9",
        // receiveLibraryConfig: {
        //     receiveLibrary: "0x12523de19dc41c91F7d2093E0CFbB76b17012C8d",
        //     gracePeriod: BigInt(0)
        // }
    },
    arbitrumTest: {
        // sendLibrary: "0x4f7cd4DA19ABB31b0eC98b9066B9e857B1bf9C0E",
        // receiveLibraryConfig: {
        //     receiveLibrary: "0x75Db67CDab2824970131D5aa9CECfC9F69c69636",
        //     gracePeriod: BigInt(0)
        // }
    }
}

const buildConnections = (): Connection[] => {
    const result = []

    for (const network in stateRootValidator) {
        const config = networkConfig[network] || {}
        const fromContract = stateRootValidator[network]
        for (const network in stateRootStorage) {
            const toContract = stateRootStorage[network]
            result.push({
                from: fromContract,
                to: toContract,
                config
            })
        }
    }
    for (const network in stateRootStorage) {
        const config = networkConfig[network] || {}
        const fromContract = stateRootStorage[network]
        for (const network in stateRootValidator) {
            const toContract = stateRootValidator[network]
            result.push({
                from: fromContract,
                to: toContract,
                config
            })
        }
    }
    //console.log(result)
    return result
}

const config: OAppOmniGraphHardhat = {
    contracts: buildContracts(),
    connections: buildConnections()
}

export default config

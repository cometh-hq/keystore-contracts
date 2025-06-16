import 'dotenv/config'

import 'hardhat-deploy'
import 'hardhat-contract-sizer'
import '@nomiclabs/hardhat-ethers'
import '@layerzerolabs/toolbox-hardhat'
import { HttpNetworkAccountsUserConfig } from 'hardhat/types'
import { EndpointId } from "@layerzerolabs/lz-definitions";

const PRIVATE_KEY = process.env.DEPLOYER_PRIVATE_KEY

const accounts: HttpNetworkAccountsUserConfig | undefined = PRIVATE_KEY ? [PRIVATE_KEY, PRIVATE_KEY] : undefined

if (!accounts) {
    console.warn(
        'Could not find PRIVATE_KEY environment variables. It will not be possible to execute transactions in your example.'
    )
}

const config = {
    solidity: "0.8.20",
    defaultNetwork: "hardhat",
    paths: {
        artifacts: "./artifacts",
        cache: "./cache",
        sources: "./contracts",
        tests: "./test",
    },
    networks: {
        hardhat: {
            allowUnlimitedContractSize: true
        },
        local: {
            url: "http://127.0.0.1:8545",
            allowUnlimitedContractSize: true,
        },
        arbitrum_sepolia: {
            url: "https://arb-sepolia.g.alchemy.com/v2",
            accounts: accounts,
            chainId: 421614,
            eid: EndpointId.ARBSEP_V2_TESTNET,
        },
        base_sepolia: {
            url: "https://base-sepolia.infura.io/v3",
            accounts: accounts,
            chainId: 84532,
            eid: EndpointId.BASESEP_V2_TESTNET,
        },
    },
    namedAccounts: {
        deployer: {
            default: 0,
        },
    },
    etherscan: {
        apiKey: {
            mainnet: process.env.ETHERSCAN_API_KEY,
            arbitrum_sepolia: process.env.ARBISCAN_SEP_API_KEY,
            base_sepolia: process.env.BASESCAN_SEP_API_KEY,
        },
        customChains: [
            {
                network: "arbitrum_sepolia",
                chainId: 421614,
                urls: {
                    apiURL: "https://api-sepolia.arbiscan.io/api",
                    browserURL: "https://sepolia.arbiscan.io/",
                },
            },
            {
                network: "base_sepolia",
                chainId: 84532,
                urls: {
                    apiURL: "https://api-sepolia.basescan.org/api",
                    browserURL: "https://sepolia.basescan.org/",
                },
            }
        ],
    },
    typechain: {
        outDir: "artifacts/typechain",
        target: "ethers-v6",
    }
};

export default config;

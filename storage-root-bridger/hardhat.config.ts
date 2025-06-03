// Get the environment configuration from .env file
//
// To make use of automatic environment setup:
// - Duplicate .env.example file and name it .env
// - Fill in the environment variables
import 'dotenv/config'

import 'hardhat-deploy'
import 'hardhat-contract-sizer'
import '@nomiclabs/hardhat-ethers'
import '@layerzerolabs/toolbox-hardhat'
import { HttpNetworkAccountsUserConfig } from 'hardhat/types'
import { EndpointId } from "@layerzerolabs/lz-definitions";

const INFURA_ID = process.env.INFURA_ID;

// If you prefer to be authenticated using a private key, set a DEPLOYER_PRIVATE_KEY environment variable
const PRIVATE_KEY = process.env.DEPLOYER_PRIVATE_KEY

const accounts: HttpNetworkAccountsUserConfig | undefined = PRIVATE_KEY ? [PRIVATE_KEY, PRIVATE_KEY] : undefined

if (!accounts) {
    console.warn(
        'Could not find PRIVATE_KEY environment variables. It will not be possible to execute transactions in your example.'
    )
}

if (!INFURA_ID) {
    console.warn(
        'Could not find INFURA_ID environment variable. It will not be possible to execute transactions in your example.'
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
            // required to deploy safes
            allowUnlimitedContractSize: true
        },
        local: {
            // This is for the persistent Hardhat node
            url: "http://127.0.0.1:8545",
            // required to deploy safes
            allowUnlimitedContractSize: true,
        },
        // eth: {
        //     url: "https://mainnet.infura.io/v3/" + INFURA_ID,
        //     accounts: accounts,
        //     chainId: 1,
        //     eid: EndpointId.ETHEREUM_MAINNET,
        // },
        arbitrum_sepolia: {
            url: "https://arb-sepolia.g.alchemy.com/v2/",
            accounts: accounts,
            chainId: 421614,
            eid: EndpointId.ARBSEP_V2_TESTNET,
        },
        base_sepolia: {
            url: "https://base-sepolia.core.chainstack.com/",
            accounts: accounts,
            chainId: 84532,
            eid: EndpointId.BASESEP_V2_TESTNET,
        },



    },
    namedAccounts: {
        deployer: {
            default: 0, // wallet address of index[0], of the mnemonic in .env
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

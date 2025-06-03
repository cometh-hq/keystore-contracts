import {ethers} from "hardhat"

export const getEnv = (key: string): string => {
    const value = process.env[key]
    if (!value) {
        throw new Error(`Missing env.${key}`)
    }
    return value
}

export const findEnv = (key: string): string | undefined => {
    return process.env[key]
}

export const getAccount = async (index: number = 0) => {
    const accounts = await ethers.getSigners()
    const account = accounts[index]
    if (!account) {
        throw new Error(`Missing account[${index}]`)
    }
    return account
}

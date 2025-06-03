#### Keys Components

- **LiteKeystore**: Keystore contract containing an ownership mapping
- **Storage Verifier**: On-chain contract that verifies account & storage proofs against the stored stateRoot.
- **Cross-Chain Validator**: ERC7579 validator that uses storage proof and the storage verifier to validate a userop.

#### Prerequisite

- You need to have deployed the BLOCK_STORAGE contract on the chain where the validator will be deployed.

#### **2️⃣ Compile the **contracts\*\*\*\*

- Deploy the **StateRootValidator** on the main chain: **[tags: validator]**

```sh
forge compile
```

#### \*\*2️⃣ Set up the make file\*\*\*\*

- In the make file, add the rpcurl, scan key and privateKey used for deployment

```sh
deploy-base-sepolia:
	forge script script/Deploy.s.sol:Deploy --rpc-url $(BASE_SEPOLIA_RPC) --private-key 0x --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv
```

#### \*\*2️⃣ Deploy the contracts\*\*\*\*

- Deploy the Storage Verifier, LiteKeystore and CrosschainValidator

```sh
make deploy-base-sepolia
```

#### After deployment

- Don't forget to push the latest state of the keystore contract chain to have the latest state accesible on the validator.

-include .env


deploy-sepolia:
	forge script script/Deploy.s.sol:Deploy --rpc-url $(SEPOLIA_RPC) --private-key  --broadcast -vvvv


deploy-base-sepolia:
	forge script script/Deploy.s.sol:Deploy --rpc-url $(BASE_SEPOLIA_RPC) --private-key 0x --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv

deploy-arbitrum-sepolia:
	forge script script/Deploy.s.sol:Deploy --rpc-url $(ARBITRUM_SEPOLIA_RPC) --private-key 0x --broadcast  -vvvv

	
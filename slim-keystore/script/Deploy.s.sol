// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/Test.sol";

import { StorageVerifier } from "../src/lib/StorageVerifier.sol";
import { IStorageVerifier } from "../src/interfaces/IStorageVerifier.sol";
import { CrossChainValidator } from "../src/CrossChainValidator.sol";
import { RegistryDeployer } from "modulekit/deployment/registry/RegistryDeployer.sol";
import { ModuleType } from "modulekit/deployment/registry/types/DataTypes.sol";
import { SlimKeyStore } from "../src/SlimKeyStore.sol";

contract Deploy is Script, RegistryDeployer {
    address public newStorageVerifier = vm.envOr("STORAGE_VERIFIER", address(0));

    // Load plugins contract, if not in env, deploy new contract
    address public crossChainValidator = vm.envOr("CROSSCHAIN_VALIDATOR", address(0));
    address public blockStorage = vm.envOr("BLOCK_STORAGE", address(0));
    address public slimKeyStore = vm.envOr("SLIM_KEYSTORE", address(0));

    bytes32 public implSalt = "COMETH";

    bytes metadata = "";
    bytes resolverContext = "";

    function run() public {
        console.log("******** Deploying *********");
        console.log("Chain: ", block.chainid);

        vm.startBroadcast();

        // Deploy wrapper fcl
        if (newStorageVerifier == address(0)) {
            newStorageVerifier = address(new StorageVerifier{ salt: implSalt }(blockStorage));
            console.log("New Verifier impl: ", newStorageVerifier);
        } else {
            console.log("Exist Verifier impl: ", newStorageVerifier);
        }

        if (slimKeyStore == address(0)) {
            slimKeyStore = address(new SlimKeyStore{ salt: implSalt }());
            console.log("New SlimKeyStore impl: ", slimKeyStore);
        } else {
            console.log("Exist SlimKeyStore impl: ", slimKeyStore);
        }

        // Deploy validator
        if (crossChainValidator == address(0)) {
            bytes memory constructorArgs = abi.encode(IStorageVerifier(newStorageVerifier), slimKeyStore);
            bytes memory fullInitCode = abi.encodePacked(type(CrossChainValidator).creationCode, constructorArgs);

            crossChainValidator = deployModule({
                initCode: fullInitCode,
                salt: bytes32(0),
                metadata: metadata,
                resolverContext: resolverContext
            });

            console.log("New CrosschainValidator: ", crossChainValidator);

            // Mock attest the validator module
            ModuleType[] memory moduleTypes = new ModuleType[](1);
            moduleTypes[0] = ModuleType.wrap(uint256(1));

            mockAttestToModule(
                crossChainValidator,
                bytes("CrossChainValidator"), // Simple attestation data
                moduleTypes
            );

            console.log("Validator mock attested successfully");
        }

        console.log("******** Deploy Done! *********");

        vm.stopBroadcast();
    }
}

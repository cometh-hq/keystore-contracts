// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, stdJson as StdJson, console2 } from "forge-std/Test.sol";
import { CrossChainValidator } from "../src/CrossChainValidator.sol";
import { StorageVerifier } from "../src/lib/StorageVerifier.sol";
import { IStorageVerifier } from "../src/interfaces/IStorageVerifier.sol";
import { RhinestoneModuleKit, ModuleKitHelpers, AccountInstance, UserOpData } from "modulekit/ModuleKit.sol";
import { MODULE_TYPE_VALIDATOR } from "modulekit/accounts/common/interfaces/IERC7579Module.sol";
import { IEntryPoint, PackedUserOperation } from "modulekit/external/ERC4337.sol";
import { UserOperationLib } from "account-abstraction/core/UserOperationLib.sol";
import { MPT } from "../src/lib/MPT.sol";
import { SlimKeyStore } from "../src/SlimKeyStore.sol";
import { console } from "forge-std/console.sol";

contract MockStorageVerifier is IStorageVerifier {
    function _verifyAccount(MPT.Account memory account, bytes[] memory accountProof) external view returns (bool) {
        return true;
    }

    function _verifyStorageSlot(MPT.Account memory account, MPT.StorageSlot memory slot, bytes[] memory storageProof)
        external
        view
        returns (bool)
    {
        return true;
    }
}

contract CrossChainValidatorLZTest is RhinestoneModuleKit, Test {
    using StdJson for *;
    using ModuleKitHelpers for AccountInstance;

    // Contracts
    AccountInstance internal instance;
    CrossChainValidator internal validator;
    MockStorageVerifier internal storageVerifier;
    SlimKeyStore internal slimKeyStore;

    // Test Addresses
    address internal childSafe = 0xce8F48b7EEBa6150B991fcb7497835c283242Ce6;
    address internal SENTINEL_OWNERS = 0x0000000000000000000000000000000000000001;
    uint256 internal chainId = 64;

    // Test Parameters
    uint256 public constant SLIM_KEYSTORE_OWNERS_SLOT = 0;
    uint256 public constant SLIM_KEYSTORE_THRESHOLD_SLOT = 2;
    address internal target;
    uint256 internal value;
    uint256 internal threshold = 1;

    function setUp() public {
        // Initialize testing environment
        init();

        vm.chainId(chainId);

        // Deploy storage verifier with mock block storage
        storageVerifier = new MockStorageVerifier();
        slimKeyStore = new SlimKeyStore();

        // Deploy cross-chain validator
        validator = new CrossChainValidator(storageVerifier, address(slimKeyStore));
        vm.label(address(validator), "CrossChainValidator");

        // Create account instance
        instance = makeAccountInstance("ECDSAAccount");
        vm.deal(address(instance.account), 10 ether);

        // Setup test targets
        target = makeAddr("target");
        value = 1 ether;
    }

    function _createMockStorageProofSignature(
        address _owner,
        address _childAccount,
        bytes memory _signature,
        address accountAddress,
        uint256 threshold
    ) internal view returns (bytes memory) {
        bytes[] memory accountProof = new bytes[](8);
        accountProof[0] =
            hex"f90211a0d34d1225fc00b0a59d1088e7b2403ae43f884e7f9eedaa65cd5d7905f0341b4da0224bc50aa638db26eab82b200432c36d1c514b746113e664099b01599a244cc9a006448b6655a8321a5b4d9bce53b0c7ff5f54ed542c810600c95b41da04c97814a07811bc36bc2cba1685d8b081b58861fb06046a8a069ace18042b6e00e272d332a00c7452bd6d256b3e50e796f31da3135e8151a31cf54ae61fdd8a64231e2eb84aa0e270e3737999638cadcefa80f8ed8fb1e636d8f89979b44450b8ab2c91254a70a0bb5f5f2ebb658966eaf3141610a648f58fc08c4ef6cbc4fd1ad7cc02f88951fba0b2924e270ee57ae18fe0e46466086c99e617bd116aea2a7a0fc0795062cddab7a04a97404d39962a920b613777ce6961b9bef95ce8f985bb2d3acbe3b70f992d66a0492017d414cc4d6dcf4af1c8885d2d30a178c4bb07b011e6a50d040f49790ff2a04dde0ca546237dc218df2d07caffdede4216485afbba43f671d02bc4be3ece5ca0f68191d15c46c6fbb33d3385fa72ded0685beac56167c792f775ec77b71e9e00a02dc69492eeefd073ee5db442f61b7f8fa33b65635180efbec059ab22ef40a54fa029084bbcf26d823a35375b0ca080cb809f7dd4271aa6083825aceb02db8403f6a0b9b2159a9f29ac6a9a4c46ad5caf648516483d7b9a029d7b41aa46ab6aa334d0a0bcd8a805e53aa029ed63459cb2f60bcf51d3b1f6b534f426c838faa084b48d4d80";
        accountProof[1] =
            hex"f90211a0cd4e85ca364d780ff0c25d447cb0adb65e4f2d51b296c4205d50aafa0cf68a63a042288d7ce3c52d06e481467f5d0fe8ec169833db63b86add47d26435b48175d8a05b571f32ff038849c5085f99dc0710ee088d663ef0e5a8f5f6c71ff03e12b1dda0493ca1da61e73327814de290cd00c639915a24cda3f9579d6febde0486890475a09408649dadcd8cb956b44ea1c316b036804680245058239c8629f31e96097e80a086f35fcff145c56c48082bfb4b9833ecb803095395cf0af114c5b65d5bea9dc6a0df2b104dcbf50f94e34aca11056d1834d1f7354f88f99cccf14383391a036d4ea0c6eaf3d49078c86bc46772f2ed562de227be9a96da69f125fc4e080f2af9cfbca0512ea40a191d06130bc8597fb159b59fb79a66618ea806b151902e7466cab49ea0b48c1b739f72c2569cabcca4aa28abc4506d1c117ea80257b206c5849f819e2da0d8f75a5d2f8acab41c2fa5673d6d6a47b36afdc799bf76da7dcac9546f6f11c8a00e12b82ca4c061cb0ac0e0628f518be3375b85a63ecc5d424022330e3910edcea0a560f406feef3409a6f3f7ffb15da14c9e91fad911dc8a496ce281548376abd6a0f88743609446b3e71620daf51e7bdbb93e95f6f75fea0542c4c0ec8b5ca7893ea06cbe800177b8aa420a1aefe630bc8290863e9fc85e61cc15aca5ab54c96c7836a06a61cd84640573638cfa3c2a0f59b306bc96bb14bdab57cad1324b0df21bcc6b80";
        accountProof[2] =
            hex"f90211a05e388d564e4408cea145f569815a3c7784e2558d871798bcae356bbf19dcfb98a00f6c4d2705f710d838c31eac448d305e7f0ed124395daba9ff6ac1fbc785afc0a02cf1f0f6a71cb3157ff55dca0590f594b41ae55bfa2724923d1ed8eece56b766a0a72cc932c0a450a73956723ef2548c8387d0632afda05214d6988a076a94e599a027baef01b5d4c85aa3f7c72ee47a7e5c32ade7a98a6ee138dd60266f5f138601a022904f3cf00903b93cfde1903f4ba2396c1ca254d87c5f6ef43ac60ba3db7261a00791a039486ab9ed4c4fb2385f977f97a09e761eee5115e882af74513afd5698a04b88183e20806f1a6e231f9bca6edc1b6267fbad4c5be36339d44af7b1f22af1a0350c82a72e544cb2f95e4c9f44f4a477931c31ff2e026ca3735504a058c5e827a01aad98dcc930a14152dbafa052d14f096b350675b601473721da9b0bb74fc80fa000ba7d426a49a70506ea0c0013f85e09291802295b452b306d252f41cf647dd3a022a4bfe802e84eee957492d538091dcac02de98d556fff6cb9aa26af7a1ee74ca07ac766ff2daf57c9bf6ee19c4200bbc22bee215c98b98ca8cef6616810eb980ba0689570a60ba08f24290ad7792d5b98fe694c8af884673222b27d9d4eeaf5fb23a003ca02b8fc816178a016b3a8ba698319313a9101814c164fcfacfcdceea6f868a00a29dea6c938a6d8a3af36b890926a9f4c8f89c341a583858a002435154bfd5c80";
        accountProof[3] =
            hex"f90211a0bb225165a441334708a99e7cc0197583b5a8b0fba54db0933e1ea118de89b0d6a033d97d03a8c8aa79701054b6145e52a7e2430856fe08a1514975a6eb5f6b35c7a0d00c8be78e65ffd75904cd319ab6d53062a413354c33d234de4613b78bcd8734a040779ff2b1a4df70dc844baf46fc33a9b34c164c067439714103db78fb079765a065ccdbd0a205315a6ee1691f95f4329d7a0fe4cf6ddea836c611ca4905a64d1fa04f31442219f2bad489cacabec2820b9895de58dc497639c40ed79b617b0ec1d0a031c2869beec2ab4f049d087d54bd711f9b85cac5317515e3312e8bd4770d4dd1a072e5b1287369dd4cb47419c9942038a5d6ad53804a05edcf19146f0797c21c5aa0c6ba4bfd07d3bfe7aaa5308ac43f24e0e6b85997c99b077a9cc0a8ca8094e613a05f5a17d9234b03cc58456f4c4d5fa08ecd9a5a133e4cc6862692bd50beedad1fa0458ad0f989087927fad9640b26e49688970ca824a6d52bf42679f2dfa19cc363a0b910ad19f08554e6389d4d982e6ca322df17345b9ff0344794879b45b10fb08ba06a40fd08ea2c944dd20554d21677e617667449fe85c94a8e51216cf6fc0552fba0aac34da1fa19d7c997fe8e6854d10beca708a7dd673cf33e931882581b496391a00cea8277e3033316531b9fe7112bde76e1c74c9283dc7ec146c032109bc61c24a0c720f5ff9bc77b4cd3b37c1f1b283c74e4b351ba884c7f78460124897e6677d680";
        accountProof[4] =
            hex"f90211a00798d558e84b9226f2c407cd040128ce1a8f637094db56c60866f771d07b354ca06af456b9296273fbe8cf650d4b94f5c982e8f647a507c5e60d1ac601f7419c41a0d63576c2f7bcda8424e7ed28aa73809bcac016062344e4d096a4f23005b1d926a063bc469a19b24164af5162db709c67181f7e86745cb4bca5ab584387b4543810a0a0597ab2e42461f607a4c2b07df9aaad0dbd3116150d8c834c38d7ab062d040ca08ad2c21a5cd26c1f3ff7618b25b5fba71f060fd433835ab3c92e65bf6c9eb424a0836d0f44ca331b9db95fdcb89ea7bac97b60b6d31562795a624d5df69ad8a495a0428f9450e68632cd6a97c65520e46e250ffc306053b2f5f74f6af612d15b4f6ba0a6c5f364d49043f2e064e2418f61e9979ca96bd7febfcec77c648189eb640af1a00009de12917e1021d02c8a0bfb3f1ae43e42fdfdb062f31d3d0fe880f4416444a02bda0ad6a42e295779c01777596c1b128bff6c1a0c78c00643a1cc5ebd329d05a0069d124f1b4ee2fef05c1c7a7774525756b9ec0b9a026abd95c94386ca187dbca0a2dab9031e93a2ac7815cf661b0edc07b6c73c873858bb531a4c6ab27abee926a040f22ae4a254b8666797eaf72bf7b048710923c5612d425fe9c8db31488db8f9a0d44f6035c6b5d2d46b23b83ae71136e22bea3d3c13a66f7e152d8196622c11d1a007e2682afca471c8b4af94a27e2d6236b786f25a434d0b411ed632cef6dc0f9680";
        accountProof[5] =
            hex"f851a05e04a5eb39f85d7e775a580fa018ef5d6862fd189c389102678adfd1b992d700808080808080808080a0aea9a886c73dced22222d161018095078761d6e1f9fc1f0535702558363b7d5c808080808080";
        accountProof[6] =
            hex"f8669d3e12dea00e263a9bc2c79a2cfffbd45fa2e05e0c9c2781c7db15c8447fb846f8440180a0ec0c59b72d4f5210067173cb65fa4a13f19887b49d536e3f088023a6a8c2005aa0d7d408ebcd99b2b70be43e20253d6d92a8ea8fab29bd3be7f55b10032331fb4c";

        bytes[] memory storageProof = new bytes[](3);
        storageProof[0] =
            hex"f8f18080a04da2b7f0f61dbb52b21c6d761f9cb3f935404eb40f8cc84d8111c1a67edda915808080a0924be8837c66889806198b6222fb765776245ade68000c1f2aa31425aad4731ca02b20a93a97f5490aa87bfd499f2152cbd12a9f3fd3eaf6c5d889277a29b11795a0cea8a695807aa94209d5c15afa57dc9ab0bbe9de19af9b1dffff8d7dc769dcda80a00186e2b4b79a5301d8720c43a25c9728e29d00f9d8a91f20eb4d52e7e87cf29d80a040f61ef1c42bdf5b6916e65d3fedf546e3dd97a9cbcd25f575709cf1672ae73880a03ddf6a68d78d037051a7de7715a1f986b3d938abce8d4822cb9cd88399eb62218080";
        storageProof[1] =
            hex"f8518080808080808080a0591cf16362c2f53948b79ebd86be0543c0972aa05b532b53e172b10ce2fee10c80a0c9dd20abab9993491b5ea84de4d65f3fcb21c3ce0d3c5563893df74a8343cc20808080808080";
        storageProof[2] =
            hex"f7a020883b0dc80767b96cdd03b87dbf479a08eb7ffb2ec1a97be551bc0631e3e0d29594df2fcae11b124b963ce53566030c5dd7a199f751";

        CrossChainValidator.ThresholdData memory thresholdData = CrossChainValidator.ThresholdData({
            threshold: threshold,
            thresholdSlotValue: uint256(
                keccak256(
                    abi.encode(address(slimKeyStore), keccak256(abi.encode(_childAccount, SLIM_KEYSTORE_THRESHOLD_SLOT)))
                )
            ),
            thresholdStorageProof: storageProof
        });

        CrossChainValidator.OwnerData memory ownerData = CrossChainValidator.OwnerData({
            owner: _owner,
            prevOwner: address(SENTINEL_OWNERS),
            ownerSlotValue: uint256(
                keccak256(
                    abi.encode(address(slimKeyStore), keccak256(abi.encode(_childAccount, SLIM_KEYSTORE_OWNERS_SLOT)))
                )
            ),
            ownerStorageProof: storageProof,
            signature: _signature
        });

        CrossChainValidator.OwnerData[] memory ownerDataArray = new CrossChainValidator.OwnerData[](1);
        ownerDataArray[0] = ownerData;

        CrossChainValidator.CrosschainValidationData memory crosschainValidationData = CrossChainValidator
            .CrosschainValidationData({
            chainId: chainId,
            account: MPT.Account({
                accountAddress: address(accountAddress),
                nonce: 1,
                balance: 0,
                storageRoot: 0xec0c59b72d4f5210067173cb65fa4a13f19887b49d536e3f088023a6a8c2005a,
                codeHash: 0xd7d408ebcd99b2b70be43e20253d6d92a8ea8fab29bd3be7f55b10032331fb4c
            }),
            accountProof: accountProof,
            ownerData: ownerDataArray,
            thresholdData: thresholdData
        });

        bytes memory correctSignatureLayout = abi.encode(
            crosschainValidationData.chainId,
            crosschainValidationData.account,
            crosschainValidationData.accountProof,
            crosschainValidationData.ownerData,
            crosschainValidationData.thresholdData
        );

        return correctSignatureLayout;
    }

    function _createMockUserOperation() internal pure returns (PackedUserOperation memory) {
        return PackedUserOperation({
            sender: address(0),
            nonce: 0,
            initCode: hex"",
            callData: hex"",
            accountGasLimits: bytes32(0),
            preVerificationGas: 0,
            gasFees: bytes32(0),
            signature: hex"",
            // Add the missing argument - this is likely a new field in the recent version
            paymasterAndData: hex"" // Add this line
         });
    }

    function _createMockECDSAsignature() internal view returns (bytes memory) {
        // Create a mock ECDSA signature (65 bytes: r, s, v)
        // This is a valid ECDSA signature format but with dummy values
        return hex"1234567890123456789012345678901234567890123456789012345678901234" // r
        hex"5678901234567890123456789012345678901234567890123456789012345678" // s
        hex"1c"; // v (28 = 0x1c);
    }

    function test_InvalidCrossChainValidationParentAddress() public {
        // Prepare mock user operation
        PackedUserOperation memory userOp = _createMockUserOperation();
        userOp.sender = childSafe;

        bytes memory mockECDSAsignature = _createMockECDSAsignature();

        // Create mock signature with wrong parent
        bytes memory mockSignature = _createMockStorageProofSignature(
            makeAddr("owner"), childSafe, mockECDSAsignature, makeAddr("wrong_address"), threshold
        );
        userOp.signature = mockSignature;

        // Expect a revert due to parent mismatch
        vm.expectRevert(CrossChainValidator.InvalidTargetAccount.selector);
        validator.validateUserOp(userOp, keccak256("user_op_hash"));
    }

    function test_InvalidThresholdData() public {
        // Prepare mock user operation
        PackedUserOperation memory userOp = _createMockUserOperation();
        userOp.sender = childSafe;

        uint256 threshold = 2;

        bytes memory mockECDSAsignature = _createMockECDSAsignature();

        // Create mock storage proof signature
        bytes memory mockSignature = _createMockStorageProofSignature(
            makeAddr("owner"), childSafe, mockECDSAsignature, address(slimKeyStore), threshold
        );
        userOp.signature = mockSignature;

        // Validate user operation
        vm.prank(address(instance.aux.entrypoint));
        uint256 validationResult = validator.validateUserOp(0, userOp, keccak256("user_op_hash"));

        assertEq(validationResult, 1, "User operation should be invalid");
    }

    function test_InvalidEOAsigLength() public {
        // Prepare mock user operation
        PackedUserOperation memory userOp = _createMockUserOperation();
        userOp.sender = childSafe;

        bytes memory mockSignature = _createMockStorageProofSignature(
            makeAddr("owner"),
            childSafe,
            "0x0000000000000000000000000000000000000000000000000000",
            address(slimKeyStore),
            threshold
        );
        userOp.signature = mockSignature;

        // Validate user operation
        vm.prank(address(instance.aux.entrypoint));
        uint256 validationResult = validator.validateUserOp(0, userOp, keccak256("user_op_hash"));

        assertEq(validationResult, 1, "User operation should be invalid");
    }

    function test_InvalidEOAsig() public {
        PackedUserOperation memory userOp = _createMockUserOperation();
        userOp.sender = childSafe;

        bytes memory mockECDSAsignature = _createMockECDSAsignature();

        bytes memory mockSignature = _createMockStorageProofSignature(
            makeAddr("owner"), childSafe, mockECDSAsignature, address(slimKeyStore), threshold
        );
        userOp.signature = mockSignature;

        // Validate user operation
        vm.prank(address(instance.aux.entrypoint));
        uint256 validationResult = validator.validateUserOp(0, userOp, keccak256("user_op_hash"));

        assertEq(validationResult, 1, "User operation should be invalid");
    }
}

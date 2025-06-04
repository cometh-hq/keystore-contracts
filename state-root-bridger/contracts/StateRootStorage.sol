// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {StateRootProof} from "./lib/ValidorStructs.sol";
import {OAppCore} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppCore.sol";
import {OAppReceiver} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppReceiver.sol";
import {Origin} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

contract StateRootStorage is OAppReceiver {
    StateRootProof public stateRootProof;

    constructor(address _owner, address _endpoint) OAppCore(_endpoint, _owner) Ownable(_owner) {
    }

    function stateRoot() public view returns (bytes32) {
        return stateRootProof.stateRoot;
    }

    function blockNumber() public view returns (uint256) {
        return stateRootProof.blockNumber;
    }

    /**
 * @dev Internal function override to handle incoming messages from another chain.
     * @dev _origin A struct containing information about the message sender.
     * @dev _guid A unique global packet identifier for the message.
     * @param _payload The encoded message payload being received.
     *
     * @dev The following params are unused in the current implementation of the OApp.
     * @dev _executor The address of the Executor responsible for processing the message.
     * @dev _extraData Arbitrary data appended by the Executor to the message.
     *
     * Decodes the received payload and processes it as per the business logic defined in the function.
     */
    function _lzReceive(
        Origin calldata /*_origin*/,
        bytes32 /*_guid*/,
        bytes calldata _payload,
        address /*_executor*/,
        bytes calldata /*_extraData*/
    ) internal override {
        (bytes32 stateRoot, uint256 blockNumber,bytes32 blockHash) = abi.decode(_payload, (bytes32, uint256, bytes32));
        stateRootProof = StateRootProof(stateRoot, blockNumber, blockHash);
    }
}

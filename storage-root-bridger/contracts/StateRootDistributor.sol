// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MessagingFee} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {OAppCore} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppCore.sol";
import {OAppSender} from "@layerzerolabs/oapp-evm/contracts/oapp/OAppSender.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {StateRootProof} from "./lib/ValidorStructs.sol";

abstract contract StateRootDistributor is OAppSender {
    uint32[] public validatorDestIds;


    constructor(address _owner, address _endpoint, uint32[] memory _validatorDestIds) OAppCore(_endpoint, _owner) Ownable(_owner) {
        validatorDestIds = _validatorDestIds;
    }

    function setValidatorDestIds(uint32[] memory _validatorDestIds) public onlyOwner {
        validatorDestIds = _validatorDestIds;
    }

    /// @notice Send allowance hash to stake manager on chains defined in assets
    function propagateNewBlock(StateRootProof memory _proof, bytes memory _options) internal {
        bytes memory _payload = abi.encode(_proof.stateRoot, _proof.blockNumber, _proof.blockHash);

        for (uint256 i = 0;
            i < validatorDestIds.length;
            i++) {
            uint32 _dstEid = validatorDestIds[i];
            MessagingFee memory _fee = _quote(_dstEid, _payload, _options, false);
            _lzSend(_dstEid, _payload, _options, _fee, payable(msg.sender));
        }
    }

    function _payNative(uint256 _nativeFee) internal override returns (uint256 nativeFee) {
        if (msg.value < _nativeFee) revert NotEnoughNative(msg.value);
        return _nativeFee;
    }

    /**
     * @notice Quotes the gas needed to pay for the full omnichain transaction in native gas or ZRO token.
     * @param _dstEid Destination chain's endpoint ID.
     * @param _message The message.
     * @param _payInLzToken Whether to return fee in ZRO token.
     * @return fee A `MessagingFee` struct containing the calculated gas fee in either the native token or ZRO token.
     */
    function quote(
        uint32 _dstEid,
        string memory _message,
        bytes memory _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory payload = abi.encode(_message);
        fee = _quote(_dstEid, payload, _options, _payInLzToken);
    }

    /**
     * @notice Quotes the gas needed to pay for the full omnichain transaction in native gas.
     * @param _proof The state root proof.
     * @param _options Additional options for the message.
     * @return total The total fee for the message.
     */
    function fullQuote(StateRootProof memory _proof, bytes memory _options) public view returns (uint total) {
        bytes memory _payload = abi.encode(_proof.stateRoot, _proof.blockNumber, _proof.blockHash);

        for (uint256 i = 0;
            i < validatorDestIds.length;
            i++) {
            uint32 _dstEid = validatorDestIds[i];
            MessagingFee memory _fee = _quote(_dstEid, _payload, _options, false);
            total += _fee.nativeFee;
        }
        return total;
    }
}

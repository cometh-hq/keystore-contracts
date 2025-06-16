// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import { IKeystore } from "./interfaces/IKeystore.sol";
import { ErrorMessage } from "./lib/ErrorMessage.sol";

contract SlimKeyStore is IKeystore, ErrorMessage {
    address internal constant SENTINEL_OWNERS = address(0x1);

    mapping(address => mapping(address => address)) internal owners;
    mapping(address => uint256) internal ownerCounts;
    mapping(address => uint256) internal thresholds;

    error InvalidOwner();
    error DuplicateOwner();
    error OwnerMismatch();
    error LastOwnerRemovalNotAllowed();
    error ThresholdExceedsOwnerCount();
    error ThresholdMustBePositive();

    event ChangedThreshold(uint256 threshold);

    modifier onlyAccount(address account) {
        require(msg.sender == account, "Not authorized: caller is not account");
        _;
    }

    function addOwnerWithThreshold(address account, address owner, uint256 _threshold)
        public
        override
        onlyAccount(account)
    {
        if (owner == address(0)) revert InvalidOwner();
        if (owner == SENTINEL_OWNERS) revert InvalidOwner();
        if (owner == address(this)) revert InvalidOwner();
        if (owners[account][owner] != address(0)) revert DuplicateOwner();

        if (ownerCounts[account] == 0) {
            owners[account][SENTINEL_OWNERS] = owner;
            owners[account][owner] = SENTINEL_OWNERS;
        } else {
            owners[account][owner] = owners[account][SENTINEL_OWNERS];
            owners[account][SENTINEL_OWNERS] = owner;
        }

        unchecked {
            ownerCounts[account]++;
        }

        emit AddedOwner(owner);

        if (_threshold != thresholds[account]) changeThreshold(account, _threshold);
    }

    function removeOwnerWithThreshold(address account, address prevOwner, address owner, uint256 _threshold)
        public
        override
        onlyAccount(account)
    {
        if (ownerCounts[account] - 1 < _threshold) revert ThresholdExceedsOwnerCount();
        if (ownerCounts[account] <= 1) revert LastOwnerRemovalNotAllowed();
        if (owner == address(0) || owner == SENTINEL_OWNERS || owners[account][prevOwner] != owner) {
            revert OwnerMismatch();
        }

        owners[account][prevOwner] = owners[account][owner];
        owners[account][owner] = address(0);
        unchecked {
            ownerCounts[account]--;
        }
        emit RemovedOwner(owner);

        if (_threshold != thresholds[account]) changeThreshold(account, _threshold);
    }

    function swapOwner(address account, address prevOwner, address oldOwner, address newOwner)
        public
        onlyAccount(account)
    {
        if (newOwner == address(0) || newOwner == SENTINEL_OWNERS || newOwner == address(this)) revert InvalidOwner();

        if (owners[account][newOwner] != address(0)) revert DuplicateOwner();

        mapping(address => address) storage linkedList = owners[account];

        if (oldOwner == address(0) || oldOwner == SENTINEL_OWNERS || linkedList[prevOwner] != oldOwner) {
            revert OwnerMismatch();
        }

        linkedList[newOwner] = linkedList[oldOwner];
        linkedList[prevOwner] = newOwner;
        linkedList[oldOwner] = address(0);

        emit RemovedOwner(oldOwner);
        emit AddedOwner(newOwner);
    }

    function isOwner(address account, address owner) public view override returns (bool) {
        return owner != SENTINEL_OWNERS && owners[account][owner] != address(0);
    }

    function getOwners(address account) public view override returns (address[] memory) {
        address[] memory result = new address[](ownerCounts[account]);
        address current = owners[account][SENTINEL_OWNERS];
        uint256 index = 0;

        while (current != SENTINEL_OWNERS) {
            result[index] = current;
            current = owners[account][current];
            index++;
        }

        return result;
    }

    function changeThreshold(address account, uint256 _threshold) public onlyAccount(account) {
        if (_threshold == 0) revert ThresholdMustBePositive();
        if (_threshold > ownerCounts[account]) revert ThresholdExceedsOwnerCount();
        thresholds[account] = _threshold;
        emit ChangedThreshold(_threshold);
    }

    function getThreshold(address account) public view returns (uint256) {
        return thresholds[account];
    }
}

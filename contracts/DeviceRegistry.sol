// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DeviceIncentives.sol";

contract DeviceRegistry is DeviceIncentives {
    constructor(address _tokenAddress, bool _stakingRequired, uint256 _minStakeAmount) 
        DeviceIncentives(_tokenAddress, _stakingRequired, _minStakeAmount) {}

    function registerDevice(string memory _deviceId, address _owner, uint256 _stakeAmount) public {
        require(!deviceExists[_deviceId], "Device ID already exists");
        
        // Check staking requirements
        if (stakingRequired) {
            require(_stakeAmount >= minStakeAmount, "Insufficient staking amount");
            if (_stakeAmount > 0) {
                require(token.transferFrom(msg.sender, address(this), _stakeAmount), "Staking transfer failed");
                stakerBalances[_owner] += _stakeAmount;
                devices[_deviceId].stakedAmount = _stakeAmount;
                emit Staked(_deviceId, _owner, _stakeAmount);
            }
        } else {
            // Staking is optional
            if (_stakeAmount > 0) {
                require(token.transferFrom(msg.sender, address(this), _stakeAmount), "Staking transfer failed");
                stakerBalances[_owner] += _stakeAmount;
                devices[_deviceId].stakedAmount = _stakeAmount;
                emit Staked(_deviceId, _owner, _stakeAmount);
            }
        }
        
        devices[_deviceId].owner = _owner;
        devices[_deviceId].lastPing = block.timestamp;
        devices[_deviceId].isActive = true;
        deviceExists[_deviceId] = true;
        deviceList.push(_deviceId);
        deviceCount++;
        emit DeviceRegistered(_deviceId, _owner);
    }

    function getDeviceList() public view returns (string[] memory) {
        return deviceList;
    }

    function getDeviceAtIndex(uint256 index) public view returns (string memory) {
        require(index < deviceCount, "Index out of bounds");
        return deviceList[index];
    }
}
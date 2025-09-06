// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DeviceRegistryBase.sol";

contract DeviceStaking is DeviceRegistryBase {
    event Staked(string deviceId, address owner, uint256 amount);
    event Unstaked(string deviceId, address owner, uint256 amount);

    constructor(address _tokenAddress, bool _stakingRequired, uint256 _minStakeAmount) 
        DeviceRegistryBase(_tokenAddress, _stakingRequired, _minStakeAmount) {}

    function stakeTokens(string memory _deviceId, uint256 _amount) public {
        require(deviceExists[_deviceId], "Device does not exist");
        require(_amount >= minStakeAmount, "Insufficient staking amount");
        require(token.transferFrom(msg.sender, address(this), _amount), "Staking transfer failed");
        
        stakerBalances[msg.sender] += _amount;
        devices[_deviceId].stakedAmount += _amount;
        emit Staked(_deviceId, msg.sender, _amount);
    }

    function unstakeTokens(string memory _deviceId) public {
        require(deviceExists[_deviceId], "Device does not exist");
        require(devices[_deviceId].owner == msg.sender, "Not owner of device");
        
        uint256 stakedAmount = devices[_deviceId].stakedAmount;
        require(stakedAmount > 0, "No staked tokens");
        
        devices[_deviceId].stakedAmount = 0;
        stakerBalances[msg.sender] -= stakedAmount;
        require(token.transfer(msg.sender, stakedAmount), "Unstaking transfer failed");
        
        emit Unstaked(_deviceId, msg.sender, stakedAmount);
    }

    function checkStakingRequirement(string memory _deviceId) internal view returns (bool) {
        if (stakingRequired) {
            return devices[_deviceId].stakedAmount >= minStakeAmount;
        }
        return true;
    }
}
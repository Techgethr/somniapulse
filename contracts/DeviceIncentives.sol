// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DeviceMetrics.sol";

contract DeviceIncentives is DeviceMetrics {
    event IncentivesDistributed(string deviceId, uint256 amount);

    constructor(address _tokenAddress, bool _stakingRequired, uint256 _minStakeAmount) 
        DeviceMetrics(_tokenAddress, _stakingRequired, _minStakeAmount) {}

    function distributeIncentives(string memory _deviceId, string memory _metricName, uint256 _value) internal {
        uint256 baseIncentive = calculateBaseIncentive(_metricName, _value);
        uint256 finalIncentive = baseIncentive;
        
        // If staking is enabled for this device, calculate staking bonus
        if (devices[_deviceId].stakedAmount > 0) {
            uint256 stakingBonus = (baseIncentive * devices[_deviceId].stakedAmount) / minStakeAmount;
            finalIncentive += stakingBonus;
        }
        
        if (finalIncentive > 0) {
            devices[_deviceId].incentives += finalIncentive;
            token.transfer(devices[_deviceId].owner, finalIncentive);
            emit IncentivesDistributed(_deviceId, finalIncentive);
        }
    }

    // Simple incentive calculation - can be made more complex
    function calculateBaseIncentive(string memory _metricName, uint256 _value) internal pure returns (uint256) {
        if (keccak256(abi.encodePacked(_metricName)) == keccak256(abi.encodePacked("uptime"))) {
            // For uptime, incentive is proportional to value (max 100 tokens for 100% uptime)
            return (_value * 100) / 100;
        } else if (keccak256(abi.encodePacked(_metricName)) == keccak256(abi.encodePacked("temperature"))) {
            // For temperature, a fixed incentive for reporting
            return 10;
        }
        // Default incentive for other metrics
        return 5;
    }

    function getIncentives(string memory _deviceId) public view returns (uint256) {
        return devices[_deviceId].incentives;
    }

    function getStakedAmount(string memory _deviceId) public view returns (uint256) {
        return devices[_deviceId].stakedAmount;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DeviceMetrics.sol";
import "./IncentiveConfig.sol";

contract DeviceIncentives is DeviceMetrics {
    string public network;
    
    event IncentivesDistributed(string deviceId, uint256 amount);

    constructor(
        address _tokenAddress, 
        bool _stakingRequired, 
        uint256 _minStakeAmount,
        address _incentiveConfigAddress,
        string memory _network
    ) DeviceMetrics(_tokenAddress, _stakingRequired, _minStakeAmount, _incentiveConfigAddress) {
        network = _network;
        
        // Verify that the network is supported
        require(incentiveConfig.isNetworkSupported(_network), "Network not supported");
    }

    // Calculate weighted incentive based on metric configuration
    function calculateWeightedIncentive(
        string memory _metricName, 
        uint256 _value
    ) internal view returns (uint256) {
        IncentiveConfig.MetricConfig memory config = incentiveConfig.getMetricConfig(_metricName);
        
        uint256 baseIncentive;
        if (config.proportional) {
            // Proportional calculation with maximum limit
            baseIncentive = (_value * config.baseReward) / 100;
            if (baseIncentive > config.maxReward) {
                baseIncentive = config.maxReward;
            }
        } else {
            // Fixed reward
            baseIncentive = config.baseReward;
        }
        
        // Apply weighting
        return (baseIncentive * config.weight) / 100;
    }
    
    // Calculate reputation bonus based on device's validation history
    function calculateReputationBonus(string memory _deviceId) internal view returns (uint256) {
        // Based on positive validation history
        uint256 validReports = devices[_deviceId].validReportCount;
        uint256 totalReports = devices[_deviceId].totalReportCount;
        
        if (totalReports == 0) return 0;
        
        uint256 reputation = (validReports * 100) / totalReports;
        uint256 baseIncentive = 10; // Base reputation bonus
        return (baseIncentive * reputation) / 100; // Up to 100% bonus
    }
    
    // Calculate consistency bonus based on reporting frequency
    function calculateConsistencyBonus(string memory _deviceId, string memory _metricName) internal view returns (uint256) {
        // For simplicity, we'll use a fixed consistency bonus
        // In a more complex implementation, this could be based on actual reporting patterns
        return 5; // Fixed consistency bonus
    }

    function distributeIncentives(string memory _deviceId, string memory _metricName, uint256 _value) internal override {
        // Calculate incentive using the new system
        uint256 baseIncentive = calculateWeightedIncentive(_metricName, _value);
        uint256 reputationBonus = calculateReputationBonus(_deviceId);
        uint256 consistencyBonus = calculateConsistencyBonus(_deviceId, _metricName);
        
        uint256 finalIncentive = baseIncentive + reputationBonus + consistencyBonus;
        
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

    function getIncentives(string memory _deviceId) public view returns (uint256) {
        return devices[_deviceId].incentives;
    }

    function getStakedAmount(string memory _deviceId) public view returns (uint256) {
        return devices[_deviceId].stakedAmount;
    }
}
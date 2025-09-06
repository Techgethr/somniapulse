// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract IncentiveConfig is Ownable {
    struct MetricConfig {
        uint256 baseReward;
        uint256 maxReward;
        bool proportional;
        uint256 frequencyLimit; // segundos entre reportes
        uint256 weight; // factor de ponderación (porcentaje)
    }
    
    mapping(string => MetricConfig) public metricConfigs;
    mapping(string => bool) public networkSupported;
    
    event MetricConfigUpdated(string metricName, uint256 baseReward, uint256 maxReward, bool proportional, uint256 frequencyLimit, uint256 weight);
    event NetworkSupported(string network);
    
    constructor(string[] memory supportedNetworks) {
        for (uint i = 0; i < supportedNetworks.length; i++) {
            networkSupported[supportedNetworks[i]] = true;
            emit NetworkSupported(supportedNetworks[i]);
        }
    }
    
    function setMetricConfig(
        string memory _metricName,
        uint256 _baseReward,
        uint256 _maxReward,
        bool _proportional,
        uint256 _frequencyLimit,
        uint256 _weight
    ) public onlyOwner {
        metricConfigs[_metricName] = MetricConfig({
            baseReward: _baseReward,
            maxReward: _maxReward,
            proportional: _proportional,
            frequencyLimit: _frequencyLimit,
            weight: _weight
        });
        
        emit MetricConfigUpdated(_metricName, _baseReward, _maxReward, _proportional, _frequencyLimit, _weight);
    }
    
    function getMetricConfig(string memory _metricName) public view returns (MetricConfig memory) {
        return metricConfigs[_metricName];
    }
    
    function isNetworkSupported(string memory _network) public view returns (bool) {
        return networkSupported[_network];
    }
}
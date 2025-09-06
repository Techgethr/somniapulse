// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DeviceStaking.sol";

contract DeviceMetrics is DeviceStaking {
    event MetricsReported(string deviceId, string metricName, uint256 value);
    event DeviceVerified(string deviceId);

    constructor(address _tokenAddress, bool _stakingRequired, uint256 _minStakeAmount) 
        DeviceStaking(_tokenAddress, _stakingRequired, _minStakeAmount) {}

    function reportMetric(
        string memory _deviceId,
        string memory _metricName,
        uint256 _value,
        bytes memory signature
    ) public {
        require(deviceExists[_deviceId], "Device does not exist");
        
        // Verify staking requirements
        require(checkStakingRequirement(_deviceId), "Device must stake tokens to report metrics");
        
        // Recreate the message that was signed
        bytes32 message = keccak256(abi.encodePacked(_deviceId, _metricName, _value, block.chainid));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
        
        // Recover the signer address
        address signer = recoverSigner(ethSignedMessageHash, signature);
        
        // Verify the signer is the device owner
        require(signer == devices[_deviceId].owner, "Invalid signature");
        
        devices[_deviceId].metrics[_metricName] = _value;
        devices[_deviceId].lastPing = block.timestamp;
        emit MetricsReported(_deviceId, _metricName, _value);
    }

    function verifyDevice(string memory _deviceId) public {
        require(deviceExists[_deviceId], "Device does not exist");
        devices[_deviceId].verified = true;
        emit DeviceVerified(_deviceId);
    }

    function isVerified(string memory _deviceId) public view returns (bool) {
        return devices[_deviceId].verified;
    }

    function getMetric(string memory _deviceId, string memory _metricName) public view returns (uint256) {
        return devices[_deviceId].metrics[_metricName];
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeviceRegistry {
    struct Device {
        address owner;
        uint256 lastPing;
        bool verified;
        mapping(string => uint256) metrics;
        uint256 incentives;
    }

    mapping(string => Device) public devices;
    mapping(string => bool) public deviceExists;
    string[] public deviceList;
    uint256 public deviceCount;
    IERC20 public token;

    event DeviceRegistered(string deviceId, address owner);
    event MetricsReported(string deviceId, string metricName, uint256 value);
    event DeviceVerified(string deviceId);
    event IncentivesDistributed(string deviceId, uint256 amount);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function registerDevice(string memory _deviceId, address _owner) public {
        require(!deviceExists[_deviceId], "Device ID already exists");
        devices[_deviceId].owner = _owner;
        devices[_deviceId].lastPing = block.timestamp;
        deviceExists[_deviceId] = true;
        deviceList.push(_deviceId);
        deviceCount++;
        emit DeviceRegistered(_deviceId, _owner);
    }

    function reportMetric(
        string memory _deviceId,
        string memory _metricName,
        uint256 _value,
        bytes memory signature
    ) public {
        require(deviceExists[_deviceId], "Device does not exist");
        
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
        
        // Distribute incentives based on metric value
        distributeIncentives(_deviceId, _metricName, _value);
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

    function getDeviceList() public view returns (string[] memory) {
        return deviceList;
    }

    function getDeviceAtIndex(uint256 index) public view returns (string memory) {
        require(index < deviceCount, "Index out of bounds");
        return deviceList[index];
    }

    function getIncentives(string memory _deviceId) public view returns (uint256) {
        return devices[_deviceId].incentives;
    }

    // Helper function to distribute incentives
    function distributeIncentives(string memory _deviceId, string memory _metricName, uint256 _value) internal {
        uint256 incentiveAmount = calculateIncentive(_metricName, _value);
        if (incentiveAmount > 0) {
            devices[_deviceId].incentives += incentiveAmount;
            token.transfer(devices[_deviceId].owner, incentiveAmount);
            emit IncentivesDistributed(_deviceId, incentiveAmount);
        }
    }

    // Simple incentive calculation - can be made more complex
    function calculateIncentive(string memory _metricName, uint256 _value) internal pure returns (uint256) {
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

    // Helper function to recover signer from signature
    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    // Helper function to split signature into r, s, v
    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        // Adjust v if necessary
        if (v < 27) {
            v += 27;
        }
    }
}
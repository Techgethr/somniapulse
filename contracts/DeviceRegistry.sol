// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DeviceRegistry {
    struct Device {
        address owner;
        uint256 lastPing;
        bool verified;
        mapping(string => uint256) metrics;
    }

    mapping(string => Device) public devices;
    mapping(string => bool) public deviceExists;

    event DeviceRegistered(string deviceId, address owner);
    event MetricsReported(string deviceId, string metricName, uint256 value);
    event DeviceVerified(string deviceId);

    function registerDevice(string memory _deviceId) public {
        require(!deviceExists[_deviceId], "Device ID already exists");
        devices[_deviceId].owner = msg.sender;
        devices[_deviceId].lastPing = block.timestamp;
        deviceExists[_deviceId] = true;
        emit DeviceRegistered(_deviceId, msg.sender);
    }

    function reportMetric(string memory _deviceId, string memory _metricName, uint256 _value) public {
        require(deviceExists[_deviceId], "Device does not exist");
        Device storage device = devices[_deviceId];
        require(device.owner == msg.sender, "Not owner of device");

        device.metrics[_metricName] = _value;
        device.lastPing = block.timestamp;
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
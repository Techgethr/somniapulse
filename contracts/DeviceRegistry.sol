// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DeviceRegistry {
    struct Device {
        address owner;
        string location;
        uint256 lastPing;
        bool verified;
        uint256 uptime; // en porcentaje
    }

    mapping(uint256 => Device) public devices;
    uint256 public deviceCount;

    event DeviceRegistered(uint256 deviceId, address owner);
    event MetricsReported(uint256 deviceId, uint256 uptime);
    event DeviceVerified(uint256 deviceId);

    function registerDevice(string memory _location) public {
        deviceCount++;
        devices[deviceCount] = Device({
            owner: msg.sender,
            location: _location,
            lastPing: block.timestamp,
            verified: false,
            uptime: 0
        });
        emit DeviceRegistered(deviceCount, msg.sender);
    }

    function reportMetrics(uint256 _deviceId, uint256 _uptime) public {
        require(_deviceId <= deviceCount, "Device does not exist");
        Device storage device = devices[_deviceId];
        require(device.owner == msg.sender, "Not owner of device");

        device.uptime = _uptime;
        device.lastPing = block.timestamp;
        emit MetricsReported(_deviceId, _uptime);
    }

    function verifyDevice(uint256 _deviceId) public {
        require(_deviceId <= deviceCount, "Device does not exist");
        devices[_deviceId].verified = true;
        emit DeviceVerified(_deviceId);
    }

    function isVerified(uint256 _deviceId) public view returns (bool) {
        return devices[_deviceId].verified;
    }
}
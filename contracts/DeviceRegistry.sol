// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import \"@openzeppelin/contracts/token/ERC20/IERC20.sol\";

contract DeviceRegistry {
    struct Device {
        address owner;
        uint256 lastPing;
        bool verified;
        mapping(string => uint256) metrics;
        uint256 incentives;
        uint256 stakedAmount;
        bool isActive;
    }

    mapping(string => Device) public devices;
    mapping(string => bool) public deviceExists;
    string[] public deviceList;
    uint256 public deviceCount;
    IERC20 public token;
    
    // Staking configuration
    bool public stakingRequired;
    uint256 public minStakeAmount;
    mapping(address => uint256) public stakerBalances;

    event DeviceRegistered(string deviceId, address owner);
    event MetricsReported(string deviceId, string metricName, uint256 value);
    event DeviceVerified(string deviceId);
    event IncentivesDistributed(string deviceId, uint256 amount);
    event Staked(string deviceId, address owner, uint256 amount);
    event Unstaked(string deviceId, address owner, uint256 amount);

    constructor(address _tokenAddress, bool _stakingRequired, uint256 _minStakeAmount) {
        token = IERC20(_tokenAddress);
        stakingRequired = _stakingRequired;
        minStakeAmount = _minStakeAmount;
    }

    function registerDevice(string memory _deviceId, address _owner, uint256 _stakeAmount) public {
        require(!deviceExists[_deviceId], \"Device ID already exists\");
        
        // Check staking requirements
        if (stakingRequired) {
            require(_stakeAmount >= minStakeAmount, \"Insufficient staking amount\");
            if (_stakeAmount > 0) {
                require(token.transferFrom(msg.sender, address(this), _stakeAmount), \"Staking transfer failed\");
                stakerBalances[_owner] += _stakeAmount;
                devices[_deviceId].stakedAmount = _stakeAmount;
                emit Staked(_deviceId, _owner, _stakeAmount);
            }
        } else {
            // Staking is optional
            if (_stakeAmount > 0) {
                require(token.transferFrom(msg.sender, address(this), _stakeAmount), \"Staking transfer failed\");
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

    function reportMetric(
        string memory _deviceId,
        string memory _metricName,
        uint256 _value,
        bytes memory signature
    ) public {
        require(deviceExists[_deviceId], \"Device does not exist\");
        
        // Verify staking requirements
        if (stakingRequired) {
            require(devices[_deviceId].stakedAmount >= minStakeAmount, \"Device must stake tokens to report metrics\");
        }
        
        // Recreate the message that was signed
        bytes32 message = keccak256(abi.encodePacked(_deviceId, _metricName, _value, block.chainid));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked(\"\\x19Ethereum Signed Message:\\n32\", message));
        
        // Recover the signer address
        address signer = recoverSigner(ethSignedMessageHash, signature);
        
        // Verify the signer is the device owner
        require(signer == devices[_deviceId].owner, \"Invalid signature\");
        
        devices[_deviceId].metrics[_metricName] = _value;
        devices[_deviceId].lastPing = block.timestamp;
        emit MetricsReported(_deviceId, _metricName, _value);
        
        // Distribute incentives based on metric value and staking
        distributeIncentives(_deviceId, _metricName, _value);
    }

    function verifyDevice(string memory _deviceId) public {
        require(deviceExists[_deviceId], \"Device does not exist\");
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
        require(index < deviceCount, \"Index out of bounds\");
        return deviceList[index];
    }

    function getIncentives(string memory _deviceId) public view returns (uint256) {
        return devices[_deviceId].incentives;
    }

    function getStakedAmount(string memory _deviceId) public view returns (uint256) {
        return devices[_deviceId].stakedAmount;
    }

    function unstakeTokens(string memory _deviceId) public {
        require(deviceExists[_deviceId], \"Device does not exist\");
        require(devices[_deviceId].owner == msg.sender, \"Not owner of device\");
        
        uint256 stakedAmount = devices[_deviceId].stakedAmount;
        require(stakedAmount > 0, \"No staked tokens\");
        
        devices[_deviceId].stakedAmount = 0;
        stakerBalances[msg.sender] -= stakedAmount;
        require(token.transfer(msg.sender, stakedAmount), \"Unstaking transfer failed\");
        
        emit Unstaked(_deviceId, msg.sender, stakedAmount);
    }

    // Helper function to distribute incentives
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
        if (keccak256(abi.encodePacked(_metricName)) == keccak256(abi.encodePacked(\"uptime\"))) {
            // For uptime, incentive is proportional to value (max 100 tokens for 100% uptime)
            return (_value * 100) / 100;
        } else if (keccak256(abi.encodePacked(_metricName)) == keccak256(abi.encodePacked(\"temperature\"))) {
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
        require(sig.length == 65, \"Invalid signature length\");
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
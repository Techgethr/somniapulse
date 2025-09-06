// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeviceRegistryBase {
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

    constructor(address _tokenAddress, bool _stakingRequired, uint256 _minStakeAmount) {
        token = IERC20(_tokenAddress);
        stakingRequired = _stakingRequired;
        minStakeAmount = _minStakeAmount;
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
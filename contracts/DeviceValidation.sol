// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DeviceIncentives.sol";

contract DeviceValidation is DeviceIncentives {
    struct Validator {
        address addr;
        uint256 stakedAmount;
        bool isActive;
        uint256 minStakeAmount; // Stake mínimo personalizado por el owner
    }
    
    struct MalBehaviorReport {
        string deviceId;
        address reporter;
        string reason;
        bytes proof;
        uint256 timestamp;
        bool resolved;
        bool isValid;
    }
    
    mapping(address => Validator) public validators;
    mapping(uint256 => MalBehaviorReport) public reports;
    uint256 public reportCount;
    uint256 public slashingPercentage; // Porcentaje de slashing (0-100)
    
    event ValidatorRegistered(address validator, uint256 minStakeAmount);
    event ValidatorStaked(address validator, uint256 amount);
    event ValidatorUnstaked(address validator, uint256 amount);
    event MalBehaviorReported(uint256 reportId, string deviceId, address reporter, string reason);
    event ReportVerified(uint256 reportId, bool valid);
    event DeviceSlashed(string deviceId, uint256 amount);
    event ValidatorRewarded(address validator, uint256 amount);

    constructor(
        address _tokenAddress, 
        bool _stakingRequired, 
        uint256 _minStakeAmount,
        address _incentiveConfigAddress,
        string memory _network
    ) DeviceIncentives(_tokenAddress, _stakingRequired, _minStakeAmount, _incentiveConfigAddress, _network) {}
    
    // Modifier para restringir acceso a validadores
    modifier onlyValidator() {
        require(validators[msg.sender].isActive, "Only registered validators can call this function");
        _;
    }
    
    // Registrar validador (solo owner)
    function registerValidator(address _validator, uint256 _minStakeAmount) public onlyOwner {
        validators[_validator].addr = _validator;
        validators[_validator].minStakeAmount = _minStakeAmount;
        validators[_validator].isActive = true;
        emit ValidatorRegistered(_validator, _minStakeAmount);
    }
    
    // Stake de validador
    function stakeValidatorTokens(uint256 _amount) public {
        require(validators[msg.sender].isActive, "Validator not registered");
        require(_amount >= validators[msg.sender].minStakeAmount, "Insufficient staking amount");
        require(token.transferFrom(msg.sender, address(this), _amount), "Staking transfer failed");
        
        validators[msg.sender].stakedAmount += _amount;
        stakerBalances[msg.sender] += _amount;
        emit ValidatorStaked(msg.sender, _amount);
    }
    
    // Unstake de validador
    function unstakeValidatorTokens() public {
        require(validators[msg.sender].isActive, "Validator not registered");
        
        uint256 stakedAmount = validators[msg.sender].stakedAmount;
        require(stakedAmount > 0, "No staked tokens");
        
        validators[msg.sender].stakedAmount = 0;
        stakerBalances[msg.sender] -= stakedAmount;
        require(token.transfer(msg.sender, stakedAmount), "Unstaking transfer failed");
        
        emit ValidatorUnstaked(msg.sender, stakedAmount);
    }
    
    // Reportar mal comportamiento (solo validadores)
    function reportMalBehavior(
        string memory _deviceId,
        string memory _reason,
        bytes memory _proof
    ) public onlyValidator {
        require(deviceExists[_deviceId], "Device does not exist");
        
        reportCount++;
        reports[reportCount] = MalBehaviorReport({
            deviceId: _deviceId,
            reporter: msg.sender,
            reason: _reason,
            proof: _proof,
            timestamp: block.timestamp,
            resolved: false,
            isValid: false
        });
        
        emit MalBehaviorReported(reportCount, _deviceId, msg.sender, _reason);
    }
    
    // Verificar reporte (solo owner)
    function verifyReport(uint256 _reportId, bool _isValid) public onlyOwner {
        require(_reportId <= reportCount, "Report does not exist");
        require(!reports[_reportId].resolved, "Report already resolved");
        
        reports[_reportId].resolved = true;
        reports[_reportId].isValid = _isValid;
        emit ReportVerified(_reportId, _isValid);
        
        if (_isValid) {
            // Ejecutar slashing
            executeSlashing(_reportId);
        }
    }
    
    // Ejecutar slashing
    function executeSlashing(uint256 _reportId) internal {
        string memory deviceId = reports[_reportId].deviceId;
        address reporter = reports[_reportId].reporter;
        
        // Calcular monto a recortar
        uint256 slashAmount = 0;
        if (devices[deviceId].stakedAmount > 0) {
            // Si hay staking, recortar del staking
            slashAmount = (devices[deviceId].stakedAmount * slashingPercentage) / 100;
            devices[deviceId].stakedAmount -= slashAmount;
            stakerBalances[devices[deviceId].owner] -= slashAmount;
        } else {
            // Si no hay staking, recortar de incentivos
            slashAmount = (devices[deviceId].incentives * slashingPercentage) / 100;
            devices[deviceId].incentives -= slashAmount;
        }
        
        // Transferir monto recortado al validador que reportó
        if (slashAmount > 0) {
            require(token.transfer(reporter, slashAmount), "Slashing transfer failed");
            emit DeviceSlashed(deviceId, slashAmount);
            emit ValidatorRewarded(reporter, slashAmount);
        }
    }
    
    // Configurar porcentaje de slashing (solo owner)
    function setSlashingPercentage(uint256 _percentage) public onlyOwner {
        require(_percentage <= 100, "Percentage must be <= 100");
        slashingPercentage = _percentage;
    }
    
    // Obtener información de validador
    function getValidatorInfo(address _validator) public view returns (Validator memory) {
        return validators[_validator];
    }
}
const { ethers } = require("ethers");
const fs = require("fs");
const path = require("path");

// Load the DeviceRegistry ABI
const deviceRegistryABI = require("./pulse_abi.json");
// Load the ERC20 ABI
const erc20ABI = require("./erc20_abi.json");

class SomniaPulseSDK {
  constructor(network, contractAddress) {
    // Define network URLs
    const networkUrls = {
      testnet: "https://dream-rpc.somnia.network/",
      mainnet: "https://api.infra.mainnet.somnia.network/"
    };
    
    // Validate network parameter
    if (!networkUrls[network]) {
      throw new Error("Invalid network. Please use 'testnet' or 'mainnet'.");
    }
    
    this.provider = new ethers.providers.JsonRpcProvider(networkUrls[network]);
    this.contractAddress = contractAddress;
    this.abi = deviceRegistryABI;
    this.tokenAbi = erc20ABI;
    this.network = network;
  }

  async initializeWallet(privateKey) {
    this.wallet = new ethers.Wallet(privateKey, this.provider);
    this.contract = new ethers.Contract(this.contractAddress, this.abi, this.wallet);
    
    // Retrieve token address from the contract
    this.tokenAddress = await this.contract.token();
    this.tokenContract = new ethers.Contract(this.tokenAddress, this.tokenAbi, this.wallet);
  }

  async registerDevice(deviceId, ownerAddress, stakeAmount = 0) {
    // If staking is required or optional with amount, approve token transfer first
    if (stakeAmount > 0) {
      const approveTx = await this.tokenContract.approve(this.contractAddress, stakeAmount);
      await approveTx.wait();
    }
    
    const tx = await this.contract.registerDevice(deviceId, ownerAddress, stakeAmount);
    await tx.wait();
    console.log(`Device ${deviceId} registered with transaction: ${tx.hash}`);
  }

  async reportMetric(deviceId, metricName, value) {
    // Create the message to sign
    const message = ethers.utils.solidityKeccak256(
      ["string", "string", "uint256", "uint256"],
      [deviceId, metricName, value, (await this.provider.getNetwork()).chainId]
    );
    
    // Sign the message
    const signature = await this.wallet.signMessage(ethers.utils.arrayify(message));
    
    // Report the metric with signature
    const tx = await this.contract.reportMetric(deviceId, metricName, value, signature);
    await tx.wait();
    console.log(`Metric ${metricName} reported for device ${deviceId} with transaction: ${tx.hash}`);
  }

  async isVerified(deviceId) {
    const verified = await this.contract.isVerified(deviceId);
    console.log(`Device ${deviceId} verified status: ${verified}`);
    return verified;
  }

  async getMetric(deviceId, metricName) {
    const value = await this.contract.getMetric(deviceId, metricName);
    console.log(`Metric ${metricName} for device ${deviceId}: ${value}`);
    return value;
  }

  async getDeviceList() {
    const deviceList = await this.contract.getDeviceList();
    console.log(`Registered devices: ${deviceList.join(", ")}`);
    return deviceList;
  }

  async getDeviceAtIndex(index) {
    const deviceId = await this.contract.getDeviceAtIndex(index);
    console.log(`Device at index ${index}: ${deviceId}`);
    return deviceId;
  }

  async getIncentives(deviceId) {
    const incentives = await this.contract.getIncentives(deviceId);
    const decimals = await this.tokenContract.decimals();
    console.log(`Incentives for device ${deviceId}: ${ethers.utils.formatUnits(incentives, decimals)} tokens`);
    return incentives;
  }

  async getStakedAmount(deviceId) {
    const stakedAmount = await this.contract.getStakedAmount(deviceId);
    const decimals = await this.tokenContract.decimals();
    console.log(`Staked amount for device ${deviceId}: ${ethers.utils.formatUnits(stakedAmount, decimals)} tokens`);
    return stakedAmount;
  }

  async stakeTokens(deviceId, amount) {
    // Approve token transfer first
    const approveTx = await this.tokenContract.approve(this.contractAddress, amount);
    await approveTx.wait();
    
    const tx = await this.contract.stakeTokens(deviceId, amount);
    await tx.wait();
    console.log(`Tokens staked for device ${deviceId} with transaction: ${tx.hash}`);
  }

  async unstakeTokens(deviceId) {
    const tx = await this.contract.unstakeTokens(deviceId);
    await tx.wait();
    console.log(`Tokens unstaked for device ${deviceId} with transaction: ${tx.hash}`);
  }

  // Validator functions
  async registerValidator(validatorAddress, minStakeAmount) {
    const tx = await this.contract.registerValidator(validatorAddress, minStakeAmount);
    await tx.wait();
    console.log(`Validator ${validatorAddress} registered with transaction: ${tx.hash}`);
  }

  async stakeValidatorTokens(amount) {
    // Approve token transfer first
    const approveTx = await this.tokenContract.approve(this.contractAddress, amount);
    await approveTx.wait();
    
    const tx = await this.contract.stakeValidatorTokens(amount);
    await tx.wait();
    console.log(`Validator tokens staked with transaction: ${tx.hash}`);
  }

  async unstakeValidatorTokens() {
    const tx = await this.contract.unstakeValidatorTokens();
    await tx.wait();
    console.log(`Validator tokens unstaked with transaction: ${tx.hash}`);
  }

  async reportMalBehavior(deviceId, reason, proof) {
    const tx = await this.contract.reportMalBehavior(deviceId, reason, proof);
    await tx.wait();
    console.log(`Mal behavior reported for device ${deviceId} with transaction: ${tx.hash}`);
  }

  async verifyReport(reportId, isValid) {
    const tx = await this.contract.verifyReport(reportId, isValid);
    await tx.wait();
    console.log(`Report ${reportId} verified with transaction: ${tx.hash}`);
  }

  async setSlashingPercentage(percentage) {
    const tx = await this.contract.setSlashingPercentage(percentage);
    await tx.wait();
    console.log(`Slashing percentage set to ${percentage}% with transaction: ${tx.hash}`);
  }

  async getValidatorInfo(validatorAddress) {
    const validatorInfo = await this.contract.getValidatorInfo(validatorAddress);
    console.log(`Validator info:`, validatorInfo);
    return validatorInfo;
  }

  async getTokenBalance() {
    const balance = await this.tokenContract.balanceOf(this.wallet.address);
    const decimals = await this.tokenContract.decimals();
    console.log(`Token balance: ${ethers.utils.formatUnits(balance, decimals)} tokens`);
    return balance;
  }
}

module.exports = SomniaPulseSDK;
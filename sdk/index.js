const { ethers } = require("ethers");
const fs = require("fs");

class SomniaPulseSDK {
  constructor(providerUrl, contractAddress, abiPath, tokenAddress, tokenAbiPath) {
    this.provider = new ethers.providers.JsonRpcProvider(providerUrl);
    this.contractAddress = contractAddress;
    this.abi = JSON.parse(fs.readFileSync(abiPath, "utf8"));
    this.tokenAddress = tokenAddress;
    this.tokenAbi = JSON.parse(fs.readFileSync(tokenAbiPath, "utf8"));
  }

  async initializeWallet(privateKey) {
    this.wallet = new ethers.Wallet(privateKey, this.provider);
    this.contract = new ethers.Contract(this.contractAddress, this.abi, this.wallet);
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

  async verifyDevice(deviceId) {
    const tx = await this.contract.verifyDevice(deviceId);
    await tx.wait();
    console.log(`Device ${deviceId} verified with transaction: ${tx.hash}`);
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

  async unstakeTokens(deviceId) {
    const tx = await this.contract.unstakeTokens(deviceId);
    await tx.wait();
    console.log(`Tokens unstaked for device ${deviceId} with transaction: ${tx.hash}`);
  }

  async getTokenBalance() {
    const balance = await this.tokenContract.balanceOf(this.wallet.address);
    const decimals = await this.tokenContract.decimals();
    console.log(`Token balance: ${ethers.utils.formatUnits(balance, decimals)} tokens`);
    return balance;
  }
}

module.exports = SomniaPulseSDK;
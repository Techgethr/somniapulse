const { ethers } = require("ethers");
const fs = require("fs");

class SomniaPulseSDK {
  constructor(providerUrl, contractAddress, abiPath) {
    this.provider = new ethers.providers.JsonRpcProvider(providerUrl);
    this.contractAddress = contractAddress;
    this.abi = JSON.parse(fs.readFileSync(abiPath, "utf8"));
  }

  async initializeWallet(privateKey) {
    this.wallet = new ethers.Wallet(privateKey, this.provider);
    this.contract = new ethers.Contract(this.contractAddress, this.abi, this.wallet);
  }

  async registerDevice(deviceId) {
    const tx = await this.contract.registerDevice(deviceId);
    await tx.wait();
    console.log(`Device ${deviceId} registered with transaction: ${tx.hash}`);
  }

  async reportMetric(deviceId, metricName, value) {
    const tx = await this.contract.reportMetric(deviceId, metricName, value);
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
}

module.exports = SomniaPulseSDK;
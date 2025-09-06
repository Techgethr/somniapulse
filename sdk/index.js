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

  async registerDevice(location) {
    const tx = await this.contract.registerDevice(location);
    await tx.wait();
    console.log(`Device registered with transaction: ${tx.hash}`);
  }

  async reportMetrics(deviceId, uptime) {
    const tx = await this.contract.reportMetrics(deviceId, uptime);
    await tx.wait();
    console.log(`Metrics reported for device ${deviceId} with transaction: ${tx.hash}`);
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
}

module.exports = SomniaPulseSDK;
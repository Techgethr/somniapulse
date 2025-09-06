const SomniaPulseSDK = require("../sdk/index.js");
const path = require("path");
const { ethers } = require("ethers");

async function runDemo() {
  // Connection configuration
  const network = "testnet"; // O "mainnet"
  const contractAddress = "0xd0876600e82CCAa4aA0ab0Cd8bEa9c74F5b46De3"; // DeviceRegistry contract address

  // Private key of a test account (DO NOT SHARE THIS IN PRODUCTION)
  const privateKey = "0x...";

  const sdk = new SomniaPulseSDK(network, contractAddress);
  await sdk.initializeWallet(privateKey);

  console.log("🚀 Starting SomniaPulse demo...");

  // Verify initial token balance
  await sdk.getTokenBalance();

  // 1. Register a device with a custom ID and owner address (without initial staking)
  const deviceId = "sensor-001";
  const ownerAddress = "0x..."; // Device public address (can be the same as the wallet address for testing)
  await sdk.registerDevice(deviceId, ownerAddress);

  // 2. Stake tokens after registration (optional staking)
  const stakeAmount = ethers.utils.parseUnits("100", 18); // 100 tokens (adjust according to the token)
  await sdk.stakeTokens(deviceId, stakeAmount);

  // 3. Report generic metrics (with cryptographic authentication)
  await sdk.reportMetric(deviceId, "temperature", 25); // 25°C
  await sdk.reportMetric(deviceId, "uptime", 98); // 98% uptime

  // 4. Verify device verification status (device is already verified)
  await sdk.isVerified(deviceId);

  // 5. Get a specific metric
  await sdk.getMetric(deviceId, "temperature");

  // 6. Get accumulated incentives
  await sdk.getIncentives(deviceId);

  // 7. Get staked amount
  await sdk.getStakedAmount(deviceId);

  // 8. Verify token balance after receiving incentives
  await sdk.getTokenBalance();

  // 9. List registered devices
  await sdk.getDeviceList();

  // 10. Get device by index
  await sdk.getDeviceAtIndex(0);

  // 11. Unstake tokens (optional)
  // await sdk.unstakeTokens(deviceId);
}

runDemo().catch(console.error);
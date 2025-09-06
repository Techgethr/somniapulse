const SomniaPulseSDK = require("../sdk/index.js");
const path = require("path");
const { ethers } = require("ethers");

async function runValidationDemo() {
  // Connection configuration
  const network = "testnet"; // O "mainnet"
  const contractAddress = "0xd0876600e82CCAa4aA0ab0Cd8bEa9c74F5b46De3"; // DeviceRegistry contract address

  // Private keys (DO NOT SHARE THIS IN PRODUCTION)
  const ownerPrivateKey = "0x..."; // Owner of the contract
  const validatorPrivateKey = "0x..."; // Validator
  const deviceOwnerPrivateKey = "0x..."; // Device owner

  console.log("🚀 Starting SomniaPulse validation demo...");

  // Initialize SDK for the owner
  const ownerSDK = new SomniaPulseSDK(network, contractAddress);
  await ownerSDK.initializeWallet(ownerPrivateKey);

  // Initialize SDK for the validator
  const validatorSDK = new SomniaPulseSDK(network, contractAddress);
  await validatorSDK.initializeWallet(validatorPrivateKey);

  // Initialize SDK for the device owner
  const deviceOwnerSDK = new SomniaPulseSDK(network, contractAddress);
  await deviceOwnerSDK.initializeWallet(deviceOwnerPrivateKey);

  // 1. Configure slashing percentage (only owner)
  console.log("\n1. Configuring slashing percentage...");
  await ownerSDK.setSlashingPercentage(10); // 10% of slashing

  // 2. Register validator (only owner)
  console.log("\n2. Registering validator...");
  const validatorAddress = validatorSDK.wallet.address;
  await ownerSDK.registerValidator(validatorAddress, ethers.utils.parseUnits("50", 18)); // 50 tokens minimum

  // 3. Validator stakes tokens
  console.log("\n3. Validator stakes tokens...");
  await validatorSDK.stakeValidatorTokens(ethers.utils.parseUnits("100", 18)); // 100 tokens

  // 8. Validator reports malicious behavior
  console.log("\n8. Validator reporting malicious behavior...");
  // Create proof of malicious behavior (in a real implementation, this would be an invalid signature or incorrect data)
  const proof = ethers.utils.toUtf8Bytes("Device reported invalid temperature: 1000°C");
  await validatorSDK.reportMalBehavior(deviceId, "Invalid temperature", proof);

  // 9. Owner verifies the report (in a real implementation, this would require analysis of the proof)
  console.log("\n9. Owner verifying report...");
  const reportId = 1; // Assuming it's the first report
  await ownerSDK.verifyReport(reportId, true); // Report valid

  // 10. Verify incentives and staking after slashing
  console.log("\n10. Verifying incentives and staking after slashing...");
  await deviceOwnerSDK.getIncentives(deviceId);
  await deviceOwnerSDK.getStakedAmount(deviceId);

  // 11. Verify validator reward
  console.log("\n11. Verifying validator reward...");
  await validatorSDK.getTokenBalance();

  console.log("\n✅ Validation demo completed!");
}

runValidationDemo().catch(console.error);
const SomniaPulseSDK = require("../sdk/index.js");
const path = require("path");
const { ethers } = require("ethers");

async function runValidationDemo() {
  // Configuración de conexión (ajusta según tu entorno)
  const providerUrl = "http://127.0.0.1:8545"; // Ejemplo: Ganache
  const contractAddress = "0x..."; // Dirección del contrato DeviceRegistry desplegado
  const tokenAddress = "0x..."; // Dirección de un token ERC-20 existente
  const abiPath = path.resolve(__dirname, "../contracts/DeviceRegistry.abi.json");
  const tokenAbiPath = path.resolve(__dirname, "../contracts/IERC20.abi.json");

  // Claves privadas (NO COMPARTAS ESTO EN PRODUCCIÓN)
  const ownerPrivateKey = "0x..."; // Owner del contrato
  const validatorPrivateKey = "0x..."; // Validador
  const deviceOwnerPrivateKey = "0x..."; // Dueño del dispositivo

  console.log("🚀 Iniciando demo de validación de SomniaPulse...");

  // Inicializar SDK para el owner
  const ownerSDK = new SomniaPulseSDK(providerUrl, contractAddress, abiPath, tokenAddress, tokenAbiPath);
  await ownerSDK.initializeWallet(ownerPrivateKey);

  // Inicializar SDK para el validador
  const validatorSDK = new SomniaPulseSDK(providerUrl, contractAddress, abiPath, tokenAddress, tokenAbiPath);
  await validatorSDK.initializeWallet(validatorPrivateKey);

  // Inicializar SDK para el dueño del dispositivo
  const deviceOwnerSDK = new SomniaPulseSDK(providerUrl, contractAddress, abiPath, tokenAddress, tokenAbiPath);
  await deviceOwnerSDK.initializeWallet(deviceOwnerPrivateKey);

  // 1. Configurar porcentaje de slashing (solo owner)
  console.log("\n1. Configurando porcentaje de slashing...");
  await ownerSDK.setSlashingPercentage(10); // 10% de slashing

  // 2. Registrar validador (solo owner)
  console.log("\n2. Registrando validador...");
  const validatorAddress = validatorSDK.wallet.address;
  await ownerSDK.registerValidator(validatorAddress, ethers.utils.parseUnits("50", 18)); // 50 tokens mínimos

  // 3. Validador stakea tokens
  console.log("\n3. Validador stakeando tokens...");
  await validatorSDK.stakeValidatorTokens(ethers.utils.parseUnits("100", 18)); // 100 tokens

  // 4. Registrar dispositivo
  console.log("\n4. Registrando dispositivo...");
  const deviceId = "sensor-malicious-001";
  const deviceOwnerAddress = deviceOwnerSDK.wallet.address;
  await deviceOwnerSDK.registerDevice(deviceId, deviceOwnerAddress);

  // 5. Dispositivo stakea tokens
  console.log("\n5. Dispositivo stakeando tokens...");
  await deviceOwnerSDK.stakeTokens(deviceId, ethers.utils.parseUnits("200", 18)); // 200 tokens

  // 6. Reportar métricas válidas
  console.log("\n6. Reportando métricas válidas...");
  await deviceOwnerSDK.reportMetric(deviceId, "temperature", 25);
  await deviceOwnerSDK.reportMetric(deviceId, "uptime", 95);

  // 7. Verificar incentivos antes de slashing
  console.log("\n7. Verificando incentivos antes de slashing...");
  await deviceOwnerSDK.getIncentives(deviceId);
  await deviceOwnerSDK.getStakedAmount(deviceId);

  // 8. Validador reporta mal comportamiento
  console.log("\n8. Validador reportando mal comportamiento...");
  // Crear prueba de mal comportamiento (en una implementación real, esto sería una firma inválida o dato erróneo)
  const proof = ethers.utils.toUtf8Bytes("Dispositivo reportó temperatura inválida: 1000°C");
  await validatorSDK.reportMalBehavior(deviceId, "Temperatura inválida", proof);

  // 9. Owner verifica el reporte (en una implementación real, esto requeriría análisis de la prueba)
  console.log("\n9. Owner verificando reporte...");
  const reportId = 1; // Asumimos que es el primer reporte
  await ownerSDK.verifyReport(reportId, true); // Reporte válido

  // 10. Verificar incentivos y staking después de slashing
  console.log("\n10. Verificando incentivos y staking después de slashing...");
  await deviceOwnerSDK.getIncentives(deviceId);
  await deviceOwnerSDK.getStakedAmount(deviceId);

  // 11. Verificar recompensa del validador
  console.log("\n11. Verificando recompensa del validador...");
  await validatorSDK.getTokenBalance();

  console.log("\n✅ Demo de validación completada!");
}

runValidationDemo().catch(console.error);
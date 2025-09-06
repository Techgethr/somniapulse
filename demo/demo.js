const SomniaPulseSDK = require("../sdk/index.js");
const path = require("path");
const { ethers } = require("ethers");

async function runDemo() {
  // Configuración de conexión (ajusta según tu entorno)
  const network = "testnet"; // O "mainnet"
  const contractAddress = "0x..."; // Dirección del contrato DeviceRegistry desplegado

  // Clave privada de una cuenta de prueba (NO COMPARTAS ESTO EN PRODUCCIÓN)
  const privateKey = "0x...";

  const sdk = new SomniaPulseSDK(network, contractAddress);
  await sdk.initializeWallet(privateKey);

  console.log("🚀 Iniciando demo de SomniaPulse...");

  // Verificar balance inicial de tokens
  await sdk.getTokenBalance();

  // 1. Registrar un dispositivo con ID personalizado y dirección del propietario (sin staking inicial)
  const deviceId = "sensor-001";
  const ownerAddress = "0x..."; // Dirección pública del dispositivo (puede ser la misma que la de la wallet para pruebas)
  await sdk.registerDevice(deviceId, ownerAddress);

  // 2. Stakear tokens después del registro (staking opcional)
  const stakeAmount = ethers.utils.parseUnits("100", 18); // 100 tokens (ajusta según el token)
  await sdk.stakeTokens(deviceId, stakeAmount);

  // 3. Reportar métricas genéricas (con autenticación criptográfica)
  // El dispositivo se verifica automáticamente al reportar la primera métrica
  await sdk.reportMetric(deviceId, "temperature", 25); // 25°C
  await sdk.reportMetric(deviceId, "uptime", 98); // 98% uptime

  // 4. Consultar estado de verificación (el dispositivo ya está verificado)
  await sdk.isVerified(deviceId);

  // 5. Consultar una métrica específica
  await sdk.getMetric(deviceId, "temperature");

  // 6. Consultar incentivos acumulados
  await sdk.getIncentives(deviceId);

  // 7. Consultar cantidad staked
  await sdk.getStakedAmount(deviceId);

  // 8. Verificar balance de tokens después de recibir incentivos
  await sdk.getTokenBalance();

  // 9. Listar dispositivos registrados
  await sdk.getDeviceList();

  // 10. Obtener dispositivo por índice
  await sdk.getDeviceAtIndex(0);

  // 11. Retirar staking (opcional)
  // await sdk.unstakeTokens(deviceId);
}

runDemo().catch(console.error);
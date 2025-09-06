const SomniaPulseSDK = require("../sdk/index.js");
const path = require("path");
const { ethers } = require("ethers");

async function runDemo() {
  // Configuración de conexión (ajusta según tu entorno)
  const providerUrl = "http://127.0.0.1:8545"; // Ejemplo: Ganache
  const contractAddress = "0x..."; // Dirección del contrato DeviceRegistry desplegado
  const tokenAddress = "0x..."; // Dirección de un token ERC-20 existente (por ejemplo, DAI, USDC, etc.)
  const abiPath = path.resolve(__dirname, "../contracts/DeviceRegistry.abi.json");
  const tokenAbiPath = path.resolve(__dirname, "../contracts/IERC20.abi.json"); // ABI estándar de ERC-20

  // Clave privada de una cuenta de prueba (NO COMPARTAS ESTO EN PRODUCCIÓN)
  const privateKey = "0x...";

  const sdk = new SomniaPulseSDK(providerUrl, contractAddress, abiPath, tokenAddress, tokenAbiPath);
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
  await sdk.reportMetric(deviceId, "temperature", 25); // 25°C
  await sdk.reportMetric(deviceId, "uptime", 98); // 98% uptime

  // 4. Verificar dispositivo
  await sdk.verifyDevice(deviceId);

  // 5. Consultar estado de verificación
  await sdk.isVerified(deviceId);

  // 6. Consultar una métrica específica
  await sdk.getMetric(deviceId, "temperature");

  // 7. Consultar incentivos acumulados
  await sdk.getIncentives(deviceId);

  // 8. Consultar cantidad staked
  await sdk.getStakedAmount(deviceId);

  // 9. Verificar balance de tokens después de recibir incentivos
  await sdk.getTokenBalance();

  // 10. Listar dispositivos registrados
  await sdk.getDeviceList();

  // 11. Obtener dispositivo por índice
  await sdk.getDeviceAtIndex(0);

  // 12. Retirar staking (opcional)
  // await sdk.unstakeTokens(deviceId);
}

runDemo().catch(console.error);
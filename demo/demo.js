const SomniaPulseSDK = require("../sdk/index.js");
const path = require("path");

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

  // 1. Registrar un dispositivo con ID personalizado, dirección del propietario y staking opcional
  const deviceId = "sensor-001";
  const ownerAddress = "0x..."; // Dirección pública del dispositivo (puede ser la misma que la de la wallet para pruebas)
  const stakeAmount = ethers.utils.parseUnits("100", 18); // 100 tokens (ajusta según el token)
  await sdk.registerDevice(deviceId, ownerAddress, stakeAmount);

  // 2. Reportar métricas genéricas (con autenticación criptográfica)
  await sdk.reportMetric(deviceId, "temperature", 25); // 25°C
  await sdk.reportMetric(deviceId, "uptime", 98); // 98% uptime

  // 3. Verificar dispositivo
  await sdk.verifyDevice(deviceId);

  // 4. Consultar estado de verificación
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
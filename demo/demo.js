const SomniaPulseSDK = require("../sdk/index.js");
const path = require("path");

async function runDemo() {
  // Configuración de conexión (ajusta según tu entorno)
  const providerUrl = "http://127.0.0.1:8545"; // Ejemplo: Ganache
  const contractAddress = "0x..."; // Dirección del contrato DeviceRegistry desplegado
  const tokenAddress = "0x..."; // Dirección del contrato IncentiveToken desplegado
  const abiPath = path.resolve(__dirname, "../contracts/DeviceRegistry.abi.json");
  const tokenAbiPath = path.resolve(__dirname, "../contracts/IncentiveToken.abi.json");

  // Clave privada de una cuenta de prueba (NO COMPARTAS ESTO EN PRODUCCIÓN)
  const privateKey = "0x...";

  const sdk = new SomniaPulseSDK(providerUrl, contractAddress, abiPath, tokenAddress, tokenAbiPath);
  await sdk.initializeWallet(privateKey);

  console.log("🚀 Iniciando demo de SomniaPulse...");

  // Verificar balance inicial de tokens
  await sdk.getTokenBalance();

  // 1. Registrar un dispositivo con ID personalizado y dirección del propietario
  const deviceId = "sensor-001";
  const ownerAddress = "0x..."; // Dirección pública del dispositivo (puede ser la misma que la de la wallet para pruebas)
  await sdk.registerDevice(deviceId, ownerAddress);

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

  // 7. Verificar balance de tokens después de recibir incentivos
  await sdk.getTokenBalance();

  // 8. Listar dispositivos registrados
  await sdk.getDeviceList();

  // 9. Obtener dispositivo por índice
  await sdk.getDeviceAtIndex(0);
}

runDemo().catch(console.error);
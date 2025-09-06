const SomniaPulseSDK = require("../sdk/index.js");
const path = require("path");

async function runDemo() {
  // Configuración de conexión (ajusta según tu entorno)
  const providerUrl = "http://127.0.0.1:8545"; // Ejemplo: Ganache
  const contractAddress = "0x..."; // Dirección del contrato desplegado
  const abiPath = path.resolve(__dirname, "../contracts/DeviceRegistry.abi.json");

  // Clave privada de una cuenta de prueba (NO COMPARTAS ESTO EN PRODUCCIÓN)
  const privateKey = "0x...";

  const sdk = new SomniaPulseSDK(providerUrl, contractAddress, abiPath);
  await sdk.initializeWallet(privateKey);

  console.log("🚀 Iniciando demo de SomniaPulse...");

  // 1. Registrar un dispositivo
  await sdk.registerDevice("40.7128,-74.0060"); // Coordenadas de Nueva York

  // 2. Reportar métricas
  await sdk.reportMetrics(1, 98); // 98% uptime

  // 3. Verificar dispositivo
  await sdk.verifyDevice(1);

  // 4. Consultar estado de verificación
  await sdk.isVerified(1);
}

runDemo().catch(console.error);
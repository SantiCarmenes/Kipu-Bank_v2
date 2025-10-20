# 🚀 KipuBank V2: Moneda Digital Segura y Flexible

**KipuBank V2** es la versión final y refactorizada del sistema bancario inteligente originalmente diseñado para manejar solo ETH. Esta nueva versión introduce un enfoque moderno, seguro y flexible basado en múltiples activos ERC-20, con un límite de riesgo dinámico expresado en USD y validado mediante oráculos de Chainlink.

---

## ✅ 1. Mejoras Realizadas y Fundamentación Técnica

| Mejora | Descripción | Fundamento |
|--------|------------|------------|
| ✅ Soporte Multi-Token | Permite depósitos y retiros en **cualquier token ERC-20**, además de ETH (usando `address(0)` como alias). | Aumenta la flexibilidad y escalabilidad del banco digital. |
| ✅ Bank Cap Dinámico en USD | El contrato no limita por ETH estático, sino por **valor total en USD** (`s_totalUsdValue`). | Modelo de riesgo realista adaptable a múltiples activos. |
| ✅ Integración con Chainlink | Precios en tiempo real mediante feeds de Chainlink. | Previene desbalances y permite validar el valor total con precisión confiable. |
| ✅ Validación de Precios Obsoletos | El contrato **rechaza transacciones si el precio está obsoleto o comprometido**. | Previene ataques de manipulación de precios (oracle risk). |
| ✅ Lógica Interna Unificada | Uso de funciones internas `_deposit` y `_withdraw`. | DRY (Don't Repeat Yourself) y seguridad lógica centralizada. |

---

## 🛠️ 2. Instrucciones de Despliegue (Testnet Sepolia con Foundry)

### 📍 Prerrequisitos

| Requisito | Valor |
|-----------|-------|
| RPC URL | `$SEPOLIA_RPC_URL` |
| Private Key | `$PRIVATE_KEY` |
| Foundry instalado | ✅ |
| ETH de prueba en la cuenta | ✅ |

---

### 📦 2.1 Comando de Despliegue + Verificación

```bash
forge script script/DeployKipuBank.s.sol:DeployKipuBank   --rpc-url $SEPOLIA_RPC_URL   --private-key $PRIVATE_KEY   --broadcast   --verify   -vvvv
```

⚠️ `--verify` publica el código en Etherscan (requerido para entrega final y transparencia).

---

## 📍 3. Configuración Post-Despliegue (Asignación de Oráculos)

El límite en USD requiere oráculos reales. Setearlos usando `setPriceFeed(address token, address priceFeed)`.

| Activo | Dirección Token (Sepolia) | Chainlink Price Feed |
|--------|--------------------------|----------------------|
| ETH | `0x0000000000000000000000000000000000000000` | `0x694AA1769357215DE4FAC081bf1f309aDC325306` |
| USDC | `0x1c7d4b196cb0c7b01d743fbc6116a902379c7238` | `0x0d79df66BE487753B02D015Fb622DED7f0E9798d` |

### ✅ Ejemplo para configurar USDC

```bash
cast send <KIPU_BANK_ADDRESS> "setPriceFeed(address,address)"   "0x1c7d4b196cb0c7b01d743fbc6116a902379c7238"   "0x0d79df66BE487753B02D015Fb622DED7f0E9798d"   --private-key $PRIVATE_KEY
```

---

## 🧩 4. Decisiones de Diseño Clave y Trade-Offs

### ✅ A. Precisión vs. Gas (Bank Cap)
| Opción | Rechazada | Aceptada |
|--------|-----------|----------|
| Recalcular valor total iterando balances | ❌ Muy costoso en gas | |
| Rastreo incremental con `s_totalUsdValue` | | ✅ Eficiente y estándar |

🟡 *Riesgo asumido:* ligera desactualización si hay fluctuaciones entre transacciones.

### ✅ B. Seguridad en Fallback y Receive

- Ambas funciones llaman a `this.deposit()`, garantizando que pasen por modificadores de seguridad (`withinBankCap`).
- Previene bypasses si se envía ETH sin data.

### ✅ C. Estandarización de ETH como Token
- ETH se maneja como `address(0)`.
- Abstracción permite lógica única para todos los activos.

---

## 💻 5. Interacción Básica (Ejemplo)

```solidity
deposit(address token, uint256 amount); // ETH => address(0)
withdraw(address token, uint256 amount);
getUsdValue(address user); // Retorna el valor total del usuario en USD
```

---

## 🏁 6. Conclusión: Proyecto Listo para Producción

✅ Seguro  | ✅ Profesional | ✅ Cumple estándares DeFi | ✅ Portafolio-ready

💬 *“KipuBank V2 representa la transición de un simple banco ETH a un sistema financiero tokenizado, escalable y gobernado por precio-realidad.”* 🚀

---

👤 Autor: **Santiago Cármenes**
📅 Versión: **Smart Contract V2 Final**
📍 Licencia: **MIT**

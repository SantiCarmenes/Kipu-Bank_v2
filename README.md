# 🌐 Kipu-Bank_v2

## 🔹 Description

**Kipu-Bank_v2** is the second iteration of the smart banking system originally designed just for ETH handling. This new version introduces a modern, secure, and flexible approach based on multiple ERC-20 assets, with a dynamic risk limit expressed in USD and validated through Chainlink oracles.

---

## ✅ 1. Improvements Made and Technical Rationale

| Improvement | Description | Rationale |
|--------|------------|------------|
| ✅ Multi-Token Support | Allows deposits and withdrawals in **any ERC-20 token**, in addition to ETH (using `address(0)` as an alias). | Increases the flexibility and scalability of the digital bank. |
| ✅ Dynamic Bank Cap in USD | The contract does not limit by static ETH, but by **total value in USD** (`s_totalUsdValue`). | Realistic risk model adaptable to multiple assets. |
| ✅ Integration with Chainlink | Real-time pricing via Chainlink feeds. | Prevents imbalances and allows the total value to be validated with reliable accuracy. |
| ✅ Obsolete Price Validation | The contract **rejects transactions if the price is obsolete or compromised**. | Prevents price manipulation attacks (oracle risk). |
| ✅ Unified Internal Logic | Use of internal functions `_deposit` and `_withdraw`. | DRY (Don't Repeat Yourself) and centralized logic security. |

---

## 🛠️ 2. Deployment Instructions (Sepolia Testnet with Foundry)

### 📍 Prerequisites

| Requirement | Value |
|-----------|-------|
| RPC URL | `$SEPOLIA_RPC_URL` |
| Private Key | `$PRIVATE_KEY` |
| Foundry installed | ✅ |
| Test ETH in account | ✅ |

---

### 📦 2.1 Deployment Command + Verification

```bash
forge script script/DeployKipuBank.s.sol:DeployKipuBank   --rpc-url $SEPOLIA_RPC_URL   --private-key $PRIVATE_KEY   --broadcast   --verify   -vvvv
```

⚠️ `--verify` publishes the code on Etherscan (required for final delivery and transparency).

---

## 📍 3. Post-Deployment Configuration (Oracle Assignment)

The USD limit requires real oracles. Set them using `setPriceFeed(token address, priceFeed address)`.

| Asset | Token Address (Sepolia) | Chainlink Price Feed |
|--------|--------------------------|----------------------|
| ETH | `0x000000000000000000000000000000000000000` | `0x694AA1769357215DE4FAC081bf1f309aDC325306` |
| USDC | `0x1c7d4b196cb0c7b01d743fbc6116a902379c7238` | `0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E` |

### ✅ Example for configuring USDC

```bash
cast send <KIPU_BANK_ADDRESS> “setPriceFeed(address,address)”   “0x1c7d4b196cb0c7b01d743fbc6116a902379c7238”   “0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E”   --private-key $PRIVATE_KEY
```

---

## 🧩 4. Key Design Decisions and Trade-Offs

### ✅ A. Accuracy vs. Gas (Bank Cap)
| Option | Rejected | Accepted |
|--------|-----------|----------|
| Recalculate total value by iterating balances | ❌ Very costly in gas | |
| Incremental tracking with `s_totalUsdValue` | | ✅ Efficient and standard |

🟡 *Assumed risk:* slight outdatedness if there are fluctuations between transactions.

### ✅ B. Security in Fallback and Receive

- Both functions call `this.deposit()`, ensuring that they pass through security modifiers (`withinBankCap`).
- Prevents bypasses if ETH is sent without data.

### ✅ C. Standardization of ETH as a Token
- ETH is handled as `address(0)`.
- Abstraction allows for unique logic for all assets.

---

## 💻 5. Basic Interaction (Example)

```solidity
depositToken(address tokenAddress, uint256 amount);
withdrawToken(address tokenAddress, uint256 amount);
getMyBalance(address tokenAddress);
```

---

## 🏁 6. Conclusion

✅ Secure  | ✅ Professional | ✅ Complies with DeFi standards | ✅ Portfolio-ready

💬 *“Kipu-Bank_V2 represents the transition from a simple ETH bank to a tokenized, scalable financial system governed by price-reality.”* 🚀

---

👤 Author: **Santiago Cármenes**

Translated with DeepL.com (free version)

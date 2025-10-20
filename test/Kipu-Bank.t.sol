// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import "kipubank/Kipu-Bank_v2.sol";
import {MockV3Aggregator} from "./MockV3Aggregator.sol";
import {MockERC20} from "./MockERC20.sol";

contract KipuBankTest is Test {
    KipuBank public kipuBank;
    MockV3Aggregator public ethPriceFeed;
    MockV3Aggregator public usdcPriceFeed;
    MockERC20 public usdc;

    // Test addresses and constants
    address public constant USER = address(0x1);
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    uint256 public constant INITIAL_BANK_CAP_USD = 1_000_000 * 1e8; // $1M 8 decimals
    uint256 public constant ETH_WITHDRAW_LIMIT = 2 * 1e18; // 2 ETH

    // Starting prices for mocks (8 decimals)
    int256 public constant INITIAL_ETH_PRICE = 2000 * 1e8; 
    int256 public constant INITIAL_USDC_PRICE = 1 * 1e8;

    // Config function to run before each test
    function setUp() public {
        // 1. Desplegar el contrato KipuBank
        kipuBank = new KipuBank(INITIAL_BANK_CAP_USD, ETH_WITHDRAW_LIMIT);

        // 2. Desplegar los Mocks
        ethPriceFeed = new MockV3Aggregator(INITIAL_ETH_PRICE);
        usdcPriceFeed = new MockV3Aggregator(INITIAL_USDC_PRICE);
        usdc = new MockERC20("USD Coin", "USDC", 6); // USDC tiene 6 decimales

        // 3. Configurar el KipuBank como 'owner' (esta dirección de test es el owner por defecto)
        kipuBank.allowToken(ETH_ADDRESS, address(ethPriceFeed));
        kipuBank.allowToken(address(usdc), address(usdcPriceFeed));
    }

    // Test starting conditions
    
    function testInitialSetup() public {
        assertEq(kipuBank.i_bankCap(), INITIAL_BANK_CAP_USD);
        assertEq(kipuBank.s_totalUsdValue(), 0);
    }
}
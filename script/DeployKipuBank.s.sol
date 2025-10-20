// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {KipuBank} from "../src/Kipu-Bank_v2.sol";

contract DeployKipuBank is Script {
    function run() external returns (KipuBank) {
        
        // Bank cap in USD 
        uint256 bankCap = 100000000 * 1e8; 

        // Withdraw limit in ETH.
        // ETH has 18 decimals.
        uint256 withdrawLimit = 10 * 1e18; 

        vm.startBroadcast();

        KipuBank kipuBank = new KipuBank(bankCap, withdrawLimit);

        vm.stopBroadcast();

        return kipuBank;
    }
}
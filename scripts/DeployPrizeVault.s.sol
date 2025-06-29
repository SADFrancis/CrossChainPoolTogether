// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../lib/forge-std/src/Script.sol";
import {PrizeVault} from "../src/PrizeVault.sol";
import { PrizePool } from "pt-v5-prize-pool/PrizePool.sol";
import { IERC4626 } from "openzeppelin/interfaces/IERC4626.sol";

// To deploy:

// deploying this to BASE SEPOLIA
//  echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
//  source ~/.bashrc
// direnv allow
// forge script ./scripts/DeployPrizeVault.s.sol:DeployPrizeVault -vvvv --broadcast --rpc-url base-sepolia --verify

// Going to use deployed contracts
// https://dev.pooltogether.com/protocol/deployments/testnets/base-sepolia/



contract DeployPrizeVault is Script {
    function run() public {
        vm.startBroadcast();

        PrizeVault prizeVault = new PrizeVault(
            "USD Coin", /* name*/
            "USDC",/* symbol */
            IERC4626(vm.envAddress("YIELD_VAULT")),/* IERC4626 yieldVault*/
            PrizePool(vm.envAddress("PRIZE_POOL")),/* PrizePool prizePool*/
            vm.envAddress("CLAIMER"),/* address claimer_*/
            msg.sender,/* address yieldFeeRecipient_*/
            0,/* uint32 yieldFeePercentage*/
            100000, /*uint256 yield buffer */
            msg.sender /*owner*/
        );

        console.log(
            "PrizeVault deployed to ",
            address(prizeVault)
        );

        vm.stopBroadcast();
    }
}
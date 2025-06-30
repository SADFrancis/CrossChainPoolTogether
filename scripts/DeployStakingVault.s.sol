// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import { StakingVault } from "../lib/pt-v5-staking-vault/src/StakingVault.sol";
import { IERC20 } from "lib/pt-v5-staking-vault/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// To deploy:

// deploying this to BASE SEPOLIA
//  echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
//  source ~/.bashrc
// direnv allow
// forge script ./scripts/DeployPrizeVault.s.sol:DeployPrizeVault -vvvv --broadcast --rpc-url base-sepolia --verify

// Going to use deployed contracts
// https://dev.pooltogether.com/protocol/deployments/testnets/base-sepolia/



contract DeployStakingVault is Script {
    function run() public {
        vm.startBroadcast();
        //address usdcAddress = vm.envAddress("DESTINATION_USDC");
        StakingVault stakingVault = new StakingVault(
            "Staking Vault - USD Coin", // name
            "stk-USDC", // symbol  
            IERC20(0x036CbD53842c5426634e7929541eC2318f3dCF7e) // asset
        );

        console.log(
            "StakingVault deployed to ",
            address(stakingVault)
        );

        vm.stopBroadcast();
    }
}
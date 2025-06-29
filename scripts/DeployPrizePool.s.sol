// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import { PrizePool,ConstructorParams } from "pt-v5-prize-pool/PrizePool.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import { TwabController } from "pt-v5-twab-controller/TwabController.sol";


// To deploy:

// deploying this to BASE SEPOLIA
//  echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
//  source ~/.bashrc
// direnv allow
// forge script ./scripts/DeployPrizePool.s.sol:DeployPrizePool -vvvv --broadcast --rpc-url base-sepolia --verify

// Going to use deployed contracts
// https://dev.pooltogether.com/protocol/deployments/testnets/base-sepolia/



contract DeployPrizePool is Script {

    // struct ConstructorParams {
    //     IERC20 prizeToken;
    //     TwabController twabController;
    //     address creator;
    //     uint256 tierLiquidityUtilizationRate;
    //     uint48 drawPeriodSeconds;
    //     uint48 firstDrawOpensAt;
    //     uint24 grandPrizePeriodDraws;
    //     uint8 numberOfTiers;
    //     uint8 tierShares;
    //     uint8 canaryShares;
    //     uint8 reserveShares;
    //     uint24 drawTimeout;
    // }


    // firstDrawOpensAt
    /*
    I used ChatGPT to calculate this:

    TwabController
    https://sepolia.basescan.org/address/0x3fFC739e78F84fd116072E3621e5CAFb3a80405f#readContract
    if ((params.firstDrawOpensAt - twabPeriodOffset) % twabPeriodLength != 0) {

    uint48(block.timestamp + 1716922800)

    twabPeriodOffset= 1716922800
    twabPeriodLength=3600

    (num - offset ) % len = 0

    num - offset = len

    num = len + offset
    x + block.timestamp = offset+ len
    
     */

    function run() public {

        ConstructorParams memory params = ConstructorParams({
            prizeToken: IERC20(0x036CbD53842c5426634e7929541eC2318f3dCF7e), /*IERC20 Prize Token USDC 6 decimals*/
            twabController: TwabController(0x3fFC739e78F84fd116072E3621e5CAFb3a80405f), /*TwabController twabController official contract*/
            creator: tx.origin, /*address creator*/
            tierLiquidityUtilizationRate: 500000000000000000, // uint256 tierLiquidityUtilizationRate
            drawPeriodSeconds: 14400, // uint48 drawPeriodSeconds
            firstDrawOpensAt: uint48(1751223600), // uint48 firstDrawOpensAt 
            grandPrizePeriodDraws: 91, // uint24 grandPrizePeriodDraws
            numberOfTiers: 4, // uint8 numberOfTiers;
            tierShares: 100, // uint8 tierShares;
            canaryShares: 4, // uint8 canaryShares;
            reserveShares: 30, // uint8 reserveShares;
            drawTimeout: 91 // uint24 drawTimeout;
        });

        vm.startBroadcast();

        PrizePool prizePool = new PrizePool( params);

        console.log(
            "PrizeVault deployed to ",
            address(prizePool)
        );

        vm.stopBroadcast();
    }
}
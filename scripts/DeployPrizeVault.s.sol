// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../lib/forge-std/src/Script.sol";
import {PrizeVault} from "../src/PrizeVault.sol";

// To deploy:

// source .env
// forge script ./script/DeployTransferUSDC.s.sol:DeployTransferUSDC -vvv --broadcast --rpc-url avalancheFuji

// Going to use deployed contracts
// https://dev.pooltogether.com/protocol/deployments/testnets/base-sepolia/


    /// @notice Vault constructor
    /// @param name_ Name of the ERC20 share minted by the vault
    /// @param symbol_ Symbol of the ERC20 share minted by the vault
    /// @param yieldVault_ Address of the underlying ERC4626 vault in which assets are deposited to generate yield
    /// @param prizePool_ Address of the PrizePool that computes prizes
    /// @param claimer_ Address of the claimer
    /// @param yieldFeeRecipient_ Address of the yield fee recipient
    /// @param yieldFeePercentage_ Yield fee percentage
    /// @param yieldBuffer_ Amount of yield to keep as a buffer
    /// @param owner_ Address that will gain ownership of this contract
    // constructor(
    //     string memory name_,
    //     string memory symbol_,
    //     IERC4626 yieldVault_,
    //     PrizePool prizePool_,
    //     address claimer_,
    //     address yieldFeeRecipient_,
    //     uint32 yieldFeePercentage_,
    //     uint256 yieldBuffer_,
    //     address owner_


// contract DeployTransferPrizeVault is Script {
//     function run() public {
//         //uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//         vm.startBroadcast();

//         PrizeVault prizeVault = new PrizeVault(
//             "USD Coin", /* name*/
//             "USDC",/* symbol */
//             "",/* IERC4626 yieldVault*/
//             "",/* PrizePool prizePool*/
//             ,/* address claimer_*/
//             ,/* address yieldFeeRecipient_*/
//             ,/* uint32 yieldFeePercentage*/
//             , /*uint256 yield buffer */
//             msg.sender
//         );

//         console.log(
//             "TransferUSDC deployed to ",
//             address(prizeVault)
//         );

//         vm.stopBroadcast();
//     }
// }
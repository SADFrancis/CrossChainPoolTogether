// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Script.sol";
import {Sender} from "../src/ccip-usdc-example/USDCSender.sol";


// deploying this to avalanche Fuji
// source .env
// forge script ./script/DeployTransferUSDC.s.sol:DeployTransferUSDC -vvv --broadcast --rpc-url avalancheFuji

contract DeploySender is Script {
    function run() public {
        //uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast();

    /// @notice Constructor initializes the contract with the router address.
    /// @param _router The address of the router contract.
    /// @param _link The address of the link contract.
    /// @param _usdcToken The address of the usdc contract.
        // Sender sender = new Sender(
        //    // /*address*/ _router, 
        //    // /*address*/ _link,
        //   //  /*address*/ _usdcToken
        //     );

        // console.log(
        //     "Sender contract deployed to ",
        //     address(sender)
        // );

        vm.stopBroadcast();
    }
}
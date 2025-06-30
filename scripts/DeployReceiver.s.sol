// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Receiver} from "../src/ccip-usdc-example/Receiver.sol";

// deploying this to avalanche Fuji
//  echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
//  source ~/.bashrc
// direnv allow
// forge script ./scripts/DeployReceiver.s.sol:DeployReceiver -vvvv --broadcast --rpc-url base-sepolia --verify


contract DeployReceiver is Script {
    function run() public {
        vm.startBroadcast();
        
        // Receiver constructor(
        // address _router,
        // address _usdcToken,
        // address _staker
        // )
    
        Receiver receiver = new Receiver(
           vm.envAddress("DESTINATION_ROUTER"),// /*address*/ _router, 
           vm.envAddress("DESTINATION_USDC"),// /*address*/ _USDC,
          vm.envAddress("DEPLOYED_DESTINATION_STAKER")//  /*address*/ PrizeVault
            );

        console.log(
            "Receiver contract deployed to ",
            address(receiver)
        );

        vm.stopBroadcast();
    }
}
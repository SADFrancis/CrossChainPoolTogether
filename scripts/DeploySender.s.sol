// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Script.sol";
import {Sender} from "../src/ccip-usdc-example/USDCSender.sol";


// deploying this to avalanche Fuji
//  echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
//  source ~/.bashrc
// direnv allow
// forge script ./scripts/DeploySender.s.sol:DeploySender -vvvv --broadcast --rpc-url avalancheFuji --verify


contract DeploySender is Script {
    function run() public {
        //uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast();

    /// @notice Constructor initializes the contract with the router address.
    /// @param _router The address of the router contract.
    /// @param _link The address of the link contract.
    /// @param _usdcToken The address of the usdc contract.
        Sender sender = new Sender(
           vm.envAddress("SOURCE_ROUTER"),// /*address*/ _router, 
           vm.envAddress("SOURCE_LINK"),// /*address*/ _link,
          vm.envAddress("SOURCE_USDC")//  /*address*/ _usdcToken
            );

        console.log(
            "Sender contract deployed to ",
            address(sender)
        );

        vm.stopBroadcast();
    }
}
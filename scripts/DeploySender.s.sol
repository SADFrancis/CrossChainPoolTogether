// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../lib/forge-std/src/Script.sol";
import { Sender } from "../src/ccip-usdc-example/USDCSender.sol";

// deploying this to avalanche Fuji
// source .envrc or .env
// set a private key wallet (named 'defaultKey')if needed: cast wallet import defaultKey --interactive
//
// forge script ./scripts/DeploySender.s.sol:DeploySender --rpc-url avalancheFuji --account defaultKey --sender yourEthAddress --broadcast --verify -vvvvv
// cast call contractaddress "getAllAuthorizedCallers()" --rpc-url avalancheFuji

contract DeploySender is Script {
    function run() public {
        vm.startBroadcast();

        // The deployer of the contract will be the owner and can add/remove callers later.
        address deployerAddress = msg.sender;

        address[] memory authorizedCallers = new address[](3);
        authorizedCallers[0] = deployerAddress; // The deployer is an authorized caller.
        authorizedCallers[1] = 0xe865658aF136ffcF2D12BE81ED825239FF295A6D;
        authorizedCallers[2] = 0x82E0Cd516dB8f4fa09bE0083aa11Bf9C80Ef3eA0;

        Sender sender = new Sender(
            vm.envAddress("SOURCE_ROUTER"), // /*address*/ _router,
            vm.envAddress("SOURCE_LINK"), // /*address*/ _link,
            vm.envAddress("SOURCE_USDC"), //  /*address*/ _usdcToken
            authorizedCallers
        );

        console.log("Sender contract deployed to ", address(sender));

        vm.stopBroadcast();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../lib/forge-std/src/Script.sol";
import { Sender } from "../src/ccip-usdc-example/USDCSender.sol";

// deploying this to avalanche Fuji
// source .envrc or .env
// forge script ./scripts/DeploySender.s.sol:DeploySender --rpc-url avalancheFuji  --broadcast -vvvvv
// cast call contractaddress "getAllAuthorizedCallers()" --rpc-url avalancheFuji

contract DeploySender is Script {
    // Avalanche Fuji Addresses
    address router = 0xF694E193200268f9a4868e4Aa017A0118C9a8177;
    address link = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
    address usdcToken = 0x5425890298aed601595a70AB815c96711a31Bc65;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("HDWALLET_PRIVATE_KEY");
        if (deployerPrivateKey == 0) {
            revert("HDWALLET_PRIVATE_KEY must be set in your .env or .envrc file");
        }
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // The deployer of the contract will be the owner and can add/remove callers later.

        address[] memory authorizedCallers = new address[](3);
        authorizedCallers[0] = deployerAddress; // The deployer is an authorized caller.
        authorizedCallers[1] = 0xe865658aF136ffcF2D12BE81ED825239FF295A6D;
        authorizedCallers[2] = 0x82E0Cd516dB8f4fa09bE0083aa11Bf9C80Ef3eA0;

        Sender sender = new Sender(router, link, usdcToken, authorizedCallers);

        console.log("Sender contract deployed to ", address(sender));

        vm.stopBroadcast();
    }
}



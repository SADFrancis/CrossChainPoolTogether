// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../lib/forge-std/src/Script.sol";
import { Receiver } from "../src/ccip-usdc-example/Receiver.sol";

// To deploy:
// export SENDER_CONTRACT_ADDRESS=<Your Sender Contract Address on Avalanche Fuji>
// export STAKER_CONTRACT_ADDRESS=<Your PrizeVault Address on Base Sepolia> (optional, set to 0x0)
//
// source .envrc or .env
// set a private key wallet (named 'defaultKey') if needed: cast wallet import defaultKey --interactive
//
// forge script ./scripts/DeployReceiver.s.sol:DeployReceiver --rpc-url baseSepolia --account defaultKey --sender yourEthAddress --broadcast -vvvvv

contract DeployReceiver is Script {
    function run() external {
        // Base Sepolia Addresses
        address router = vm.envAddress("RECEIVER_ROUTER");
        address usdcToken = vm.envAddress("RECEIVER_USDC");

        // Avalanche Fuji (Source Chain) Details
        uint256 sourceChainSelector256 = vm.envUint("SOURCE_CHAIN_SELECTOR");
        require(
            (sourceChainSelector256 <= type(uint64).max),
            "SOURCE_CHAIN_SELECTOR value is too large for a uint64"
        );

        uint64 sourceChainSelector = uint64(sourceChainSelector256);

        address senderContract = vm.envAddress("SENDER_CONTRACT_ADDRESS");
        if (senderContract == address(0)) {
            revert("SENDER_CONTRACT_ADDRESS must be set in your environment");
        }

        // The staker address is optional. If not provided, it can be set later.
        address stakerContract = vm.envOr("STAKER_CONTRACT_ADDRESS", address(0));

        address deployerAddress = msg.sender;

        // The deployer of the contract will be an authorized caller.
        // Add other authorized callers as needed.
        address[] memory authorizedCallers = new address[](3);
        authorizedCallers[0] = deployerAddress; // The deployer is an authorized caller.
        authorizedCallers[1] = 0xe865658aF136ffcF2D12BE81ED825239FF295A6D;
        authorizedCallers[2] = 0x82E0Cd516dB8f4fa09bE0083aa11Bf9C80Ef3eA0;

        vm.startBroadcast();

        // Deploy the Receiver contract with staker address
        // The staker address can be set later via setStakerAddress.
        Receiver receiver = new Receiver(router, usdcToken, stakerContract, authorizedCallers);

        console.log("Receiver contract deployed to: ", address(receiver));

        // Set the sender for the source chain (Avalanche Fuji)
        receiver.setSenderForSourceChain(sourceChainSelector, senderContract);

        console.log(
            "Sender for source chain selector %s set to %s",
            sourceChainSelector,
            senderContract
        );

        // If a staker contract address was provided, set it.
        if (stakerContract != address(0)) {
            receiver.setStakerAddress(stakerContract);
            console.log("Staker (PrizeVault) address set to: ", stakerContract);

            // Verify the staker address was set correctly on-chain
            address currentStaker = receiver.s_staker(); // This calls the public getter for s_staker
            console.log("Check the set staker address from contract: ", currentStaker);
        } else {
            console.log(
                "No STAKER_CONTRACT_ADDRESS provided. It can be set later by an authorized caller."
            );
        }

        vm.stopBroadcast();
    }
}

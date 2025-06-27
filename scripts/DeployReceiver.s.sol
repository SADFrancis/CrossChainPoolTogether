// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Receiver} from "../src/ccip-usdc-example/Receiver.sol";

// To deploy:

// source .env
// forge script ./script/DeployTransferUSDC.s.sol:DeployTransferUSDC -vvv --broadcast --rpc-url avalancheFuji
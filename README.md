This is a CCIP integration to Prize Vault

This repository uses `envrc` for environment variable maniplaution. See the `PRIZEVAULTREADME.md` file for more information. Please also refer to this [tutorial video on encrypting private keys](https://www.youtube.com/watch?v=VQe7cIpaE54) to fill in your .password file to use deploy and interact with contracts. Refer to the Makefile to deploy and interact contracts.

This project demo tested sending 1 USDC from Avalanche Fuji to Base Sepolia to be deposited into a custom PrizeVault contract in a single transaction. 

Please refer to the cabana site for the most up to date parameters to deploy PrizePool and PrizeVault contracts before using the contracts in the PoolTogether documentation.

https://factory.cabana.fi/
https://dev.pooltogether.com/protocol/deployments/base


Currently, the project is hardcoded to use the 6 decimal USDC token found here:

https://docs.chain.link/ccip/directory/testnet/token/USDC

The faucet for USDC can be found here:
https://faucet.circle.com/
# Makefile to run the PoolTogether Crosschain USDC Deposit demo

# Create a .envrc file and fill the relevant environment variables from .envrc

# This project encrypted private keys using this tutorial:
# https://www.youtube.com/watch?v=VQe7cIpaE54

# PoolTogether Factory Frontend to source parameters
# https://factory.cabana.fi/create

# Developer documentation to source other constructor parameters
# https://dev.pooltogether.com/protocol/deployments/testnets/base-sepolia/

#  Sender Contract Avalanche Fuji
    # https://testnet.snowtrace.io/address/0x076a964f4D318F08a594435a6e0421B381c2eb32

    # // USDC PrizePool contract Base Sepolia
    # 0xa8322fd822ad303181CB29C0125ef137179b6658

    # https://sepolia.basescan.org/address/0xa8322fd822ad303181cb29c0125ef137179b6658


# USDC Stakiing Vault contract Base Sepolia
# https://sepolia.basescan.org/address/0x8dfec628e42cc35665c621ad04e03dc627d15432

    # // USDC PrizeVault contract Base Sepolia
    # https://sepolia.basescan.org/address/0x8138ed0afc9b26f6e5ee623dd83d00947db2e245


    # Receiver contract Base Sepolia
    # https://sepolia.basescan.org/address/0x7e5035e84df11a48db74c2294ffcd66562328862


# ANY CHANGES to the .envrc, run the command
# $ direnv allow

# deploying this to BASE SEPOLIA
#  echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
#  source ~/.bashrc
# direnv allow

# DEPLOY SCRIPTS

SOURCE_RPC_URL ?= avalancheFuji
DESTINATION_RPC_URL ?= base-sepolia
# SOURCE_USDC ?= SOURCE_USDC
TO ?= $(DEV_ADDRESS)
AMOUNT ?=1
GAS_AMOUNT ?=200000
USDC_AMOUNT ?= 1000000
# assume you approve 1 USDC token later down the road
APPROVAL_AMOUNT ?=0x00000000000000000000000000000000000000000000000000000000000f4240 
HEX ?= 0x0000000000000000000000000000000000000000000000000000000000000000

# Default to Fuji, 
# Example command to switch source chain to Base Sepolia
# $ make deploy-sender SOURCE_RPC_URL=base-sepolia
deploy-sender:
	forge script ./scripts/DeploySender.s.sol:DeploySender -vvvv --broadcast --rpc-url $(SOURCE_RPC_URL) --verify

# The constructor parameter firstDrawOpensAt is hardcoded. You have to change it relative to your current time
# refer to the DeployPrizePool file to change
deploy-prize-pool:
	forge script ./scripts/DeployPrizePool.s.sol:DeployPrizePool -vvvv --broadcast --rpc-url  $(DESTINATION_RPC_URL) --verify


deploy-staking-vault:
	forge script ./scripts/DeployStakingVault.s.sol:DeployStakingVault -vvvv --broadcast --rpc-url $(DESTINATION_RPC_URL) --verify

# PrizePool's contract is currently hardcoded, refer to the DeployPrizeVault file to adjust
deploy-prize-vault:
	forge script ./scripts/DeployPrizeVault.s.sol:DeployPrizeVault -vvvv --broadcast --rpc-url  $(DESTINATION_RPC_URL) --verify

# PrizeVault's contract, the staker address parameter for the constructor, is currently hardcoded.
deploy-receiver: 
	forge script ./scripts/DeployReceiver.s.sol:DeployReceiver -vvvv --broadcast --rpc-url $(DESTINATION_RPC_URL) --verify



# Assuming you have your contracts deployed: Following commands are sourced from
# https://docs.chain.link/ccip/tutorials/evm/usdc
# to demo sending a USDC token from Avalanche to deposit into a PrizeVault on Base Sepolia 


# FUND SENDER CONTRACT

# General funding with native gas token
# cast send --to <CONTRACT_ADDRESS> --value <AMOUNT> --rpc-url <RPC_URL>
# cast send --to 0x123... --value 0.1ether --rpc-url baseSepolia


# sanity check make commands
test-echo:
	echo $(DEPLOYED_SOURCE_USDC_SENDER)

# cast send $AVA_CON --rpc-url avalancheFuji --private-key=$PRIVATE_KEY "transferUsdc(uint64,address,uint256,uint64)" 16015286601757825753 0xe865658aF136ffcF2D12BE81ED825239FF295A6D 1000000 0

check-usdc-balance:
	 cast call $(SOURCE_USDC) "balanceOf(address)(uint256)" $(TO) --rpc-url $(SOURCE_RPC_URL)

#################################################
####### FUNDING SENDER CONTRACT COMMANDS ########
#################################################


# Send 1 USDC (6 decimals) to Sender contract
fund-usdc:
	cast send $(SOURCE_USDC) "transfer(address,uint256)" $(DEPLOYED_SOURCE_USDC_SENDER) 1000000 --rpc-url $(SOURCE_RPC_URL)

# Send Link (18 decimals) to Sender contract: default 1 
# to send 30 see command below:
# $ make fund-link AMOUNT=30
fund-link:
	cast send $(SOURCE_LINK) "transfer(address,uint256)" $(DEPLOYED_SOURCE_USDC_SENDER) $(AMOUNT)ether --rpc-url $(SOURCE_RPC_URL)

# Withdraw USDC from Sender Contract
withdraw-usdc:
	cast send $(DEPLOYED_SOURCE_USDC_SENDER) "withdrawUsdcToken(address)" $(TO) --rpc-url $(SOURCE_RPC_URL)

# Withdraw Link from Sender Contract
withdraw-link:
	cast send $(DEPLOYED_SOURCE_USDC_SENDER) "withdrawLinkToken(address)" $(TO) --rpc-url $(SOURCE_RPC_URL)


############################################
############# SET PERMISSIONS ##############
############################################

# Set Sender for Source Chain on Receiver Contract

set-source-chain-sender:
	cast send $(DEPLOYED_DESTINATION_RECEIVER) "setSenderForSourceChain(uint64,address)" $(SOURCE_CHAIN_SELECTOR) $(DEPLOYED_SOURCE_USDC_SENDER) --rpc-url $(DESTINATION_RPC_URL)

set-destination-chain-receiver:
	cast send $(DEPLOYED_SOURCE_USDC_SENDER) "setReceiverForDestinationChain(uint64,address)" $(DESTINATION_CHAIN_SELECTOR) $(DEPLOYED_DESTINATION_RECEIVER) --rpc-url $(SOURCE_RPC_URL)

# default Gas amount = 200_000
# make set-dc-gas-limit GAS_AMOUNT=500000
set-dc-gas-limit:
	cast send $(DEPLOYED_SOURCE_USDC_SENDER) "setGasLimitForDestinationChain(uint64,uint256)" $(DESTINATION_CHAIN_SELECTOR) $(GAS_AMOUNT) --rpc-url $(SOURCE_RPC_URL)


# sanity check can deposit to PrizeVault contract on the same chain

# you need to donate tokens to the vault if it's newly created to get past the yield buffer so it can accept tokens
# $ make usdc-donate AMOUNT=5
usdc-donate:
	cast send $(DESTINATION_USDC) "transfer(address,uint256)" $(DEPLOYED_DESTINATION_STAKER) $$(($(AMOUNT)* 1000000)) --rpc-url $(DESTINATION_RPC_URL)

usdc-deposit:
	cast send $(DEPLOYED_DESTINATION_STAKER) "deposit(uint256,address)" $(USDC_AMOUNT) $(TO) --rpc-url $(DESTINATION_RPC_URL)

# make usdc-approve USDC_AMOUNT=5000000
usdc-approve:
	cast send $(DESTINATION_USDC) "approve(address,uint256)" $(DEPLOYED_DESTINATION_STAKER) $(USDC_AMOUNT) --rpc-url $(DESTINATION_RPC_URL)

usdc-check-allowance:
	cast call $(DESTINATION_USDC) "allowance(address,address)" $(TO) $(DEPLOYED_DESTINATION_STAKER) --rpc-url $(DESTINATION_RPC_URL)

# Take the above output and put below:
# $ make to-decimal HEX=
to-decimal:
	cast --to-dec $(HEX)

# Get usdc balance on destination chain
usdc-get-balance:
	cast call $(DESTINATION_USDC) "balanceOf(address)" $(TO) --rpc-url $(DESTINATION_RPC_URL)

# get max deposit for PrizeVault to determine if you need more donations:
vault-get-max-deposit:
	cast call $(DEPLOYED_DESTINATION_STAKER) "maxDeposit(address)" $(TO) --rpc-url $(DESTINATION_RPC_URL)

# get yield buffer for PrizeVault Contract

vault-get-yield-buffer:
	cast call $(DEPLOYED_DESTINATION_STAKER) "yieldBuffer()" --rpc-url $(DESTINATION_RPC_URL)

vault-get-total-assets:
	cast call $(DEPLOYED_DESTINATION_STAKER) "totalAssets()" --rpc-url $(DESTINATION_RPC_URL)

# Cross chain approve

cross-chain-usdc-approve:
	cast send $(DEPLOYED_SOURCE_USDC_SENDER) "crossChainApprovalPayLink(uint64,address,uint256)" $(DESTINATION_CHAIN_SELECTOR) $(DESTINATION_ROUTER) $(USDC_AMOUNT) --rpc-url $(SOURCE_RPC_URL) 

# Cross Chain deposit USDC into the Prize Vault AND PAY LINK!!!
cross-chain-usdc-deposit:
	cast send $(DEPLOYED_SOURCE_USDC_SENDER) "crossChainDepositPayLink(uint64,address,uint256)" $(DESTINATION_CHAIN_SELECTOR) $(TO) $(USDC_AMOUNT) --rpc-url $(SOURCE_RPC_URL) 




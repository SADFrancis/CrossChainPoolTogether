// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24; // adding the carrot cause I'm sick of the error popping up

import {IRouterClient} from "@chainlink/contracts-ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink/contracts/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink/contracts-ccip/libraries/Client.sol";
import {IERC20} from "@chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@chainlink/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

// Source Chain CCIP Sender contract

interface IStaker {
    function stake(address beneficiary, uint256 amount) external;

    function redeem() external;
}

interface IPrizeVault {
    function deposit(uint256 _assets, address _receiver) external;
}

/// @title - A simple messenger contract for transferring tokens to a receiver  that calls a staker contract.
contract Sender is OwnerIsCreator {
    using SafeERC20 for IERC20;

    // Custom errors to provide more descriptive revert messages.
    error InvalidRouter(); // Used when the router address is 0
    error InvalidLinkToken(); // Used when the link token address is 0
    error InvalidUsdcToken(); // Used when the usdc token address is 0
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees); // Used to make sure contract has enough balance to cover the fees.
    error NothingToWithdraw(); // Used when trying to withdraw Ether but there's nothing to withdraw.
    error InvalidDestinationChain(); // Used when the destination chain selector is 0.
    error InvalidReceiverAddress(); // Used when the receiver address is 0.
    error NoReceiverOnDestinationChain(uint64 destinationChainSelector); // Used when the receiver address is 0 for a given destination chain.
    error AmountIsZero(); // Used if the amount to transfer is 0.
    error InvalidGasLimit(); // Used if the gas limit is 0.
    error NoGasLimitOnDestinationChain(uint64 destinationChainSelector); // Used when the gas limit is 0.

    // Event emitted when a message is sent to another chain.
    event MessageSent(
        bytes32 indexed messageId, // The unique ID of the CCIP message.
        uint64 indexed destinationChainSelector, // The chain selector of the destination chain.
        address indexed receiver, // The address of the receiver contract on the destination chain.
        address beneficiary, // The beneficiary of the staked tokens on the destination chain.
        address token, // The token address that was transferred.
        uint256 tokenAmount, // The token amount that was transferred.
        address feeToken, // the token address used to pay CCIP fees.
        uint256 fees // The fees paid for sending the message.
    );

    IRouterClient private immutable i_router;
    IERC20 private immutable i_linkToken;
    IERC20 private immutable i_usdcToken;
    //Client.EVMTokenTokenAmount zeroTokenAmount = Client.EVMTokenAmount[](0);

    // Mapping to keep track of the receiver contract per destination chain.
    mapping(uint64 => address) public s_receivers;
    // Mapping to store the gas limit per destination chain.
    mapping(uint64 => uint256) public s_gasLimits;

    // Mapping to store addresses to pay in Link (true) or native gas token (false)
    mapping(bool => address) public i_payInLinkOrGasToken;

    modifier validateDestinationChain(uint64 _destinationChainSelector) {
        if (_destinationChainSelector == 0) revert InvalidDestinationChain();
        _;
    }

    /// @notice Constructor initializes the contract with the router address.
    /// @param _router The address of the router contract.
    /// @param _link The address of the link contract.
    /// @param _usdcToken The address of the usdc contract.
    constructor(address _router, address _link, address _usdcToken) {
        if (_router == address(0)) revert InvalidRouter();
        if (_link == address(0)) revert InvalidLinkToken();
        if (_usdcToken == address(0)) revert InvalidUsdcToken();
        i_router = IRouterClient(_router);
        i_linkToken = IERC20(_link);
        i_usdcToken = IERC20(_usdcToken);
        i_payInLinkOrGasToken[true] = _link;
        i_payInLinkOrGasToken[false] = address(0);
    }

    /// @dev Set the receiver contract for a given destination chain.
    /// @notice This function can only be called by the owner.
    /// @param _destinationChainSelector The selector of the destination chain.
    /// @param _receiver The receiver contract on the destination chain .
    function setReceiverForDestinationChain(
        uint64 _destinationChainSelector,
        address _receiver
    ) external onlyOwner validateDestinationChain(_destinationChainSelector) {
        if (_receiver == address(0)) revert InvalidReceiverAddress();
        s_receivers[_destinationChainSelector] = _receiver;
    }

    /// @dev Set the gas limit for a given destination chain.
    /// @notice This function can only be called by the owner.
    /// @param _destinationChainSelector The selector of the destination chain.
    /// @param _gasLimit The gas limit on the destination chain .
    function setGasLimitForDestinationChain(
        uint64 _destinationChainSelector,
        uint256 _gasLimit
    ) external onlyOwner validateDestinationChain(_destinationChainSelector) {
        if (_gasLimit == 0) revert InvalidGasLimit();
        s_gasLimits[_destinationChainSelector] = _gasLimit;
    }

    /// @dev Delete the receiver contract for a given destination chain.
    /// @notice This function can only be called by the owner.
    /// @param _destinationChainSelector The selector of the destination chain.
    function deleteReceiverForDestinationChain(
        uint64 _destinationChainSelector
    ) external onlyOwner validateDestinationChain(_destinationChainSelector) {
        if (s_receivers[_destinationChainSelector] == address(0))
            revert NoReceiverOnDestinationChain(_destinationChainSelector);
        delete s_receivers[_destinationChainSelector];
    }

    /// @notice Sends data and transfer tokens to receiver on the destination chain.
    /// @notice Pay for fees in LINK.
    /// @dev Assumes your contract has sufficient LINK to pay for CCIP fees.
    /// @param _destinationChainSelector The identifier (aka selector) for the destination blockchain.
    /// @param _beneficiary The address of the beneficiary of the staked tokens on the destination blockchain.
    /// @param _amount token amount.
    /// @return messageId The ID of the CCIP message that was sent.
    function sendMessagePayLINK(
        uint64 _destinationChainSelector,
        address _beneficiary,
        uint256 _amount
    )
        external
        onlyOwner
        validateDestinationChain(_destinationChainSelector)
        returns (bytes32 messageId)
    {
        address receiver = s_receivers[_destinationChainSelector];
        if (receiver == address(0))
            revert NoReceiverOnDestinationChain(_destinationChainSelector);
        if (_amount == 0) revert AmountIsZero();
        uint256 gasLimit = s_gasLimits[_destinationChainSelector];
        if (gasLimit == 0)
            revert NoGasLimitOnDestinationChain(_destinationChainSelector);
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        // address(linkToken) means fees are paid in LINK
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: address(i_usdcToken),
            amount: _amount
        });
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver), // ABI-encoded receiver address
            data: abi.encodeWithSelector(
                IStaker.stake.selector, //@audit-info  CHANGE FOR PRIZE POOL
                _beneficiary,
                _amount
            ), // Encode the function selector and the arguments of the stake function
            tokenAmounts: tokenAmounts, // The amount and type of token being transferred
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit and allowing out-of-order execution.
                // Best Practice: For simplicity, the values are hardcoded. It is advisable to use a more dynamic approach
                // where you set the extra arguments off-chain. This allows adaptation depending on the lanes, messages,
                // and ensures compatibility with future CCIP upgrades. Read more about it here: https://docs.chain.link/ccip/concepts/best-practices/evm#using-extraargs
                Client.GenericExtraArgsV2({
                    gasLimit: gasLimit, // Gas limit for the callback on the destination chain
                    allowOutOfOrderExecution: true // Allows the message to be executed out of order relative to other messages from the same sender
                })
            ),
            // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
            feeToken: address(i_linkToken)
        });

        // Get the fee required to send the CCIP message
        uint256 fees = i_router.getFee(
            _destinationChainSelector,
            evm2AnyMessage
        );

        if (fees > i_linkToken.balanceOf(address(this)))
            revert NotEnoughBalance(i_linkToken.balanceOf(address(this)), fees);

        // approve the Router to transfer LINK tokens on contract's behalf. It will spend the fees in LINK
        i_linkToken.approve(address(i_router), fees);

        // approve the Router to spend usdc tokens on contract's behalf. It will spend the amount of the given token
        i_usdcToken.approve(address(i_router), _amount);

        // Send the message through the router and store the returned message ID
        messageId = i_router.ccipSend(
            _destinationChainSelector,
            evm2AnyMessage
        );

        // Emit an event with message details
        emit MessageSent(
            messageId,
            _destinationChainSelector,
            receiver,
            _beneficiary,
            address(i_usdcToken),
            _amount,
            address(i_linkToken),
            fees
        );

        // Return the message ID
        return messageId;
    }

    /// @notice Allows the owner of the contract to withdraw all LINK tokens in the contract and transfer them to a beneficiary.
    /// @dev This function reverts with a 'NothingToWithdraw' error if there are no tokens to withdraw.
    /// @param _beneficiary The address to which the tokens will be sent.
    function withdrawLinkToken(address _beneficiary) public onlyOwner {
        // Retrieve the balance of this contract
        uint256 amount = i_linkToken.balanceOf(address(this));

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        i_linkToken.safeTransfer(_beneficiary, amount);
    }

    /// @notice Allows the owner of the contract to withdraw all usdc tokens in the contract and transfer them to a beneficiary.
    /// @dev This function reverts with a 'NothingToWithdraw' error if there are no tokens to withdraw.
    /// @param _beneficiary The address to which the tokens will be sent.
    function withdrawUsdcToken(address _beneficiary) public onlyOwner {
        // Retrieve the balance of this contract
        uint256 amount = i_usdcToken.balanceOf(address(this));

        // Revert if there is nothing to withdraw
        if (amount == 0) revert NothingToWithdraw();

        i_usdcToken.safeTransfer(_beneficiary, amount);
    }

    /**
     * @notice Approve `_staker` to spend `_amount` USDC on the destination chain.
     *         Pays CCIP fees in LINK held by this contract.
     *
     * @param _destinationChainSelector  CCIP chain selector of the destination chain.
     * @param _addressToApprove     Address that should receive the allowance on dest-chain.
     * @param _amount     Allowance amount in USDC’s smallest unit (6 decimals).
     * @param _payGasInLink   Bool to choose to between Link or Gas Token as payment
     * @return messageId      The CCIP message ID.
     */
    function crossChainApproval(
        uint64  _destinationChainSelector,
        address _addressToApprove,
        uint256 _amount,
        bool _payGasInLink
    )
        external
        onlyOwner
        validateDestinationChain(_destinationChainSelector)
        returns (bytes32 messageId)
    {
        /* ──────────────────────── sanity checks ───────────────────────── */
        if (_addressToApprove == address(0))      revert InvalidReceiverAddress();
        if (_amount == 0)               revert AmountIsZero();

        address receiver = s_receivers[_destinationChainSelector];
        if (receiver == address(0))     revert NoReceiverOnDestinationChain(_destinationChainSelector);

        uint256 gasLimit = s_gasLimits[_destinationChainSelector];
        if (gasLimit == 0)              revert NoGasLimitOnDestinationChain(_destinationChainSelector);

        address gasToken = i_payInLinkOrGasToken[_payGasInLink];

        /* ─────────────────────── build CCIP payload ───────────────────── */

        // Call data: usdc.approve( _staker, _amount )
        bytes memory callData = abi.encodeWithSelector(
            i_usdcToken.approve.selector,
            _addressToApprove,
            _amount
        );

        Client.EVM2AnyMessage memory msg_ = _buildCCIPMessage(
            _addressToApprove,
             callData,
            gasToken,
            gasLimit,
            true
        );
        
        // Client.EVM2AnyMessage({
        //     receiver:    abi.encode(receiver),  // usdc token on dest-chain
        //     data:        callData,
        //     tokenAmounts: new Client.EVMTokenAmount[](0) , // ❌ no token transfer
        //     extraArgs:   Client._argsToBytes(
        //         Client.GenericExtraArgsV2({
        //             gasLimit: gasLimit,
        //             allowOutOfOrderExecution: true
        //         })
        //     ),
        //     feeToken: i_payInLinkOrGasToken[_payGasInLink]              // pay LINK (Pay LINK mode)
        // });

        /* ───────────────────── fees & approvals ───────────────────────── */

        uint256 fee = i_router.getFee(_destinationChainSelector, msg_);
        if (fee > i_linkToken.balanceOf(address(this)))
            revert NotEnoughBalance(i_linkToken.balanceOf(address(this)), fee);

        i_linkToken.approve(address(i_router), fee);  // approve just the exact fee

        /* ───────────────────── send the message ───────────────────────── */

        messageId = i_router.ccipSend(_destinationChainSelector, msg_);

        emit MessageSent(
            messageId,
            _destinationChainSelector,
            receiver,
            _addressToApprove,                 // beneficiary is the spender we just approved
            address(i_usdcToken),
            _amount,
            gasToken,              // fee paid in LINK
            fee
        );
    }

    /// @notice Sends data and transfer tokens to receiver on the destination chain.
    /// @notice Pay for fees in LINK.
    /// @dev Assumes your contract has sufficient LINK to pay for CCIP fees.
    /// @param _destinationChainSelector The identifier (aka selector) for the destination blockchain.
    /// @param _beneficiary The address of the beneficiary of the staked tokens on the destination blockchain.
    /// @param _amount token amount.
    /// @return messageId The ID of the CCIP message that was sent.
    function crossChainDepositPayLink(
        uint64 _destinationChainSelector,
        address _beneficiary,
        uint256 _amount
    )
        external
        onlyOwner
        validateDestinationChain(_destinationChainSelector)
        returns (bytes32 messageId)
    {
        address receiver = s_receivers[_destinationChainSelector];
        if (receiver == address(0))
            revert NoReceiverOnDestinationChain(_destinationChainSelector);
        if (_amount == 0) revert AmountIsZero();
        uint256 gasLimit = s_gasLimits[_destinationChainSelector];
        if (gasLimit == 0)
            revert NoGasLimitOnDestinationChain(_destinationChainSelector);
        
        
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage 
            = _buildCCIPMessage(
                _beneficiary,
                abi.encodeWithSelector(
                    IStaker.stake.selector, //@audit-info  CHANGE FOR PRIZE POOL
                    _beneficiary,
                    _amount
                ), // Encode the function selector and the arguments of the stake function),
                i_payInLinkOrGasToken[true], // paying in Link
                gasLimit,
                true,
                address(i_usdcToken),
                _amount
        );

        // Get the fee required to send the CCIP message
        uint256 fees = i_router.getFee(
            _destinationChainSelector,
            evm2AnyMessage
        );

        if (fees > i_linkToken.balanceOf(address(this)))
            revert NotEnoughBalance(i_linkToken.balanceOf(address(this)), fees);

        // approve the Router to transfer LINK tokens on contract's behalf. It will spend the fees in LINK
        i_linkToken.approve(address(i_router), fees);

        // approve the Router to spend usdc tokens on contract's behalf. It will spend the amount of the given token
        i_usdcToken.approve(address(i_router), _amount);

        // Send the message through the router and store the returned message ID
        messageId = i_router.ccipSend(
            _destinationChainSelector,
            evm2AnyMessage
        );

        // Emit an event with message details
        emit MessageSent(
            messageId,
            _destinationChainSelector,
            receiver,
            _beneficiary,
            address(i_usdcToken),
            _amount,
            address(i_linkToken),
            fees
        );
        // Return the message ID
        return messageId;
    }
    function _buildCCIPMessage(
        address _receiver,
        bytes memory _data,
        address _feeTokenAddress,
        uint256 _gasLimit,
        bool _allowOutOfOrderExecution

    ) private pure returns (Client.EVM2AnyMessage memory){

        // setting token amounts:
        // If not sending any token, create an empty array, if yes, create 1 size array
        Client.EVMTokenAmount[]
            memory tokenAmounts = new Client.EVMTokenAmount[](0);

        // Create EVM2AnyMessage struct in memorry with necessary info for sending cross chain message
        return
        Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // ABI-encoded receiver address
            data: _data, // abi.encode(_text) -> BI-encoded string
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(
                Client.GenericExtraArgsV2({
                    gasLimit: _gasLimit, // 200_000 -  gas limit for callback on destination chain
                    allowOutOfOrderExecution: _allowOutOfOrderExecution // true
                })
            ),
            feeToken: _feeTokenAddress
        });
    }


    function _buildCCIPMessage( // I can use the same function name with extra parameters and it'll recognize as unique
        address _receiver,
        bytes memory _data,
        address _feeTokenAddress,
        uint256 _gasLimit,
        bool _allowOutOfOrderExecution,
        address _token,
        uint256 _amount
        ) private pure returns (Client.EVM2AnyMessage memory){

        // setting token amounts:
        // If not sending any token, create an empty array, if yes, create 1 size array
        Client.EVMTokenAmount[]
            memory tokenAmounts = _token == address(0) || _amount == 0 ? 
                new Client.EVMTokenAmount[](0)
            :   new Client.EVMTokenAmount[](1);

       if (tokenAmounts.length > 0){
            tokenAmounts[0] = Client.EVMTokenAmount({
                token: _token,
                amount: _amount
            });
        }
        // Create EVM2AnyMessage struct in memorry with necessary info for sending cross chain message
        return
        Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // ABI-encoded receiver address
            data: _data, // abi.encode(_text) -> BI-encoded string
            tokenAmounts: tokenAmounts,
            extraArgs: Client._argsToBytes(
                Client.GenericExtraArgsV2({
                    gasLimit: _gasLimit, // 200_000 -  gas limit for callback on destination chain
                    allowOutOfOrderExecution: _allowOutOfOrderExecution // true
                })
            ),
            feeToken: _feeTokenAddress
        });
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {PrizeVault} from "./PrizeVault.sol";
import { IERC4626 } from "openzeppelin/interfaces/IERC4626.sol";
import { PrizePool } from "pt-v5-prize-pool/PrizePool.sol";


contract CrossChainPrizeVault is PrizeVault {
////////////////////////////////////////////////////////////////////////////////
    // Constructor
    ////////////////////////////////////////////////////////////////////////////////

    // CCIP compliant Prize Vault that accepts tokens from users from other chains

    /// @notice Vault constructor
    /// @param name_ Name of the ERC20 share minted by the vault
    /// @param symbol_ Symbol of the ERC20 share minted by the vault
    /// @param yieldVault_ Address of the underlying ERC4626 vault in which assets are deposited to generate yield
    /// @param prizePool_ Address of the PrizePool that computes prizes
    /// @param claimer_ Address of the claimer
    /// @param yieldFeeRecipient_ Address of the yield fee recipient
    /// @param yieldFeePercentage_ Yield fee percentage
    /// @param yieldBuffer_ Amount of yield to keep as a buffer
    /// @param owner_ Address that will gain ownership of this contract
    constructor(
        string memory name_,
        string memory symbol_,
        IERC4626 yieldVault_,
        PrizePool prizePool_,
        address claimer_,
        address yieldFeeRecipient_,
        uint32 yieldFeePercentage_,
        uint256 yieldBuffer_,
        address owner_
        ) 
        PrizeVault(
        name_,
        symbol_, 
        yieldVault_, 
        prizePool_,
        claimer_,
        yieldFeeRecipient_,
        yieldFeePercentage_,
        yieldBuffer_,
        owner_
        ){

        // TODO
        // Add in CCIP constructors
    }

    function crossChainDeposit(uint256 _assets, address _receiver) external returns (uint256) {

        // TODO 
        // CCIP time


        //return super.deposit(_assets,_receiver); // doesn't work, so copypaste the logic over
        uint256 _shares = previewDeposit(_assets);
        _depositAndMint(msg.sender, _receiver, _assets, _shares);
        return _shares;

    }
}
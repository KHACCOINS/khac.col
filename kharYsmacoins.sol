// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC20PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// @title KharYsma Coins (KHAC)
/// @notice ERC20 token with market-making, price floor stabilization, and secure withdrawal mechanisms
contract KharYsmaCoins is 
    ERC20Upgradeable, 
    ERC20BurnableUpgradeable, 
    ERC20PausableUpgradeable, 
    OwnableUpgradeable, 
    ERC20PermitUpgradeable, 
    ReentrancyGuardUpgradeable 
{
    // Constants
    uint256 public constant PRICE_FLOOR = 550 * 10 ** 18;
    uint256 public constant TOTAL_SUPPLY_CAP = 10_000_000 * 10 ** 18;
    uint256 public constant OWNER_SHARE_PERCENT = 10;
    uint256 public constant LIQUIDITY_SHARE_PERCENT = 40;

    // Events
    event PriceUpdated(uint256 indexed newPrice);
    event Withdrawn(address indexed to, uint256 amount);
    event MinimumEthForRewardsUpdated(uint256 newMinimum);
    
    // State Variables
    uint256 public minimumEthForRewards;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the contract with the owner and initial supply
    /// @param initialOwner The address of the owner
    /// @param initialMinimumEth Minimum Ether required for rewards
    function initialize(address initialOwner, uint256 initialMinimumEth) 
        initializer 
        external 
    {
        require(initialOwner != address(0), "Invalid owner address");

        __ERC20_init("KharYsma Coins", "KHAC");
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __Ownable_init();
        __ERC20Permit_init("KharYsma Coins");
        __ReentrancyGuard_init();

        _mint(initialOwner, TOTAL_SUPPLY_CAP);
        minimumEthForRewards = initialMinimumEth;
    }

    /// @notice Pause the contract (only owner)
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract (only owner)
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Mint new tokens (only owner, respects total supply cap)
    /// @param to Address to mint tokens to
    /// @param amount Amount of tokens to mint
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= TOTAL_SUPPLY_CAP, "Exceeds total supply cap");
        _mint(to, amount);
    }

    /// @notice Burn tokens from the caller's account
    /// @param amount Amount of tokens to burn
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /// @notice Withdraw Ether from the contract (only owner)
    /// @param to Address to send Ether to
    /// @param amount Amount of Ether to withdraw
    function withdraw(address payable to, uint256 amount) 
        external 
        onlyOwner 
        nonReentrant 
    {
        require(to != address(0), "Invalid address");
        require(amount <= address(this).balance, "Insufficient balance");

        to.transfer(amount);

        emit Withdrawn(to, amount);
    }

    /// @notice Update the price of the token and ensure it does not drop below the floor
    function updatePrice() external {
        uint256 currentPrice = address(this).balance / totalSupply();
        require(currentPrice >= PRICE_FLOOR, "Price below floor");
        emit PriceUpdated(currentPrice);
    }

    /// @notice Set the minimum Ether required for rewards
    /// @param newMinimum The new minimum value
    function setMinimumEthForRewards(uint256 newMinimum) external onlyOwner {
        minimumEthForRewards = newMinimum;
        emit MinimumEthForRewardsUpdated(newMinimum);
    }

    /// @dev Fallback function to receive Ether
    receive() external payable {}

    /// @dev Prevent misuse of block.timestamp
    /// @param lockTime The time to lock funds
    function lockFunds(uint256 lockTime) external onlyOwner {
        require(block.timestamp + lockTime > block.timestamp, "Invalid lock time");
    }
}

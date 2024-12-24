// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/// @title KharYsma Coins (KHAC)
/// @notice ERC20 token with automated fee management, price visibility, and market making.
/// @custom:security-contact contact@startarcoins.com
contract KharYsmaCoins is 
    ERC20Upgradeable, 
    ERC20BurnableUpgradeable, 
    ERC20PausableUpgradeable, 
    ERC20PermitUpgradeable, 
    OwnableUpgradeable, 
    ReentrancyGuardUpgradeable 
{
    using AddressUpgradeable for address payable;

    // Constants
    uint256 public constant PRICE_FLOOR = 550 * 10 ** 18;
    uint256 public constant TOTAL_SUPPLY_CAP = 10_000_000 * 10 ** 18;
    uint256 public constant OWNER_SHARE_PERCENT = 10; // 10%
    uint256 public constant LIQUIDITY_SHARE_PERCENT = 40; // 40%

    // State variables
    uint256 public minimumLiquidityForMarketMaking;
    address public liquidityPool;

    // Events
    event PriceUpdated(uint256 indexed newPrice);
    event Withdrawn(address indexed to, uint256 amount);
    event LiquidityAdded(address indexed pool, uint256 amount);
    event MinimumLiquidityForMarketMakingUpdated(uint256 newMinimum);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initialize the contract with the owner and initial supply
    /// @param initialOwner The address of the owner
    /// @param _liquidityPool The address of the liquidity pool
    function initialize(address initialOwner, address _liquidityPool) 
        external 
        initializer 
    {
        require(initialOwner != address(0), "Invalid owner address");
        require(_liquidityPool != address(0), "Invalid liquidity pool address");

        __ERC20_init("KharYsma Coins", "KHAC");
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __Ownable_init();
        __ERC20Permit_init("KharYsma Coins");
        __ReentrancyGuard_init();

        liquidityPool = _liquidityPool;
        _mint(initialOwner, TOTAL_SUPPLY_CAP);
        emit PriceUpdated(PRICE_FLOOR);
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

    /// @notice Withdraw ETH from the contract (only owner)
    /// @param to Address to withdraw to
    /// @param amount Amount of ETH to withdraw
    function withdraw(address payable to, uint256 amount) 
        external 
        onlyOwner 
        nonReentrant 
    {
        require(to != address(0), "Invalid address");
        require(amount <= address(this).balance, "Insufficient balance");

        to.sendValue(amount);

        emit Withdrawn(to, amount);
    }

    /// @notice Update the price of the token and ensure it does not drop below the floor
    function updatePrice() external {
        uint256 currentPrice = address(this).balance / totalSupply();
        require(currentPrice >= PRICE_FLOOR, "Price below floor");
        emit PriceUpdated(currentPrice);
    }

    /// @notice Set the minimum liquidity required for market making
    /// @param newMinimum The new minimum liquidity value
    function setMinimumLiquidityForMarketMaking(uint256 newMinimum) external onlyOwner {
        minimumLiquidityForMarketMaking = newMinimum;
        emit MinimumLiquidityForMarketMakingUpdated(newMinimum);
    }

    /// @notice Add liquidity to the pool automatically
    /// @param amount Amount of tokens to add to the liquidity pool
    function addLiquidity(uint256 amount) external onlyOwner nonReentrant {
        require(balanceOf(address(this)) >= amount, "Insufficient contract balance");
        _transfer(address(this), liquidityPool, amount);
        emit LiquidityAdded(liquidityPool, amount);
    }

    /// @dev Internal function for fee management
    /// @param from Address transferring tokens
    /// @param to Address receiving tokens
    /// @param amount Amount of tokens transferred
    function _transfer(address from, address to, uint256 amount) 
        internal 
        override 
    {
        uint256 fee = (amount * OWNER_SHARE_PERCENT) / 100;
        uint256 liquidityShare = (fee * LIQUIDITY_SHARE_PERCENT) / 100;
        uint256 amountAfterFee = amount - fee;

        super._transfer(from, to, amountAfterFee);
        super._transfer(from, owner(), fee - liquidityShare);
        super._transfer(from, address(this), liquidityShare);
    }

    /// @dev Override the internal token transfer to enforce paused state
    function _beforeTokenTransfer(address from, address to, uint256 amount) 
        internal 
        override(ERC20Upgradeable, ERC20PausableUpgradeable) 
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    /// @dev Fallback function to receive Ether
    receive() external payable {}
}

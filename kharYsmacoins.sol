// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC20PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @custom:security-contact notairebtc@yahoo.fr
contract KharYsmaCoins is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable, OwnableUpgradeable, ERC20PermitUpgradeable {
    uint256 public constant PRICE_FLOOR = 550 * 10**18; // Price floor in USD
    uint256 public constant TOTAL_SUPPLY = 10000000 * 10 ** 18; // Total supply
    uint256 public constant OWNER_SHARE_PERCENT = 10;
    uint256 public constant LIQUIDITY_SHARE_PERCENT = 40;

    event PriceUpdated(uint256 currentPrice);
    event Withdrawn(address indexed to, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with initial owner and mints the total supply.
    /// @param initialOwner The address of the initial owner.
    function initialize(address initialOwner) initializer public {
        __ERC20_init("kharYsma Coins", "KHAC");
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __Ownable_init();
        __ERC20Permit_init("kharYsma Coins");

        require(initialOwner != address(0), "Invalid owner address");
        _transferOwnership(initialOwner);
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    /// @notice Pauses all token transfers.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses all token transfers.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Mints new tokens.
    /// @param to The address to receive the minted tokens.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /// @notice Withdraws ETH from the contract.
    /// @param to The address to send the withdrawn ETH.
    /// @param amount The amount of ETH to withdraw.
    function withdraw(address payable to, uint256 amount) public onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount <= address(this).balance, "Insufficient balance");
        to.transfer(amount);
        emit Withdrawn(to, amount);
    }

    /// @notice Updates the token price and ensures it stays above the price floor.
    function updatePrice() public {
        uint256 currentPrice = address(this).balance / TOTAL_SUPPLY;
        if (currentPrice < PRICE_FLOOR) {
            currentPrice = PRICE_FLOOR;
        }
        emit PriceUpdated(currentPrice);
    }

    /// @notice Overrides the hook to include pausable functionality.
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20PausableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    /// @notice Ensures the total supply remains constant by minting tokens equal to the amount burned.
    function burn(uint256 amount) public override {
        super.burn(amount);
        _mint(owner(), amount);
    }

    /// @notice Receives Ether.
    receive() external payable {}
}

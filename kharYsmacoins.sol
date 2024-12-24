// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC20PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/// @title KharYsmaCoins
/// @custom:security-contact notairebtc@yahoo.fr
contract KharYsmaCoins is
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20PausableUpgradeable,
    OwnableUpgradeable,
    ERC20PermitUpgradeable,
    ReentrancyGuard
{
    using Address for address payable;

    uint256 public constant PRICE_FLOOR = 550 ether; // Floor price in USD
    uint256 public totalSupplyCap;
    uint256 public ownerSharePercent;
    uint256 public liquiditySharePercent;

    event PriceUpdated(uint256 newPrice);
    event Withdrawn(address indexed recipient, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) external initializer {
        __ERC20_init("KharYsma Coins", "KHAC");
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __Ownable_init();
        __ERC20Permit_init("KharYsma Coins");

        require(initialOwner != address(0), "Invalid owner address");
        transferOwnership(initialOwner);

        totalSupplyCap = 10000000 * 10 ** decimals();
        ownerSharePercent = 10;
        liquiditySharePercent = 40;

        _mint(msg.sender, totalSupplyCap);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= totalSupplyCap, "Exceeds total supply cap");
        _mint(to, amount);
    }

    function withdraw(address payable recipient, uint256 amount) 
        external 
        onlyOwner 
        nonReentrant
    {
        require(recipient != address(0), "Invalid address");
        require(amount <= address(this).balance, "Insufficient balance");
        recipient.sendValue(amount);
        emit Withdrawn(recipient, amount);
    }

    function updatePrice(uint256 newPrice) external onlyOwner {
        require(newPrice >= PRICE_FLOOR, "Price below floor");
        emit PriceUpdated(newPrice);
    }

    /// @notice Override _beforeTokenTransfer for pausable functionality
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /// @notice Implement market making logic
    function automaticMarketMaking(address to, uint256 amount) internal {
        uint256 ownerShare = (amount * ownerSharePercent) / 100;
        uint256 liquidityShare = (amount * liquiditySharePercent) / 100;

        _transfer(msg.sender, owner(), ownerShare);
        _transfer(msg.sender, address(this), liquidityShare);
    }

    /// @notice Override transfer to include market making
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        super._transfer(sender, recipient, amount);
        automaticMarketMaking(recipient, amount);
    }
}

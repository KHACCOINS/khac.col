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
    uint256 public constant PRICE_FLOOR = 165100000000000000; // 0.1651 ETH in WEI
    uint256 public constant TOTAL_SUPPLY = 10_000_000 * 10 ** 18; // 10 million tokens
    uint256 public constant TRANSACTION_FEE_PERCENT = 10; // 10% transaction fee
    uint256 public constant OWNER_SHARE_PERCENT = 60; // 60% of the fee to owner
    uint256 public constant LIQUIDITY_SHARE_PERCENT = 40; // 40% of the fee to liquidity pool

    uint256 public priceFloorBalance;

    event PriceUpdated(uint256 newPrice);
    event FeeDistributed(uint256 ownerShare, uint256 liquidityShare);

    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) initializer public {
        __ERC20_init("KharYsma Coins", "KHAC");
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __Ownable_init();
        __ERC20Permit_init("KharYsma Coins");

        _mint(initialOwner, TOTAL_SUPPLY);
        priceFloorBalance = PRICE_FLOOR;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) public override {
        super.burn(amount);
        _mint(owner(), amount); // Maintain total supply by minting equivalent amount to owner
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(balanceOf(from) >= amount, "Insufficient balance");

        uint256 fee = (amount * TRANSACTION_FEE_PERCENT) / 100;
        uint256 ownerShare = (fee * OWNER_SHARE_PERCENT) / 100;
        uint256 liquidityShare = fee - ownerShare;
        uint256 amountAfterFee = amount - fee;

        super._transfer(from, to, amountAfterFee);
        super._transfer(from, owner(), ownerShare);
        priceFloorBalance += liquidityShare;

        emit FeeDistributed(ownerShare, liquidityShare);
        emit PriceUpdated(getTokenPrice());
    }

    function getTokenPrice() public view returns (uint256) {
        uint256 currentPrice = address(this).balance / TOTAL_SUPPLY;
        return currentPrice >= PRICE_FLOOR ? currentPrice : PRICE_FLOOR;
    }

    receive() external payable {}
}

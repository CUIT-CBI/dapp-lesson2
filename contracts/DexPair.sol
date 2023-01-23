// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./DexERC20.sol";


contract DexPair is DexERC20 {
    IERC20 tokenA;
    IERC20 tokenB;

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    uint reserveA;
    uint reserveB;

    function addLiquidity(uint amountA, uint amountB) external returns (uint liquidity) {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        uint _totalSupply = totalSupply();
        liquidity = Math.min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
        require(liquidity > 0, "liquidity less than zero");
        _mint(msg.sender, liquidity);

        reserveA += amountA;
        reserveB += amountB;
    }

    function removeLiquidity(uint liquidity) external {
        uint _totalSupply = totalSupply();
        uint balanceA = tokenA.balanceOf(address(this));
        uint balanceB = tokenB.balanceOf(address(this));

        uint amountA = liquidity * _totalSupply / balanceA;
        uint amountB = liquidity * _totalSupply / balanceB;
        _burn(msg.sender, liquidity);

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        reserveA = tokenA.balanceOf(address(this));
        reserveB = tokenB.balanceOf(address(this));
    }

    function SwapAtoB(uint amountA) external returns (uint slippage) {
        uint amountB = (reserveB - reserveA * reserveB / (reserveA + amountA)) * 997 / 1000;
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transfer(msg.sender, amountB);

        uint targetAmountB = reserveB * amountA / reserveA;
        slippage = (targetAmountB - amountB) * 100 / targetAmountB;

        reserveA = tokenA.balanceOf(address(this));
        reserveB = tokenB.balanceOf(address(this));
    }

    function SwapBtoA(uint amountB) external returns (uint slippage) {
        uint amountA = (reserveA - reserveA * reserveB / (reserveB + amountB)) * 997 / 1000;
        tokenB.transferFrom(msg.sender, address(this), amountB);
        tokenA.transfer(msg.sender, amountA);

        uint targetAmountA = reserveA * amountB / reserveB;
        slippage = (targetAmountA - amountA) * 100 / targetAmountA;

        reserveA = tokenA.balanceOf(address(this));
        reserveB = tokenB.balanceOf(address(this));
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./LPToken.sol";

contract TokenSwap is LPToken {
    address public immutable tokenA;
    address public immutable tokenB;

    uint private reserveA;
    uint private reserveB;

    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function _getReserve() view internal returns (uint _reserveA, uint _reserveB) {
        _reserveA = reserveA;
        _reserveB = reserveB;
    }

    function initPool(uint amountA, uint amountB) external {
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);
        _update();
        uint initLiquidity = Math.sqrt(amountA * amountB);
        _mint(msg.sender, initLiquidity);
    }


    function AddLiquidity(address token, uint amount) external returns (uint liquidity) {
        require(token == tokenA || token == tokenB, "Invalid token address");
        (uint _reserveA, uint _reserveB) = _getReserve();   
        uint amountA;
        uint amountB;
        if(token == tokenA) {
            amountA = amount;
            amountB = amountA * _reserveB / _reserveA;     
        } else {
            amountB = amount;
            amountA = amountB * _reserveA / _reserveB;     
        }
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        uint _totalSupply = totalSupply();
        liquidity = Math.min(amountA * _totalSupply / _reserveA, amountB * _totalSupply / _reserveB);
        require(liquidity > 0, 'Insufficient Liquidity Minted');

        _mint(msg.sender, liquidity);
        _update();
    }


    function RemoveLiquidity(uint liquidityAmount) external returns (uint amountA, uint amountB) {
        uint balanceA = IERC20(tokenA).balanceOf(address(this));
        uint balanceB = IERC20(tokenB).balanceOf(address(this));
        uint _totalSupply = totalSupply();

        amountA = liquidityAmount * balanceA / _totalSupply;
        amountB = liquidityAmount * balanceB / _totalSupply;
        _burn(msg.sender, liquidityAmount);

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        _update();
    }


    function _SwapByTokenA(uint amountAin) internal returns (uint amountBout) {
        (uint _reserveA, uint _reserveB) = _getReserve();   
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountAin);
        amountBout = (_reserveB - (_reserveA * _reserveB) / (_reserveA + amountAin))  * 997 / 1000; 
        IERC20(tokenB).transfer(msg.sender, amountBout);
    }

    function _SwapByTokenB(uint amountBin) internal returns (uint amountAout) {
        (uint _reserveA, uint _reserveB) = _getReserve();   
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBin);
        amountAout = (_reserveA - (_reserveA * _reserveB) / (_reserveB + amountBin)) * 997 / 1000;  
        IERC20(tokenA).transfer(msg.sender, amountAout);
    }

    function SwapSlippageLimit(address token, uint amountIn, uint8 slippageLimit) external returns (uint slippage) {
        require(token == tokenA || token == tokenB, "Invalid token address");
        (uint _reserveA, uint _reserveB) = _getReserve();   
        uint actualAmountOut;
        uint expectAmountOut;

        if(token == tokenA) {
            actualAmountOut = _SwapByTokenA(amountIn);
            expectAmountOut = _reserveB * amountIn / _reserveA;
        } else {
            actualAmountOut = _SwapByTokenB(amountIn);
            expectAmountOut = _reserveA * amountIn / _reserveB;
        }
        slippage = (expectAmountOut - actualAmountOut) * 1000 / expectAmountOut;    
        require(slippage <= slippageLimit, "Slippage limit not met");

        _update();        
    }

    function _update() internal {
        reserveA = IERC20(tokenA).balanceOf(address(this));
        reserveB = IERC20(tokenB).balanceOf(address(this));
    }
}
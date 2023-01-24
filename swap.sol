// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./FT.sol";

contract myFT is FT {
    address public tokenA;
    address public tokenB;
  uint public reserveA;
  uint public reserveB;
  uint public constant INITIAL_SUPPLY = 10**5;
  constructor(address _token0, address _token1) FT("MYFT", "FT") {
    tokenA = _token0;
    tokenB = _token1;
  }
    function updateReserve() private {
        reserveA = IERC20(tokenA).balanceOf(address(this));
        reserveB = IERC20(tokenB).balanceOf(address(this));
    }

    function addLiquidityTokenA(uint amountAIn) external {
        uint amountBIn = amountAIn * reserveB / reserveA;
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountAIn);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBIn);
        uint _totalSupply = totalSupply();
        uint liquidity = Math.min(amountAIn * _totalSupply / reserveA, amountBIn * _totalSupply / reserveB);
        _mint(msg.sender, liquidity);
        updateReserve();
    }

    function addLiquidityTokenB(uint amountBIn) external {
        uint amountAIn = amountBIn * reserveB / reserveA;
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountAIn);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBIn);
        uint _totalSupply = totalSupply();
        uint liquidity = Math.min(amountAIn * _totalSupply / reserveA, amountBIn * _totalSupply / reserveB);

        _mint(msg.sender, liquidity);
        updateReserve();
    }

    function RemoveLiquidity(uint _amount) external {
        uint balanceA = IERC20(tokenA).balanceOf(address(this));
        uint balanceB = IERC20(tokenB).balanceOf(address(this));
        uint _totalSupply = totalSupply();

        uint amountA = _amount * balanceA / _totalSupply;
        uint amountB = _amount * balanceB / _totalSupply;
        _burn(msg.sender, _amount);

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        updateReserve();
    }

    function SwapTokenA(uint amountAIn, uint slippage) external {
        uint amountBOut = (reserveB - (reserveA * reserveB) / (reserveA + amountAIn) * 997 / 1000);
        uint expectAmountBOut = reserveB * amountAIn / reserveA;
        uint slip = (expectAmountBOut - amountBOut) * 1000 / expectAmountBOut;
        require(slip < slippage, "error");
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountAIn);
        IERC20(tokenB).transfer(msg.sender, amountBOut);
        updateReserve();
    }

    function SwapTokenB(uint amountBIn, uint slippage) external {
        uint amountAOut = (reserveA - (reserveA * reserveB) / (reserveB + amountBIn) * 997 / 1000);
        uint expectAmountAOut = reserveA * amountBIn / reserveB;
        uint slip = (expectAmountAOut - amountAOut) * 1000 / expectAmountAOut;
        require(slip < slippage, "error");
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBIn);
        IERC20(tokenA).transfer(msg.sender, amountAOut);
        updateReserve();
    }
}

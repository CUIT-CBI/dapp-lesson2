// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./LP.sol";

contract Dex is LP {
    // 替换为 tokenA 的地址
    address constant tokenA = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    // 替换为 tokenB 的地址
    address constant tokenB = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

    uint reserveA;
    uint reserveB;

    function updateReserve() private {
        reserveA = IERC20(tokenA).balanceOf(address(this));
        reserveB = IERC20(tokenB).balanceOf(address(this));
    }

    function addLiquidityTokenA(uint amountAIn) external {
        uint amountBIn = amountAIn * reserveB / reserveA;
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountAIn);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBIn);

        uint LP_totalSupply = totalSupply();
        uint liquidity = Math.min(amountAIn * LP_totalSupply / reserveA, amountBIn * LP_totalSupply / reserveB);
        
        _mint(msg.sender, liquidity);
        updateReserve();
    }

    function addLiquidityTokenB(uint amountBIn) external {
        uint amountAIn = amountBIn * reserveB / reserveA;
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountAIn);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBIn);

        uint LP_totalSupply = totalSupply();
        uint liquidity = Math.min(amountAIn * LP_totalSupply / reserveA, amountBIn * LP_totalSupply / reserveB);
        
        _mint(msg.sender, liquidity);
        updateReserve();
    }

    function RemoveLiquidity(uint LP_amount) external {
        uint balanceA = IERC20(tokenA).balanceOf(address(this));
        uint balanceB = IERC20(tokenB).balanceOf(address(this));
        uint _totalSupply = totalSupply();

        uint amountA = LP_amount * balanceA / _totalSupply;
        uint amountB = LP_amount * balanceB / _totalSupply;
        _burn(msg.sender, LP_amount);

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        updateReserve();
    }

    function SwapTokenA(uint amountAIn, uint slippage) external {
        uint amountBOut = (reserveB - reserveA * reserveB / (reserveA + amountAIn)) * 997 / 1000;
        uint expectAmountBOut = reserveB * amountAIn / reserveA;
        uint slip = (expectAmountBOut - amountBOut) * 1000 / expectAmountBOut;
        require(slip < slippage, "slippage error");
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountAIn);
        IERC20(tokenB).transfer(msg.sender, amountBOut);
        updateReserve();
    }

    function SwapTokenB(uint amountBIn, uint slippage) external {
        uint amountAOut = (reserveA - reserveA * reserveB / (reserveB + amountBIn)) * 997 / 1000;
        uint expectAmountAOut = reserveA * amountBIn / reserveB;
        uint slip = (expectAmountAOut - amountAOut) * 1000 / expectAmountAOut;
        require(slip < slippage, "slippage error");
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBIn);
        IERC20(tokenA).transfer(msg.sender, amountAOut);
        updateReserve();
    }
}
